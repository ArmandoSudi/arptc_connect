enum InventoryRole {
  none('NONE'),
  user('USER'),
  manager('MANAGER'),
  admin('ADMIN');

  const InventoryRole(this.value);

  final String value;

  static InventoryRole fromValue(Object? value) {
    final normalized = value?.toString().trim().toUpperCase() ?? '';
    return values.firstWhere(
      (role) => role.value == normalized,
      orElse: () => InventoryRole.none,
    );
  }
}

class InventoryAccessPolicy {
  const InventoryAccessPolicy(this.role);

  final InventoryRole role;

  bool get canAccess => role != InventoryRole.none;
  bool get canBrowseCatalogue => canAccess;
  bool get canSubmitOwnRequest => role == InventoryRole.user;
  bool get canSubmitOnBehalf => role == InventoryRole.manager;
  bool get canReadOwnRequests => canAccess;
  bool get canReadAllRequests =>
      role == InventoryRole.manager || role == InventoryRole.admin;
  bool get canReadExactStock => canReadAllRequests;
  bool get canManageInventory => role == InventoryRole.manager;
  bool get canProcessRequests => role == InventoryRole.manager;
  bool get canExecuteStockOperations => role == InventoryRole.manager;
  bool get canManageParameters => role == InventoryRole.manager;
  bool get canReadAudit =>
      role == InventoryRole.manager || role == InventoryRole.admin;
  bool get isReadOnlyAdmin => role == InventoryRole.admin;
}

class InventoryAccessDenied implements Exception {
  const InventoryAccessDenied(this.message);

  final String message;

  @override
  String toString() => message;
}
