import 'package:file_picker/file_picker.dart';

import '../application/assets_attachment.dart';

class PlatformAssetsAttachmentFilePicker implements AssetsAttachmentFilePicker {
  const PlatformAssetsAttachmentFilePicker();

  @override
  Future<AssetsPickedFile?> pick({required bool imagesOnly}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: imagesOnly ? FileType.image : FileType.custom,
      allowedExtensions: imagesOnly
          ? null
          : const [
              'pdf',
              'jpg',
              'jpeg',
              'png',
              'gif',
              'txt',
              'csv',
              'doc',
              'docx',
              'xls',
              'xlsx',
              'ppt',
              'pptx',
            ],
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const AssetsAttachmentException(
        'The selected file could not be read.',
      );
    }
    return AssetsPickedFile(
      fileName: file.name,
      contentType: _contentType(file.name, file.extension),
      bytes: bytes,
    );
  }
}

String _contentType(String fileName, String? extension) {
  final suffix = (extension ?? fileName.split('.').last).toLowerCase();
  return switch (suffix) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'txt' => 'text/plain',
    'csv' => 'text/csv',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt' => 'application/vnd.ms-powerpoint',
    'pptx' =>
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    _ => 'application/octet-stream',
  };
}
