import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../service/administration_service.dart';

final administrationServiceProvider = Provider<AdministrationService>((ref) {
  return AdministrationService(ref.read(fireStoreProvider));
});

