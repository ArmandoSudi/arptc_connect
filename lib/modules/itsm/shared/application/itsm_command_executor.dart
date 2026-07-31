import '../data/trusted_command_gateways.dart';

class ItsmCommandExecutor {
  final Map<String, Future<ItsmCommandReceipt>> _inFlight = {};

  Future<ItsmCommandReceipt> executeOnce(
    ItsmCommandContext context,
    Future<ItsmCommandReceipt> Function() execute,
  ) {
    final key = context.idempotencyKey.trim();
    final existing = _inFlight[key];
    if (existing != null) return existing;

    late final Future<ItsmCommandReceipt> pending;
    pending = Future.sync(execute).whenComplete(() {
      if (identical(_inFlight[key], pending)) {
        _inFlight.remove(key);
      }
    });
    _inFlight[key] = pending;
    return pending;
  }

  bool isExecuting(String idempotencyKey) {
    return _inFlight.containsKey(idempotencyKey.trim());
  }
}
