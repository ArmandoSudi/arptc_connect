import 'package:arptc_connect/modules/administration/data/administration_api_provider.dart';
import 'package:arptc_connect/modules/administration/domain/models/direction.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'directions_provider.g.dart';

@riverpod
class DirectionsController extends _$DirectionsController {
  @override
  FutureOr<List<Direction>> build() async {
    return fetchDirections();
  }

  Future<List<Direction>> fetchDirections(){
    return ref.read(administrationAPIProvider).fetchDirections();
  }

  Future<void> add(Direction direction) async {
    state = const AsyncValue.loading();
    await ref.read(administrationAPIProvider).addDirection(direction);
    state = AsyncValue.data( await fetchDirections());
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    await ref.read(administrationAPIProvider).deleteDirection(id);
    state = AsyncValue.data( await fetchDirections());
  }

}
