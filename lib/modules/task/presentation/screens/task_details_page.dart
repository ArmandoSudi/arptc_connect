import 'dart:async';
import 'dart:developer';

import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:arptc_connect/modules/task/data/task_repository.dart';
import 'package:arptc_connect/utils/download_helper.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:arptc_connect/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';

enum UploadFileType { mail, report }

class TaskDetailsPage extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailsPage(this.taskId, {super.key});

  @override
  ConsumerState<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends ConsumerState<TaskDetailsPage> {
  late Future<String> _imageUrlFuture;
  String? _mailScanName, _reportFileName;

  @override
  void initState() {
    super.initState();
    _imageUrlFuture = _getDownloadUrl(
        "gs://arptc-connect.firebasestorage.app/20131010_184913-MIX_Original.jpg");
  }

  // Function to get the download URL
  Future<String> _getDownloadUrl(String imagePath) async {
    try {
      final ref = FirebaseStorage.instanceFor(
              bucket: 'gs://arptc-connect.firebasestorage.app')
          .ref()
          .child(imagePath);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      log("Error getting download URL: $e");
      // Return a placeholder URL or rethrow the error depending on your logic
      // For simplicity, rethrowing here. Handle appropriately in your UI.
      rethrow;
    }
  }

  Future<void> deleteFile(String filePath, UploadFileType fileType) async {
    try {
      // Create a reference to the file
      final ref = FirebaseStorage.instanceFor(
              bucket: 'gs://arptc-connect.firebasestorage.app')
          .ref()
          .child(filePath);

      // Delete the file
      await ref.delete();

      deleteFileUrl(widget.taskId, fileType);

      log("File deleted successfully.");
    } catch (e, stck) {
      log("Error deleting file: $e");
      log("Error deleting file stackTrace: $stck");
    }
  }

  Future<void> deleteFileUrl(String taskId, UploadFileType fileType) async {
    try {
      final String fieldName =
          fileType == UploadFileType.mail ? "mail_scan_url" : "report_file_url";
      final taskRef =
          FirebaseFirestore.instance.collection("tasks").doc(taskId);
      await taskRef.update({fieldName: ""});
      ref.invalidate(taskProvider(widget.taskId));
      log("Task scan URL updated successfully.");
    } catch (e) {
      log("Failed to update task scan URL: $e");
    }
  }

  Future<void> deleteFileFromUrl(String fileUrl) async {
    try {
      // Extract the file path from the URL
      final uri = Uri.parse(fileUrl);
      final filePath = uri.pathSegments
          .skipWhile((segment) => segment != 'o')
          .skip(1)
          .join('/')
          .replaceAll('%2F', '/'); // Decode URL-encoded slashes

      log("File path: $filePath");

      // Create a reference to the file
      final ref = FirebaseStorage.instance.ref().child(filePath);

      // Delete the file
      await ref.delete();

      log("File deleted successfully: $filePath");
    } catch (e) {
      log("Error deleting file: $e");
    }
  }

  String _setTitle(String type) {
    return type == "mail" ? "Détails du courrier" : "Détails de la tâche";
  }

  @override
  Widget build(BuildContext context) {
    // final asyncTask = ref.watch(taskProvider(widget.taskId));

    final task = ref.watch(taskProvider(widget.taskId));

    final theme = Theme.of(context);

    return Scaffold(
      body: ContentView(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // TITLE
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      context.pop();
                    },
                  ),
                  const PageHeader(
                      title: "Détails de la tâche",
                      description: 'Gestion des tickets d\'intervention'),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Container(),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                    onPressed: () {
                      context.pushNamed("edit_task",
                          pathParameters: {"taskId": widget.taskId});
                    },
                  )
                ],
              ),
              const SizedBox(height: 20),

              task.when(
                data: (task) {
                  // Extract the file names from the URLs
                  if (task.mailScanUrl == null || task.mailScanUrl!.isEmpty) {
                    _mailScanName = "";
                  } else {
                    Uri uriMail = Uri.parse(task.mailScanUrl!);
                    _mailScanName =
                        Uri.decodeComponent(uriMail.pathSegments.last);
                  }

                  if (task.reportFileUrl == null ||
                      task.reportFileUrl!.isEmpty) {
                    _reportFileName = "";
                  } else {
                    Uri uriReport = Uri.parse(task.reportFileUrl!);
                    _reportFileName =
                        Uri.decodeComponent(uriReport.pathSegments.last);
                  }

                  return ResponsiveCenter(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // GENERAL INFORMATION
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.label,
                                    style: theme.textTheme.titleMedium!
                                        .copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 20),

                                // DATE LABEL
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Date d'émission",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "Date d'accusé réception",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      task.emissionDate.formatedDate,
                                      style: theme.textTheme.labelLarge,
                                    ),
                                    Text(
                                      task.receptionDate?.formatedDate ?? " - ",
                                      style: theme.textTheme.labelLarge,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                const Text(
                                  "Remarques",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  task.observation,
                                  style: theme.textTheme.bodyLarge,
                                ),

                                Text(task.status),
                                Text(task.type),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // SCANS / PROJECTS
                          Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.black)),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Pièces jointes",
                                        style: theme.textTheme.titleMedium!
                                            .copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: Colors.green[900]),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          // Black background
                                          foregroundColor: Colors.white,
                                          // White text
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                20), // Rounded corners
                                          ),
                                        ),
                                        onPressed: () async {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(20)),
                                            ),
                                            builder: (context) =>
                                                FilePickerBottomSheet(
                                                    widget.taskId,
                                                    UploadFileType.mail),
                                          );
                                        },
                                        child: const Text(
                                          "Ajouter",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (task.mailScanUrl != null &&
                                      task.mailScanUrl!.isNotEmpty)
                                    ListTile(
                                      leading: IconButton(
                                        icon: const Icon(Icons.download),
                                        onPressed: () async {
                                          // Download file from task.mailScanUrl
                                          try {
                                            await openUrlForDownload(
                                              url: task.mailScanUrl!,
                                              fileName: task.mailScanUrl!
                                                  .split('/')
                                                  .last,
                                            );
                                          } catch (e) {
                                            log("Error: $e");
                                          }
                                        },
                                      ),
                                      title: Text(_mailScanName!),
                                      subtitle: const Text("2.5 MB"),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_outlined,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () async {
                                          // Handle delete action
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text("Confirmation"),
                                              content: const Text(
                                                  "Êtes-vous sûr de vouloir supprimer ce fichier ?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text("Annuler"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    // Perform delete action
                                                    deleteFile(
                                                        task.mailScanUrl!,
                                                        UploadFileType.mail);
                                                    ref.invalidate(taskProvider(
                                                        widget.taskId));
                                                    Navigator.of(context).pop();
                                                  },
                                                  child:
                                                      const Text("Supprimer"),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  else
                                    const ListTile(
                                      title: Text("Aucun fichier joint"),
                                    ),
                                ],
                              )),
                          const SizedBox(height: 20),

                          // RESULTS / LIVRABLES
                          Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.black)),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Livrables",
                                        style: theme.textTheme.titleMedium!
                                            .copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: Colors.blue[900]),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          // Black background
                                          foregroundColor: Colors.white,
                                          // White text
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                20), // Rounded corners
                                          ),
                                        ),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(20)),
                                            ),
                                            builder: (context) =>
                                                FilePickerBottomSheet(
                                                    widget.taskId,
                                                    UploadFileType.report),
                                          );
                                        },
                                        child: const Text(
                                          "Ajouter",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (task.reportFileUrl != null &&
                                      task.reportFileUrl!.isNotEmpty)
                                    ListTile(
                                      leading: IconButton(
                                        icon: const Icon(Icons.download),
                                        onPressed: () async {
                                          // Download file from task.mailScanUrl
                                          try {
                                            await openUrlForDownload(
                                              url: task.reportFileUrl!,
                                              fileName: task.reportFileUrl!
                                                  .split('/')
                                                  .last,
                                            );
                                          } catch (e) {
                                            log("Error: $e");
                                          }
                                        },
                                      ),
                                      title: Text(_reportFileName!),
                                      subtitle: const Text("2.5 MB"),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_outlined,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () {
                                          // Handle delete action
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text("Confirmation"),
                                              content: const Text(
                                                  "Êtes-vous sûr de vouloir supprimer ce fichier ?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text("Annuler"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    // Perform delete action
                                                    deleteFile(
                                                        task.reportFileUrl!,
                                                        UploadFileType.report);
                                                    ref.invalidate(taskProvider(
                                                        widget.taskId));
                                                    Navigator.of(context).pop();
                                                  },
                                                  child:
                                                      const Text("Supprimer"),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  else
                                    const ListTile(
                                      title: Text(
                                          "Aucun rapport / livrable joint"),
                                    ),
                                ],
                              )),
                          const SizedBox(height: 20),

                          // ANNOTATIONS
                          if (task.type == 'mail') ...[
                            Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    color: Colors.yellow.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.black)),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Annotations",
                                          style: theme.textTheme.titleMedium!
                                              .copyWith(
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.yellow[900]),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            // Black background
                                            foregroundColor: Colors.white,
                                            // White text
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      20), // Rounded corners
                                            ),
                                          ),
                                          onPressed: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              shape:
                                                  const RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            20)),
                                              ),
                                              builder: (context) =>
                                                  AnnotationBottomSheet(
                                                      widget.taskId,
                                                      task.annotations),
                                            );
                                          },
                                          child: const Text(
                                            "Ajouter",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (task.annotations != null &&
                                        task.annotations!.isNotEmpty)
                                      ...task.annotations!.entries.map((entry) {
                                        return ListTile(
                                          title:
                                              Text(entry.key), // Annotation key
                                          subtitle: Text(
                                              entry.value), // Annotation value
                                        );
                                      }).toList()
                                    else
                                      const ListTile(
                                        title: Text(
                                            "Aucune annotation disponible"),
                                      ),
                                  ],
                                )),
                          ],
                          const SizedBox(height: 20),

                          // ACTIONS
                          FilledButton.icon(
                            icon: Icon(Icons.task_alt, color: Colors.white),
                            label: const Text("Marquer la tâche complète",
                                style: TextStyle(color: Colors.white)),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.black,
                              // Black background
                              foregroundColor: Colors.white,
                              // White text
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    20), // Rounded corners
                              ),
                            ),
                            onPressed: null,
                          )
                        ],
                      ),
                    ),
                  );
                },
                error: (error, stack) => const Center(child: Text("Error")),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilePickerBottomSheet extends ConsumerStatefulWidget {
  final String taskId;
  final UploadFileType fileType;

  const FilePickerBottomSheet(this.taskId, this.fileType, {super.key});

  @override
  ConsumerState<FilePickerBottomSheet> createState() =>
      _FilePickerBottomSheetState();
}

