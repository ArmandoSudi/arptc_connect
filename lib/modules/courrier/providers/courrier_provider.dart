import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/courrier_model.dart';
import 'courrier_service_provider.dart';

part 'courrier_provider.g.dart';

final dateFilterProvider = StateProvider<DateTime?>((ref) => null);

@riverpod
class AsyncCourrier extends _$AsyncCourrier {

  List<Courrier> courriers = [];

  @override
  FutureOr<List<Courrier>> build() async {
    courriers = await fetchCourriers();
    return courriers;
  }

  Future<List<Courrier>> fetchCourriers() {
    return ref.read(courrierServiceProvider).allCourriers();
  }

  Future<void> filteredList(String query) async {
    state = const AsyncValue.loading();
    if (query == "") {
      state = AsyncValue.data(courriers);
    } else {
      state = AsyncValue.data(courriers.where((courrier) => courrier.sender.contains(query)).toList());
    }
  }

  Future<void> filterByDate(DateTime date) async {
    state = const AsyncValue.loading();
    if (date == null) {
      state = AsyncValue.data(courriers);
    } else {
      state = AsyncValue.data(courriers.where((courrier) => courrier.date.month == date.month).toList());
    }
  }

}
