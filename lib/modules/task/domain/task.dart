import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  newTask('new'),
  doing('doing'),
  done('done'),
  archived('archived');

  const TaskStatus(this.value);

  final String value;

  static TaskStatus fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return TaskStatus.values.firstWhere(
      (status) => status.value == normalized,
      orElse: () => TaskStatus.newTask,
    );
  }
}

enum TaskType {
  task('task'),
  mail('mail');

  const TaskType(this.value);

  final String value;

  static TaskType fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return TaskType.values.firstWhere(
      (type) => type.value == normalized,
      orElse: () => TaskType.task,
    );
  }
}

class TaskAttachment {
  const TaskAttachment({
    required this.url,
    this.storagePath = '',
    this.fileName = '',
    this.contentType = '',
  });

  final String url;
  final String storagePath;
  final String fileName;
  final String contentType;

  bool get isAvailable => url.trim().isNotEmpty;

  TaskAttachment copyWith({
    String? url,
    String? storagePath,
    String? fileName,
    String? contentType,
  }) {
    return TaskAttachment(
      url: url ?? this.url,
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
    );
  }
}

class Task {
  const Task({
    required this.id,
    required this.label,
    required this.observation,
    required this.creationDate,
    required this.status,
    required this.type,
    required this.departmentId,
    this.departmentName = '',
    this.sender = '',
    this.receiver = '',
    this.mailScan,
    this.reportFile,
    this.createdByUserId = '',
    this.createdByName = '',
    this.createdByEmail = '',
    this.updatedAt,
    this.emissionDate,
    this.receptionDate,
    this.annotations,
  });

  final String id;
  final String label;
  final String observation;
  final DateTime creationDate;
  final DateTime? updatedAt;
  final TaskStatus status;
  final TaskType type;
  final String sender;
  final String receiver;
  final TaskAttachment? mailScan;
  final TaskAttachment? reportFile;
  final String departmentId;
  final String departmentName;
  final String createdByUserId;
  final String createdByName;
  final String createdByEmail;

  // Retained when reading legacy documents so existing reports keep working.
  final DateTime? emissionDate;
  final DateTime? receptionDate;
  final Map<String, String>? annotations;

  String? get mailScanUrl => mailScan?.url;
  String? get reportFileUrl => reportFile?.url;
  String get department => departmentId;
  DateTime get reportingDate => emissionDate ?? creationDate;

