import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../domain/administration_service.dart';

final administrationAPIProvider = Provider<AdministrationAPI>((ref) {
  return AdministrationAPI(ref.read(fireStoreProvider));
});

