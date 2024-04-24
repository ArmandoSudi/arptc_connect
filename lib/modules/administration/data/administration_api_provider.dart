import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../../../utils/firestore_client.dart';
import '../domain/administration_service.dart';

final administrationAPIProvider = Provider<AdministrationAPI>((ref) {
  return AdministrationAPI(
    firestore: ref.read(fireStoreProvider),
    firestoreClient: ref.read(firestoreClientProvider),
  );
});
