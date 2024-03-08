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

  Future<void> addTicket(Ticket ticket) async {
    try {
      await firestoreClient.add(
        collection: "tickets",
        data: ticket.toMap(),
      );
    } catch (err) {
      throw (Exception(err));
    }
  }
}

final ticketingServiceProvider = Provider<TicketingService>((ref) {
  return TicketingService(ref.read(firestoreClientProvider),);
});
