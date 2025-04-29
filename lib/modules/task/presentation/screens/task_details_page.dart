import 'dart:async';
import 'dart:developer';

import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:arptc_connect/modules/task/data/task_repository.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';

class TaskDetailsPage extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailsPage(this.taskId, {super.key});

  @override
  ConsumerState<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends ConsumerState<TaskDetailsPage> {
  late Future<String> _imageUrlFuture;

  @override
  void initState() {
    super.initState();
    _imageUrlFuture = _getDownloadUrl(
        "gs://arptc-connect.firebasestorage.app/20131010_184913-MIX_Original.jpg");
  }

  // Function to get the download URL
  Future<String> _getDownloadUrl(String imagePath) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(imagePath);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print("Error getting download URL: $e");
      // Return a placeholder URL or rethrow the error depending on your logic
      // For simplicity, rethrowing here. Handle appropriately in your UI.
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncTask = ref.watch(taskProvider(widget.taskId));

    final theme = Theme.of(context);

    return Scaffold(
      body: ContentView(
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
                    title: "Tasks",
                    description: 'Gestion des tickets d\'intervention'),
                Expanded(
                  child: Container(),
                ),
                TextButton(
                  onPressed: () {
                    context.go("/service/tasks/task}");
                  },
                  child: const Text(
                    "Voir les tickets",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            asyncTask.when(
              data: (task) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.label,
                                style: theme.textTheme.titleMedium!
                                    .copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 20),

                            // DATE LABEL
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Date d'émission",
                                  style: theme.textTheme.labelMedium,
                                ),
                                Text(
                                  "Date d'accusé réception",
                                  style: theme.textTheme.labelMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                            const Text("Remarques"),
                            const SizedBox(height: 10),
                            Text(task.observation),

                            Text(task.status),
                            Text(task.type),
                            Text(task.sender ?? "N/A"),
                            Text(task.receiver ?? "N/A"),
                            Text(task.mailScanUrl ?? "N/A"),
                            Text(task.reportFileUrl ?? "N/A"),
                            Text(task.department),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Scans",
                                  style: theme.textTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green)),
                              IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    builder: (context) =>
                                        const FilePickerBottomSheet(),
                                  );
                                },
                                icon:
                                    const Icon(Icons.add, color: Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading:
                                        Icon(Icons.remove_red_eye_outlined),
                                    title: Text("image 001.png"),
                                    trailing:
                                        Icon(Icons.delete_outline_outlined),
                                  ),
                                  ListTile(
                                    leading:
                                        Icon(Icons.remove_red_eye_outlined),
                                    title: Text("Scan.pdf"),
                                    trailing:
                                        Icon(Icons.delete_outline_outlined),
                                  ),
                                ],
                              )),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Livrables",
                                  style: theme.textTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue)),
                              IconButton(
                                onPressed: () {
                                  context.go(
                                      "/service/tasks/task/${task.id}/scan");
                                },
                                icon: const Icon(Icons.add, color: Colors.blue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Column(
                                children: [
                                  ListTile(
                                    leading:
                                        Icon(Icons.remove_red_eye_outlined),
                                    title: Text("Rapport de l'activite 1"),
                                    trailing:
                                        Icon(Icons.delete_outline_outlined),
                                  ),
                                  ListTile(
                                    leading:
                                        Icon(Icons.remove_red_eye_outlined),
                                    title: Text(
                                        "Contrat de maintenance avec le prestateur"),
                                    trailing:
                                        Icon(Icons.delete_outline_outlined),
                                  ),
                                ],
                              )),
                        ],
                      ),
                    )
                  ],
                );
              },
              error: (error, stack) => const Center(child: Text("Error")),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),

            Image.network(
              "https://firebasestorage.googleapis.com/v0/b/arptc-connect.firebasestorage.app/o/20131010_184913-MIX_Original.jpg?alt=media&token=da23b1d2-c2c6-486d-bc67-c83763918c7a",
              width: 100,
              height: 100,
            ),

            FutureBuilder<String>(
              future: _imageUrlFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Show a loading indicator while waiting for the URL
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  // Show an error message or placeholder if URL fetching fails
                  print(
                      "FutureBuilder Error: ${snapshot.error}"); // Log the specific error
                  return const Center(
                      child: Icon(Icons.error_outline,
                          color: Colors.red, size: 50));
                  // Or return Text('Error loading image: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  // Once the URL is available, display the image
                  final imageUrl = snapshot.data!;
                  return Image.network(
                    imageUrl,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover, // Adjust fit as needed
                    // Optional: Add a loading builder for Image.network itself
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child; // Image loaded
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null, // Show progress if possible
                        ),
                      );
                    },
                    // Optional: Add an error builder for Image.network errors (e.g., 404)
                    errorBuilder: (context, error, stackTrace) {
                      print(
                          "Image.network Error: $error"); // Log the specific error
                      return const Center(
                          child: Icon(Icons.broken_image,
                              size: 50, color: Colors.grey));
                      // Or return Text('Could not load image');
                    },
                  );
                } else {
                  // Should not happen in typical cases, but good to have a fallback
                  return const Center(child: Text('No image URL found.'));
                }
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add your onPressed code here!
        },
        label: const Text('Next'),
        icon: const Icon(Icons.thumb_up),
        backgroundColor: Colors.pink,
      ),
    );
  }
}

