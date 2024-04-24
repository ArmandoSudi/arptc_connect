import 'package:arptc_connect/modules/administration/data/administration_api_provider.dart';
import 'package:arptc_connect/modules/administration/data/providers.dart';
import 'package:arptc_connect/modules/administration/domain/models/service.dart';
import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/models/bureau.dart';

part 'bureau_provider.g.dart';

@riverpod
class BureauController extends _$BureauController {

  List<Service> bureaux = [];

  @override
  FutureOr<List<Service>> build() async {

    String selectedServiceId = ref.watch(selectedServiceProvider);

    bureaux = await fetchBureaux();

    if (selectedServiceId == "") {
      print("returning all Bureaux");
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

  Future<void> add(Bureau bureau) async {
    state = const AsyncValue.loading();
    await ref.read(administrationAPIProvider).addBureau(bureau);
    state = AsyncValue.data(await fetchBureaux());
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    await ref.read(administrationAPIProvider).deleteBureau(id);
    state = AsyncValue.data(await fetchBureaux());
  }
}