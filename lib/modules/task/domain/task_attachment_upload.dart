import 'dart:typed_data';

class TaskAttachmentUpload {
  const TaskAttachmentUpload({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;

  int get size => bytes.lengthInBytes;
}