class _FilePickerBottomSheetState extends ConsumerState<FilePickerBottomSheet> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  String? _uploadUrl;
  double progress = 0.0;

  Future<void> _selectFile() async {
    // final result = await FilePicker.platform.pickFiles();
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = result.files.single);
    }
  }

  Future<void> _uploadFile(BuildContext context, UploadFileType type) async {
    String relativePath = type == UploadFileType.mail ? "scans" : "reports";

    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = "task/$relativePath/${timestamp}_${_selectedFile!.name}";
      final storage = FirebaseStorage.instanceFor(
          bucket: 'gs://arptc-connect.firebasestorage.app');
      final storageRef = storage.ref().child(path);

      UploadTask uploadTask = kIsWeb || _selectedFile!.bytes != null
          ? storageRef.putData(_selectedFile!.bytes!)
          : storageRef.putFile(io.File(_selectedFile!.path!));

      uploadTask.snapshotEvents.listen((snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        log("Upload is ${progress.toStringAsFixed(2)}% complete.");
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      log("Download URL: $downloadUrl");
      log("File Type: ${widget.fileType}");

      await updateTaskScanUrl(widget.taskId, widget.fileType, downloadUrl);

      setState(() {
        _uploadUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload successful!')),
      );

      context.pop();
    } catch (e, stck) {
      log("UPLAOD FAILED ERROR : $e");
      log("UPLAOD FAILED STACKTRACE : $stck");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
      context.pop();
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> updateTaskScanUrl(
      String taskId, UploadFileType fileType, String downloadUrl) async {
    try {
      final String fieldName =
          fileType == UploadFileType.mail ? "mail_scan_url" : "report_file_url";
      final taskRef =
          FirebaseFirestore.instance.collection("tasks").doc(taskId);
      await taskRef.update({fieldName: downloadUrl});
      ref.invalidate(taskProvider(widget.taskId));
      log("Task scan URL updated successfully.");
    } catch (e) {
      log("Failed to update task scan URL: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Upload File',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_selectedFile != null) ...[
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: Text(_selectedFile!.name),
              subtitle:
                  Text('${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB'),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectFile,
                  icon: Icon(_selectedFile == null
                      ? Icons.upload_file
                      : Icons.change_circle),
                  label: Text(
                      _selectedFile == null ? 'Select File' : 'Change File'),
                ),
              ),
              if (_selectedFile != null) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isUploading
                      ? null
                      : () => _uploadFile(context, widget.fileType),
                  // onPressed: _upload,
                  child: _isUploading
                      ? const CircularProgressIndicator()
                      : const Text('Upload'),
                ),
              ]
            ],
          ),
          if (_uploadUrl != null) ...[
            const SizedBox(height: 12),
            Text('✅ Uploaded Successfully!',
                style: TextStyle(color: Colors.green)),
            SelectableText(_uploadUrl!,
                style: const TextStyle(fontSize: 12, color: Colors.blue)),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class AnnotationBottomSheet extends ConsumerStatefulWidget {
  final String taskId;
  Map<String, String>? currentAnnotations;

  AnnotationBottomSheet(this.taskId, this.currentAnnotations, {super.key});

  @override
  ConsumerState<AnnotationBottomSheet> createState() =>
      _AnnotationBottomSheetState();
}

class _AnnotationBottomSheetState extends ConsumerState<AnnotationBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _objectController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ajouter une annotation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // OBJET DE L'ACTIVITE
              CustomFormField(
                label: "Destinateur",
                hintText: "Entrez l'destinataire de l'annotation",
                textInputType: TextInputType.text,
                controller: _receiverController,
              ),
              const SizedBox(height: 10),

              // DESCRIPTION OF THE TASK
              CustomFormField(
                label: "Objet",
                hintText: "Entrer la objet de l'annotation",
                textInputType: TextInputType.text,
                controller: _objectController,
              ),
              const SizedBox(height: 10),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Colors.grey),
                      foregroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {
                      context.pop();
                    },
                    child: const Text(
                      "Annuler",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomFilledButton(
                      text: "Enregistrer",
                      onPressed: () async {
                        final receiver = _receiverController.text;
                        final object = _objectController.text;

                        if (widget.currentAnnotations != null)
                          widget.currentAnnotations![receiver] = object;
                        else
                          widget.currentAnnotations = {receiver: object};

                        final taskRef = FirebaseFirestore.instance
                            .collection("tasks")
                            .doc(widget.taskId);
                        await taskRef.update({
                          "annotations": widget.currentAnnotations,
                        });
                        ref.invalidate(taskProvider(widget.taskId));
                        log("Task scan URL updated successfully.");

                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
