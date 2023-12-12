import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/firebase_providers.dart';
import '../service/inventory_service.dart';

part 'inventory_service_provider.g.dart';

@riverpod
InventoryService inventoryService(InventoryServiceRef ref) {
  return InventoryService(ref.read(fireStoreProvider));
}