import 'package:arptc_connect/modules/administration/providers/administration_api_provider.dart';
import 'package:arptc_connect/modules/administration/providers/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/service.dart';

part 'service_provider.g.dart';

@riverpod
class AsyncService extends _$AsyncService {
  List<Service> services = [];

  @override
  FutureOr<List<Service>> build(String directionRef) async {

    String selectedDirRef = ref.watch(selectedDirectionProvider);
    print("selectedDirRed: $selectedDirRef");

    services = await fetchServices();

    if (selectedDirRef == "") {
      print("returning all services");
      return services;
    } else {
      print("returning filtered services");
      return services
          .where((element) => element.directionRef == selectedDirRef)
          .toList();
    }
    return services;
  }

  Future<List<Service>> fetchServices() {
    return ref.read(administrationAPIProvider).allServices();
  }
}
