import 'dart:developer';

import 'package:arptc_connect/modules/ticketing/domain/ticket.dart';
import 'package:arptc_connect/utils/firestore_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TicketingService {
  final FirestoreClient firestoreClient;

  TicketingService(this.firestoreClient);

  Future<List<Ticket>> fetchAllTickets() async {
    try {
      final results = await firestoreClient.fetchAll(collection: "tickets");
      return results
          .map(
            (item) => Ticket.fromMap(item.data, id: item.id),
          )
          .toList();
    } catch (err) {
      throw (Exception(err));
    }
  }

  Future<Ticket> getTicketById(String id) async {
    try{
      final result = await firestoreClient.fetchById(collection: "tickets", id: id);
      return Ticket.fromMap(result.data, id: result.id);
    } catch (err) {
      log("getTicketById => Error : $err");
      throw (Exception(err));
    }
  }

  Future<void> addTicket(Ticket ticket) async {
    try {
      await firestoreClient.add(
        collection: "tickets",
        data: ticket.toMap(),
      );
    } catch (err) {
      log("addTicket => Error : $err");
      throw (Exception(err));
    }
  }

  Future<void> updateTicket(Ticket ticket) async {
    try {
      await firestoreClient.update(collection: 'tickets', data: ticket.toMap());
    } catch (err) {
      log("InventorySer::updateProduct => Error : ${err}");
    }
  }
}

final ticketingServiceProvider = Provider<TicketingService>((ref) {
  return TicketingService(ref.read(firestoreClientProvider),);
});