  factory Task.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    return Task.fromMap(snapshot.data() ?? const <String, dynamic>{},
        id: snapshot.id);
  }

  factory Task.fromMap(Map<String, dynamic> map, {required String id}) {
    final creationDate = _dateTime(map['creation_date']) ??
        _dateTime(map['createdAt']) ??
        DateTime.now();
    final mailScanUrl = _string(map['mail_scan_url']);
    final reportFileUrl = _string(map['report_file_url']);
    final departmentId = _firstString(
      map,
      const ['department', 'department_id', 'departmentId', 'direction'],
    );

    return Task(
      id: id,
      label: _string(map['label']),
      observation: _string(map['observation']),
      creationDate: creationDate,
      updatedAt: _dateTime(map['updated_at']) ?? _dateTime(map['updatedAt']),
      status: TaskStatus.fromValue(map['status']),
      type: TaskType.fromValue(map['type']),
      sender: _string(map['sender']),
      receiver: _string(map['receiver']),
      mailScan: mailScanUrl.isEmpty
          ? null
          : TaskAttachment(
              url: mailScanUrl,
              storagePath: _string(map['mail_scan_path']),
              fileName: _firstString(
                map,
                const ['mail_scan_name', 'mail_scan_file_name'],
              ),
              contentType: _string(map['mail_scan_content_type']),
            ),
      reportFile: reportFileUrl.isEmpty
          ? null
          : TaskAttachment(
              url: reportFileUrl,
              storagePath: _string(map['report_file_path']),
              fileName: _firstString(
                map,
                const ['report_file_name', 'report_name'],
              ),
              contentType: _string(map['report_file_content_type']),
            ),
      departmentId: departmentId,
      departmentName: _firstString(
        map,
        const ['department_name', 'departmentName'],
      ),
      createdByUserId: _firstString(
        map,
        const ['created_by_user_id', 'createdByUserId'],
      ),
      createdByName:
          _firstString(map, const ['created_by_name', 'createdByName']),
      createdByEmail:
          _firstString(map, const ['created_by_email', 'createdByEmail']),
      emissionDate: _dateTime(map['emission_date']),
      receptionDate: _dateTime(map['reception_date']),
      annotations: _stringMap(map['annotations']),
    );
  }

  Map<String, dynamic> toFirestore({
    Object? creationDateValue,
    Object? updatedAtValue,
  }) {
    final effectiveCreationDate =
        creationDateValue ?? Timestamp.fromDate(creationDate);
    final effectiveUpdatedAt =
        updatedAtValue ?? Timestamp.fromDate(updatedAt ?? creationDate);

    return <String, dynamic>{
      'label': label.trim(),
      'observation': observation.trim(),
      'creation_date': effectiveCreationDate,
      'updated_at': effectiveUpdatedAt,
      'status': status.value,
      'type': type.value,
      'sender': type == TaskType.mail ? sender.trim() : '',
      'receiver': type == TaskType.mail ? receiver.trim() : '',
      'mail_scan_url': type == TaskType.mail ? mailScan?.url ?? '' : '',
      'mail_scan_path':
          type == TaskType.mail ? mailScan?.storagePath ?? '' : '',
      'mail_scan_name': type == TaskType.mail ? mailScan?.fileName ?? '' : '',
      'mail_scan_content_type':
          type == TaskType.mail ? mailScan?.contentType ?? '' : '',
      'report_file_url': reportFile?.url ?? '',
      'report_file_path': reportFile?.storagePath ?? '',
      'report_file_name': reportFile?.fileName ?? '',
      'report_file_content_type': reportFile?.contentType ?? '',
      'department': departmentId.trim(),
      'department_name': departmentName.trim(),
      'created_by_user_id': createdByUserId.trim(),
      'created_by_name': createdByName.trim(),
      'created_by_email': createdByEmail.trim().toLowerCase(),
      if (emissionDate != null)
        'emission_date': Timestamp.fromDate(emissionDate!),
      if (receptionDate != null)
        'reception_date': Timestamp.fromDate(receptionDate!),
      if (annotations != null) 'annotations': annotations,
    };
  }

  Task copyWith({
    String? id,
    String? label,
    String? observation,
    DateTime? creationDate,
    DateTime? updatedAt,
    TaskStatus? status,
    TaskType? type,
    String? sender,
    String? receiver,
    TaskAttachment? mailScan,
    bool clearMailScan = false,
    TaskAttachment? reportFile,
    bool clearReportFile = false,
    String? departmentId,
    String? departmentName,
    String? createdByUserId,
    String? createdByName,
    String? createdByEmail,
    DateTime? emissionDate,
    DateTime? receptionDate,
    Map<String, String>? annotations,
  }) {
    return Task(
      id: id ?? this.id,
      label: label ?? this.label,
      observation: observation ?? this.observation,
      creationDate: creationDate ?? this.creationDate,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      mailScan: clearMailScan ? null : mailScan ?? this.mailScan,
      reportFile: clearReportFile ? null : reportFile ?? this.reportFile,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      emissionDate: emissionDate ?? this.emissionDate,
      receptionDate: receptionDate ?? this.receptionDate,
      annotations: annotations ?? this.annotations,
    );
  }
}

DateTime? _dateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _string(Object? value) => value?.toString().trim() ?? '';

String _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = _string(map[key]);
    if (value.isNotEmpty) return value;
  }
  return '';
}

Map<String, String>? _stringMap(Object? value) {
  if (value is! Map) return null;
  final result = <String, String>{};
  value.forEach((key, item) {
    result[key.toString()] = item?.toString() ?? '';
  });
  return result.isEmpty ? null : result;
}
