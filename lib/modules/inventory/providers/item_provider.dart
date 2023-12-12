import 'package:arptc_connect/modules/inventory/models/item.dart';
import 'package:arptc_connect/modules/inventory/providers/inventory_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'item_provider.g.dart';

@riverpod
class AsyncItem extends _$AsyncItem {
  @override
  FutureOr<List<Item>> build() async {
    return fetchItems();
  }

  Future<List<Item>> fetchItems() {
    return ref.read(inventoryServiceProvider).allItems();
  }
}
