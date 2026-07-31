import '../../shared/domain/pagination.dart';
import '../domain/assets_configuration_domain.dart';

class StockItemQuery {
  const StockItemQuery({
    this.locationId = '',
    this.lowStockOnly = false,
    this.kind,
  });

  final String locationId;
  final bool lowStockOnly;
  final StockItemKind? kind;
}

abstract interface class StockRepository {
  Stream<List<StockLocation>> watchLocations({
    bool activeOnly = true,
    int limit = PageRequest.maximumLimit,
  });

  Future<PageResult<StockItem>> fetchItemsPage({
    required StockItemQuery query,
    required PageRequest page,
  });

  Stream<StockItem?> watchItem(String stockItemId);

  Future<PageResult<StockMovement>> fetchMovementsPage({
    required String stockItemId,
    required PageRequest page,
  });
}

class StockCommandReceipt {
  const StockCommandReceipt({
    required this.commandId,
    required this.movementId,
    required this.acceptedAt,
    required this.wasDuplicate,
  });

  final String commandId;
  final String movementId;
  final DateTime acceptedAt;
  final bool wasDuplicate;
}

abstract interface class StockCommandGateway {
  Future<StockCommandReceipt> submitMovement(StockMovementRequest request);
}
