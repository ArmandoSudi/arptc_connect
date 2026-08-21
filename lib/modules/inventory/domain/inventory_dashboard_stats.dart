import 'inventory_entities.dart';
import 'material_request.dart';

class InventoryDashboardStats {
  const InventoryDashboardStats({
    required this.submittedCount,
    required this.underReviewCount,
    required this.readyForIssueCount,
    required this.partiallyFulfilledCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.fulfilledTodayCount,
    required this.averageFulfillmentMinutes,
    required this.requestsByStatus,
    required this.topRequestedItems,
    required this.consumptionByDepartment,
    required this.issuesVsReceipts,
    required this.lowStockByWarehouse,
    required this.monthlyFulfillmentTrend,
    required this.oldestPendingRequests,
    required this.recentMovements,
  });

  final int submittedCount;
  final int underReviewCount;
  final int readyForIssueCount;
  final int partiallyFulfilledCount;
  final int lowStockCount;
  final int outOfStockCount;
  final int fulfilledTodayCount;
  final num averageFulfillmentMinutes;
  final Map<String, num> requestsByStatus;
  final Map<String, num> topRequestedItems;
  final Map<String, num> consumptionByDepartment;
  final Map<String, num> issuesVsReceipts;
  final Map<String, num> lowStockByWarehouse;
  final Map<String, num> monthlyFulfillmentTrend;
  final List<MaterialRequest> oldestPendingRequests;
  final List<InventoryStockMovement> recentMovements;

  static const empty = InventoryDashboardStats(
    submittedCount: 0,
    underReviewCount: 0,
    readyForIssueCount: 0,
    partiallyFulfilledCount: 0,
    lowStockCount: 0,
    outOfStockCount: 0,
    fulfilledTodayCount: 0,
    averageFulfillmentMinutes: 0,
    requestsByStatus: {},
    topRequestedItems: {},
    consumptionByDepartment: {},
    issuesVsReceipts: {},
    lowStockByWarehouse: {},
    monthlyFulfillmentTrend: {},
    oldestPendingRequests: [],
    recentMovements: [],
  );
}