class FilePickerBottomSheet extends StatefulWidget {
  const FilePickerBottomSheet({super.key});

  @override
  State<FilePickerBottomSheet> createState() => _FilePickerBottomSheetState();
}

class _FilePickerBottomSheetState extends State<FilePickerBottomSheet> {
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

  Future<void> _uploadFile(BuildContext context) async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('uploads')
          .child(_selectedFile!.name);

      final metadata = SettableMetadata(
        contentType: _selectedFile!.extension == 'pdf'
            ? 'application/pdf'
            : 'application/octet-stream',
        customMetadata: {'picked-file-path': _selectedFile!.path ?? ''},
      );

      log('_selectedFile!.path: ${_selectedFile!.path}');
      log('METADATA $metadata');

      UploadTask uploadTask;

      if (kIsWeb || _selectedFile!.bytes != null) {
        log('_selectedFile!.bytes: LENGTH:: ${_selectedFile!.bytes?.length}');
        uploadTask = storageRef.putData(_selectedFile!.bytes!, metadata);
      } else if (_selectedFile!.path != null) {
        final file = io.File(_selectedFile!.path!);
        uploadTask = storageRef.putFile(file, metadata);
      } else {
        throw Exception("Invalid file data or path.");
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint(
            "Upload is ${progress.toStringAsFixed(2)}% complete. State: ${snapshot.state}");
      }, onError: (e) {
        debugPrint("Error during upload stream: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload stream failed: $e')),
        );
        setState(() => _isUploading = false);
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('uploads').add({
        'file_name': _selectedFile!.name,
        'url': downloadUrl,
        'uploaded_at': Timestamp.now(),
        'size_kb': (_selectedFile!.size / 1024).toStringAsFixed(2),
      });

      setState(() {
        _uploadUrl = downloadUrl;
      });
    } catch (e) {
      debugPrint("Upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _upload() async {
    UploadTask? uploadTask;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || !mounted) return;

      setState(() {
        _isUploading = true;
        progress = 0;
      });

      final fileName = result.files.first.name;
      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) throw Exception("File data is null");

      // Improve reliability (especially on web)
      final storage = FirebaseStorage.instance
        ..setMaxUploadRetryTime(const Duration(minutes: 10))
        ..setMaxOperationRetryTime(const Duration(minutes: 5));

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = "files/${timestamp}_$fileName";
      final ref = storage.ref().child(path);

      final metadata = SettableMetadata(
        contentType: result.files.first.extension == 'pdf'
            ? 'application/pdf'
            : 'application/octet-stream',
        cacheControl: 'public,max-age=31536000',
      );

      uploadTask = ref.putData(fileBytes, metadata);

      bool isUploadStarted = false;

      uploadTask.snapshotEvents.listen(
        (snapshot) {
          isUploadStarted = true;

          if (!mounted) return;
          setState(() {
            progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          });

          if (snapshot.state == TaskState.success) {
            snapshot.ref.getDownloadURL().then((url) {
              if (!mounted) return;
              setState(() => _uploadUrl = url);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upload successful!')),
              );
            });
          }
        },
        onError: (error) {
          log("Upload stream error: $error");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: ${error.toString()}')),
            );
            setState(() => _isUploading = false);
          }
        },
        cancelOnError: true,
      );
    } catch (e, stack) {
      log("Upload error: $e");
      log("Stack trace: $stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _isUploading = false);
      }
    }
  }

  Future<UploadTask?> uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file was selected'),
        ),
      );

      return null;
    }

    final fileName = result?.files.first.name;
    final fileBytes = result?.files.first.bytes;
    if (fileBytes == null) throw Exception("File data is null");

    UploadTask uploadTask;

    // Create a Reference to the file
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('flutter-tests')
        .child('/some-image.jpg');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'picked-file-path': fileName!},
    );

    if (kIsWeb) {
      uploadTask = ref.putData(fileBytes, metadata);
    } else {
      uploadTask = ref.putFile(io.File(fileName!), metadata);
    }

    return Future.value(uploadTask);
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
          ElevatedButton(
            onPressed: _upload,
            child: const Text('Televerser'),
          ),
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
                  onPressed: _isUploading ? null : () => _uploadFile(context),
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
