import 'dart:typed_data';

class KnowledgePickedFile {
  KnowledgePickedFile({
    required this.fileName,
    required this.contentType,
    required Uint8List bytes,
  }) : bytes = Uint8List.fromList(bytes);

  final String fileName;
  final String contentType;
  final Uint8List bytes;
}

abstract interface class KnowledgeFilePicker {
  Future<KnowledgePickedFile?> pick();
}
