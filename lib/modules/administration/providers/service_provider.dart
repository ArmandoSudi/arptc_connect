import 'package:arptc_connect/modules/administration/providers/administration_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/service.dart';

part 'service_provider.g.dart';

@riverpod
class AsyncService extends _$AsyncService {

  List<Service> services = [];

  @override
  FutureOr<List<Service>> build(String directionRef) async {
   return services;
  }

  Future<List<Service>> fetchServices(){
    return ref.read(administrationServiceProvider).allServices();
  }

  Future<List<Service>> servicesByDirectionRef(String directionRef) async {

    print("Loading services...");

    services = await fetchServices();

    if (directionRef == ""){
      print("returning all services");
      return services;
    } else {
      print("returning filtered services");
      return services.where((element) => element.directionRef == directionRef).toList();
    }

  }

}