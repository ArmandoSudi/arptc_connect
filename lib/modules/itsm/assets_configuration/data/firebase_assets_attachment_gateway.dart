import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../application/assets_attachment.dart';

typedef AssetsAttachmentDelay = Future<void> Function(Duration duration);

class FirebaseAssetsAttachmentGateway implements AssetsAttachmentGateway {
  FirebaseAssetsAttachmentGateway({
    required FirebaseStorage storage,
    required FirebaseFirestore firestore,
    this.registrationAttempts = 12,
    this.registrationPollInterval = const Duration(milliseconds: 500),
    AssetsAttachmentDelay? delay,
  })  : _storage = storage,
        _firestore = firestore,
        _delay = delay ?? Future<void>.delayed {
    if (registrationAttempts < 1) {
      throw RangeError.value(registrationAttempts, 'registrationAttempts');
    }
  }

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;
  final int registrationAttempts;
  final Duration registrationPollInterval;
  final AssetsAttachmentDelay _delay;

  @override
  Future<AssetsAttachmentUploadResult> uploadAndAwaitRegistration(
    AssetsAttachmentUploadRequest request,
  ) async {
    try {
      await _storage.ref(request.storagePath).putData(
            request.file.bytes,
            SettableMetadata(
              contentType: request.file.contentType,
              customMetadata: request.customMetadata,
            ),
          );
    } on FirebaseException catch (error) {
      throw AssetsAttachmentException(
        error.message ?? 'The attachment could not be uploaded.',
      );
    }

    for (var attempt = 0; attempt < registrationAttempts; attempt++) {
      try {
        final snapshot =
            await _firestore.doc(request.registrationDocumentPath).get();
        final data = snapshot.data();
        if (snapshot.exists &&
            data != null &&
            data['storagePath'] == request.storagePath &&
            data['uploadedByUserId'] == request.uploadedByUserId) {
          return AssetsAttachmentUploadResult(
            attachmentId: request.attachmentId,
            storagePath: request.storagePath,
            fileName: request.safeFileName,
            kind: request.kind,
          );
        }
      } on FirebaseException {
        // Storage finalization and Firestore registration converge briefly.
      }
      if (attempt + 1 < registrationAttempts) {
        await _delay(registrationPollInterval);
      }
    }

    throw const AssetsAttachmentException(
      'The file was uploaded but its secure registration did not complete.',
    );
  }
}
