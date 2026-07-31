import 'dart:typed_data';

enum AssetsAttachmentKind {
  assetFile,
  assetPhotograph,
  stockSupportingDocument,
}

class AssetsPickedFile {
  const AssetsPickedFile({
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;
}

abstract interface class AssetsAttachmentFilePicker {
  Future<AssetsPickedFile?> pick({required bool imagesOnly});
}

class AssetsAttachmentUploadRequest {
  AssetsAttachmentUploadRequest({
    required String parentId,
    required this.kind,
    required String attachmentId,
    required String uploadedByUserId,
    required this.file,
  })  : parentId = _identifier(parentId, 'parentId'),
        attachmentId = _identifier(attachmentId, 'attachmentId'),
        uploadedByUserId = _identifier(
          uploadedByUserId,
          'uploadedByUserId',
        ) {
    if (file.bytes.isEmpty || file.bytes.length > maxSizeBytes) {
      throw const AssetsAttachmentException(
        'Attachments must be between 1 byte and 20 MB.',
      );
    }
    if (!_supportedContentType(file.contentType)) {
      throw const AssetsAttachmentException(
        'This file type is not supported.',
      );
    }
    if (kind == AssetsAttachmentKind.assetPhotograph &&
        !file.contentType.toLowerCase().startsWith('image/')) {
      throw const AssetsAttachmentException(
        'Asset photographs must be image files.',
      );
    }
  }

  static const maxSizeBytes = 20 * 1024 * 1024;

  final String parentId;
  final AssetsAttachmentKind kind;
  final String attachmentId;
  final String uploadedByUserId;
  final AssetsPickedFile file;

  String get safeFileName {
    final normalized =
        file.fileName.trim().replaceAll(RegExp(r'[/\\\u0000-\u001f]'), '_');
    return normalized.isEmpty ? 'attachment' : normalized;
  }

  String get storagePath => switch (kind) {
        AssetsAttachmentKind.assetFile =>
          'itsm/assets/$parentId/attachments/$attachmentId/$safeFileName',
        AssetsAttachmentKind.assetPhotograph =>
          'itsm/assets/$parentId/photographs/$attachmentId/$safeFileName',
        AssetsAttachmentKind.stockSupportingDocument =>
          'itsm/stock/$parentId/supportingDocuments/$attachmentId/$safeFileName',
      };

  Map<String, String> get customMetadata => switch (kind) {
        AssetsAttachmentKind.assetFile => {
            'assetId': parentId,
            'resourceKind': 'attachments',
            'resourceId': attachmentId,
            'uploadedByUserId': uploadedByUserId,
            'isInternal': 'true',
          },
        AssetsAttachmentKind.assetPhotograph => {
            'assetId': parentId,
            'resourceKind': 'photographs',
            'resourceId': attachmentId,
            'uploadedByUserId': uploadedByUserId,
            'isInternal': 'true',
          },
        AssetsAttachmentKind.stockSupportingDocument => {
            'stockItemId': parentId,
            'attachmentId': attachmentId,
            'uploadedByUserId': uploadedByUserId,
            'isInternal': 'true',
          },
      };

  String get registrationDocumentPath => switch (kind) {
        AssetsAttachmentKind.assetFile =>
          'assets/$parentId/attachments/$attachmentId',
        AssetsAttachmentKind.assetPhotograph =>
          'assets/$parentId/photographs/$attachmentId',
        AssetsAttachmentKind.stockSupportingDocument =>
          'stockSupportingDocuments/$attachmentId',
      };
}

class AssetsAttachmentUploadResult {
  const AssetsAttachmentUploadResult({
    required this.attachmentId,
    required this.storagePath,
    required this.fileName,
    required this.kind,
  });

  final String attachmentId;
  final String storagePath;
  final String fileName;
  final AssetsAttachmentKind kind;
}

abstract interface class AssetsAttachmentGateway {
  Future<AssetsAttachmentUploadResult> uploadAndAwaitRegistration(
    AssetsAttachmentUploadRequest request,
  );
}

class AssetsAttachmentException implements Exception {
  const AssetsAttachmentException(this.message);

  final String message;

  @override
  String toString() => message;
}

String _identifier(String value, String field) {
  final normalized = value.trim();
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$').hasMatch(normalized)) {
    throw AssetsAttachmentException('$field is not a valid identifier.');
  }
  return normalized;
}

bool _supportedContentType(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.startsWith('image/')) return true;
  return const {
    'application/pdf',
    'application/msword',
    'application/vnd.ms-excel',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain',
    'text/csv',
  }.contains(normalized);
}
