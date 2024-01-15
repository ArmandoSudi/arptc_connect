import 'package:arptc_connect/models/direction.dart';
import 'package:arptc_connect/modules/administration/providers/administration_api_provider.dart';
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
}
