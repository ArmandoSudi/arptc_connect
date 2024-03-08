import 'package:arptc_connect/modules/ticketing/data/ticketing_service.dart';
import 'package:arptc_connect/modules/ticketing/domain/ticket.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'async_ticket.g.dart';
@riverpod
class AsyncTicket extends _$AsyncTicket {

  List<Ticket> tickets = [];

  @override
  FutureOr<List<Ticket>> build() async {
    tickets = await fetchProducts();
    return tickets;
  }

  Future<List<Ticket>> fetchProducts() {
    return ref.read(ticketingServiceProvider).fetchAllTickets();
  }

  Future<void> addTicket(Ticket ticket) async {
    state = const AsyncValue.loading();
    ref.read(ticketingServiceProvider).addTicket(ticket);
    state = AsyncValue.data( await fetchProducts());
  }
}