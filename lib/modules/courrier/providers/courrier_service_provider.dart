import 'package:arptc_connect/modules/courrier/service/courrier_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';

final courrierServiceProvider = Provider<CourrierService>((ref) {
  return CourrierService(ref.read(fireStoreProvider));
});