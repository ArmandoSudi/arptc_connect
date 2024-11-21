import 'package:arptc_connect/modules/ticketing/data/ticketing_service.dart';
import 'package:arptc_connect/modules/ticketing/domain/ticket.dart';
import 'package:arptc_connect/modules/ticketing/presentation/screens/ticket_details_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'async_ticket_details.g.dart';
@riverpod
class AsyncTicketDetails extends _$AsyncTicketDetails{

  @override
  FutureOr<Ticket> build(String ticketId) async {
    final ticket =  await fetchTicket(ticketId);
    ref.read(ticketStatusProvider.notifier).state = ticket.isSolved;
    return ticket;
  }

  Future<Ticket> fetchTicket(String ticketId) {
    return ref.read(ticketingServiceProvider).getTicketById(ticketId);
  }

}