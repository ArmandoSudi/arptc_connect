import 'package:arptc_connect/utils/firestore_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../domain/administration_service.dart';

final administrationAPIProvider = Provider<AdministrationAPI>((ref) {
  return AdministrationAPI(
    firestore: ref.read(fireStoreProvider),
    firestoreClient: ref.read(firestoreClientProvider),
  );
});
