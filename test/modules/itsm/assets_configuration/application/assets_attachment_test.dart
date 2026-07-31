import 'dart:typed_data';

import 'package:arptc_connect/modules/itsm/assets_configuration/application/assets_attachment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('asset attachment path and metadata match the trusted registrar', () {
    final request = AssetsAttachmentUploadRequest(
      parentId: 'asset-1',
      kind: AssetsAttachmentKind.assetFile,
      attachmentId: 'attachment-1',
      uploadedByUserId: 'manager-1',
      file: _file('terms.pdf', 'application/pdf'),
    );

    expect(
      request.storagePath,
      'itsm/assets/asset-1/attachments/attachment-1/terms.pdf',
    );
    expect(request.registrationDocumentPath,
        'assets/asset-1/attachments/attachment-1');
    expect(request.customMetadata, {
      'assetId': 'asset-1',
      'resourceKind': 'attachments',
      'resourceId': 'attachment-1',
      'uploadedByUserId': 'manager-1',
      'isInternal': 'true',
    });
  });

  test('stock evidence path binds the upload to its stock item', () {
    final request = AssetsAttachmentUploadRequest(
      parentId: 'stock-1',
      kind: AssetsAttachmentKind.stockSupportingDocument,
      attachmentId: 'evidence-1',
      uploadedByUserId: 'manager-1',
      file: _file('count sheet.csv', 'text/csv'),
    );

    expect(
      request.storagePath,
      'itsm/stock/stock-1/supportingDocuments/evidence-1/count sheet.csv',
    );
    expect(request.registrationDocumentPath,
        'stockSupportingDocuments/evidence-1');
    expect(request.customMetadata['stockItemId'], 'stock-1');
    expect(request.customMetadata['attachmentId'], 'evidence-1');
  });

  test('photographs reject non-images and unsafe identifiers', () {
    expect(
      () => AssetsAttachmentUploadRequest(
        parentId: 'asset-1',
        kind: AssetsAttachmentKind.assetPhotograph,
        attachmentId: 'photo-1',
        uploadedByUserId: 'manager-1',
        file: _file('notes.txt', 'text/plain'),
      ),
      throwsA(isA<AssetsAttachmentException>()),
    );
    expect(
      () => AssetsAttachmentUploadRequest(
        parentId: '../asset',
        kind: AssetsAttachmentKind.assetFile,
        attachmentId: 'attachment-1',
        uploadedByUserId: 'manager-1',
        file: _file('terms.pdf', 'application/pdf'),
      ),
      throwsA(isA<AssetsAttachmentException>()),
    );
  });
}

AssetsPickedFile _file(String name, String contentType) => AssetsPickedFile(
      fileName: name,
      contentType: contentType,
      bytes: Uint8List.fromList([1, 2, 3]),
    );
