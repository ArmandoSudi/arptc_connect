import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';
import 'package:arptc_connect/modules/task/domain/task_attachment_upload.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' hide Task;
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchTasks(TaskPrincipal principal);

  Stream<Task?> watchTask(String taskId);

  Future<Task?> getTask(String taskId);

  Future<String> createTask(
    Task task, {
    required String actingUserId,
    TaskAttachmentUpload? mailScan,
    TaskAttachmentUpload? reportFile,
  });

  Future<void> updateTask(
    Task task, {
    required String actingUserId,
    TaskAttachmentUpload? mailScan,
    bool removeMailScan,
    TaskAttachmentUpload? reportFile,
    bool removeReportFile,
  });

  Future<void> deleteTask(Task task);
}

class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  static const collectionPath = 'tasks';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection(collectionPath);

  @override
  Stream<List<Task>> watchTasks(TaskPrincipal principal) {
    Query<Map<String, dynamic>> query = _tasks;
    if (!principal.role.canViewAllDepartments) {
      query = query.where('department', isEqualTo: principal.departmentId);
    }

    return query.snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map((document) => Task.fromMap(document.data(), id: document.id))
          .toList();
      tasks.sort((left, right) {
        return right.creationDate.compareTo(left.creationDate);
      });
      return tasks;
    });
  }

  @override
  Stream<Task?> watchTask(String taskId) {
    return _tasks.doc(taskId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return Task.fromMap(data, id: snapshot.id);
    });
  }

  @override
  Future<Task?> getTask(String taskId) async {
    final snapshot = await _tasks.doc(taskId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return Task.fromMap(data, id: snapshot.id);
  }

  @override
  Future<String> createTask(
    Task task, {
    required String actingUserId,
    TaskAttachmentUpload? mailScan,
    TaskAttachmentUpload? reportFile,
  }) async {
    final document = _tasks.doc();
    TaskAttachment? uploadedMailScan;
    TaskAttachment? uploadedReport;

    try {
      if (task.type == TaskType.mail && mailScan != null) {
        uploadedMailScan = await _uploadAttachment(
          taskId: document.id,
          category: 'mail-scans',
          upload: mailScan,
          departmentId: task.departmentId,
          uploadedByUserId: actingUserId,
        );
      }
      if (reportFile != null) {
        uploadedReport = await _uploadAttachment(
          taskId: document.id,
          category: 'reports',
          upload: reportFile,
          departmentId: task.departmentId,
          uploadedByUserId: actingUserId,
        );
      }

      final storedTask = task.copyWith(
        id: document.id,
        mailScan: uploadedMailScan,
        reportFile: uploadedReport,
      );
      await document.set(storedTask.toFirestore(
        creationDateValue: FieldValue.serverTimestamp(),
        updatedAtValue: FieldValue.serverTimestamp(),
      ));
      return document.id;
    } catch (_) {
      await _rollbackUploads([
        uploadedMailScan,
        uploadedReport,
      ]);
      rethrow;
    }
  }

  @override
  Future<void> updateTask(
    Task task, {
    required String actingUserId,
    TaskAttachmentUpload? mailScan,
    bool removeMailScan = false,
    TaskAttachmentUpload? reportFile,
    bool removeReportFile = false,
  }) async {
    TaskAttachment? nextMailScan = task.mailScan;
    TaskAttachment? nextReport = task.reportFile;
    TaskAttachment? uploadedMailScan;
    TaskAttachment? uploadedReport;

    final shouldRemoveMail = removeMailScan || task.type != TaskType.mail;

    try {
      if (task.type == TaskType.mail && mailScan != null) {
        uploadedMailScan = await _uploadAttachment(
          taskId: task.id,
          category: 'mail-scans',
          upload: mailScan,
          departmentId: task.departmentId,
          uploadedByUserId: actingUserId,
        );
        nextMailScan = uploadedMailScan;
      } else if (shouldRemoveMail) {
        nextMailScan = null;
      }

      if (reportFile != null) {
        uploadedReport = await _uploadAttachment(
          taskId: task.id,
          category: 'reports',
          upload: reportFile,
          departmentId: task.departmentId,
          uploadedByUserId: actingUserId,
        );
        nextReport = uploadedReport;
      } else if (removeReportFile) {
        nextReport = null;
      }

      final updatedTask = task.copyWith(
        mailScan: nextMailScan,
        clearMailScan: nextMailScan == null,
        reportFile: nextReport,
        clearReportFile: nextReport == null,
        updatedAt: DateTime.now(),
      );
      await _tasks.doc(task.id).update(updatedTask.toFirestore(
            creationDateValue: Timestamp.fromDate(task.creationDate),
            updatedAtValue: FieldValue.serverTimestamp(),
          ));

      await _deleteReplacedAttachment(
        previous: task.mailScan,
        current: nextMailScan,
      );
      await _deleteReplacedAttachment(
        previous: task.reportFile,
        current: nextReport,
      );
    } catch (_) {
      await _rollbackUploads([
        uploadedMailScan,
        uploadedReport,
      ]);
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(Task task) async {
    await _deleteAttachments([
      task.mailScan,
      task.reportFile,
    ]);
    await _tasks.doc(task.id).delete();
  }

  Future<TaskAttachment> _uploadAttachment({
    required String taskId,
    required String category,
    required TaskAttachmentUpload upload,
    required String departmentId,
    required String uploadedByUserId,
  }) async {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final safeName = _safeFileName(upload.fileName);
    final storagePath = 'tasks/$taskId/$category/${timestamp}_$safeName';
    final reference = _storage.ref(storagePath);
    final snapshot = await reference.putData(
      upload.bytes,
      SettableMetadata(
        contentType: upload.contentType,
        customMetadata: <String, String>{
          'taskId': taskId,
          'departmentId': departmentId,
          'uploadedByUserId': uploadedByUserId,
          'originalFileName': upload.fileName,
        },
      ),
    );

    return TaskAttachment(
      url: await snapshot.ref.getDownloadURL(),
      storagePath: storagePath,
      fileName: upload.fileName,
      contentType: upload.contentType,
    );
  }

  Future<void> _deleteReplacedAttachment({
    required TaskAttachment? previous,
    required TaskAttachment? current,
  }) async {
    if (previous == null || !previous.isAvailable) return;
    if (previous.storagePath == current?.storagePath &&
        previous.url == current?.url) {
      return;
    }
    try {
      await _deleteAttachment(previous);
    } catch (_) {
      // The task already references the replacement. Do not roll it back
      // because cleanup of the superseded object failed.
    }
  }

  Future<void> _rollbackUploads(
    Iterable<TaskAttachment?> attachments,
  ) async {
    for (final attachment in attachments) {
      if (attachment == null || !attachment.isAvailable) continue;
      try {
        await _deleteAttachment(attachment);
      } catch (_) {}
    }
  }

  Future<void> _deleteAttachments(
    Iterable<TaskAttachment?> attachments,
  ) async {
    Object? firstError;
    StackTrace? firstStackTrace;
    for (final attachment in attachments) {
      if (attachment == null || !attachment.isAvailable) continue;
      try {
        await _deleteAttachment(attachment);
      } on FirebaseException catch (error, stackTrace) {
        if (error.code == 'object-not-found') continue;
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }
    if (firstError != null && firstStackTrace != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace);
    }
  }

  Future<void> _deleteAttachment(TaskAttachment attachment) async {
    if (attachment.storagePath.trim().isNotEmpty) {
      await _storage.ref(attachment.storagePath).delete();
      return;
    }
    if (attachment.url.trim().isNotEmpty) {
      await _storage.refFromURL(attachment.url).delete();
    }
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return FirestoreTaskRepository(
    firestore: ref.read(fireStoreProvider),
    storage: ref.read(firebaseStorageProvider),
  );
});

String _safeFileName(String fileName) {
  final sanitized = fileName
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return sanitized.isEmpty ? 'document' : sanitized;
}
