import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/item.dart';
import 'inventory_service_provider.dart';

part 'async_item.g.dart';

@riverpod
class AsyncItems extends _$AsyncItems {

  List<Item> items = [];

  @override
  FutureOr<List<Item>> build() async {
    items = await fetchItems();
    return items;
  }

  Future<List<Item>> fetchItems() {
    return ref.read(inventoryServiceProvider).allItems();
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    if (query == "") {
      state = AsyncValue.data(items);
    } else {
      state = AsyncValue.data(items.where((item) => item.name.contains(query)).toList());
    }
  }

  Future<void> addItem(Item item) async {
    state = const AsyncValue.loading();
    await ref.read(inventoryServiceProvider).addItem(item);
    state = AsyncValue.data( await fetchItems());
  }

}
