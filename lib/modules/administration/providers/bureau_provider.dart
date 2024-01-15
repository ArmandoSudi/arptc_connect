import 'package:arptc_connect/modules/administration/providers/providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:arptc_connect/modules/administration/providers/administration_api_provider.dart';
import '../../../models/service.dart';

part 'bureau_provider.g.dart';

@riverpod
class BureauController extends _$BureauController {

  List<Service> bureaux = [];

  @override
  FutureOr<List<Service>> build() async {
    String selectedServiceId = ref.watch(selectedServiceProvider);
    debugPrint("Selected Service ID for bureau: $selectedServiceId");

    bureaux = await fetchBureaux();

    if (selectedServiceId == "") {
      print("returning all services");
      return bureaux;
    } else {
      print("returning filtered services");
      return bureaux
          .where((element) => element.directionRef == selectedServiceId)
          .toList();
    }
  }

  Future<List<Service>> fetchBureaux(){
    return ref.read(administrationAPIProvider).fetchBureaux();
  }
}