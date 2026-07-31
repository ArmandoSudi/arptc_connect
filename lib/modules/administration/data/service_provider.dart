import 'package:arptc_connect/modules/administration/data/administration_api_provider.dart';
import 'package:arptc_connect/modules/administration/data/providers.dart';
import 'package:arptc_connect/modules/administration/domain/models/service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'service_provider.g.dart';

@riverpod
class AsyncService extends _$AsyncService {
  List<Service> services = [];

  @override
  FutureOr<List<Service>> build() async {
    String selectedDirRef = ref.watch(selectedDirectionProvider);

    services = await fetchServices();

    if (selectedDirRef == "") {
      return services;
    } else {
      return services
          .where((element) => element.directionRef == selectedDirRef)
          .toList();
    }
  }

  Future<List<Service>> fetchServices() {
    return ref.read(administrationAPIProvider).allServices();
  }

  Future<void> add(Service service) async {
    state = const AsyncValue.loading();
    await ref.read(administrationAPIProvider).addService(service);
    state = AsyncValue.data(await fetchServices());
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    await ref.read(administrationAPIProvider).deleteService(id);
    state = AsyncValue.data(await fetchServices());
  }
}
