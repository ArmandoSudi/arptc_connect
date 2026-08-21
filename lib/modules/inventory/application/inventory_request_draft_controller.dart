import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/inventory_domain.dart';

class InventoryRequestDraftLine {
  const InventoryRequestDraftLine({
    required this.item,
    required this.quantity,
  });

  final InventoryCatalogueItem item;
  final InventoryQuantity quantity;

  InventoryRequestDraftLine copyWith({InventoryQuantity? quantity}) =>
      InventoryRequestDraftLine(
        item: item,
        quantity: quantity ?? this.quantity,
      );
}

class InventoryRequestDraft {
  const InventoryRequestDraft({
    this.lines = const [],
    this.justification = '',
    this.deliveryDestination = '',
  });

  final List<InventoryRequestDraftLine> lines;
  final String justification;
  final String deliveryDestination;

  InventoryRequestDraft copyWith({
    List<InventoryRequestDraftLine>? lines,
    String? justification,
    String? deliveryDestination,
  }) =>
      InventoryRequestDraft(
        lines: lines ?? this.lines,
        justification: justification ?? this.justification,
        deliveryDestination: deliveryDestination ?? this.deliveryDestination,
      );
}

class InventoryRequestDraftController
    extends StateNotifier<InventoryRequestDraft> {
  InventoryRequestDraftController() : super(const InventoryRequestDraft());

  void setQuantity(
    InventoryCatalogueItem item,
    InventoryQuantity quantity,
  ) {
    if (!quantity.isPositive) {
      remove(item.id);
      return;
    }
    final lines = [...state.lines];
    final index = lines.indexWhere((line) => line.item.id == item.id);
    final next = InventoryRequestDraftLine(item: item, quantity: quantity);
    if (index < 0) {
      lines.add(next);
    } else {
      lines[index] = next;
    }
    state = state.copyWith(lines: List.unmodifiable(lines));
  }

  void remove(String itemId) {
    state = state.copyWith(
      lines: List.unmodifiable(
        state.lines.where((line) => line.item.id != itemId),
      ),
    );
  }

  void setDetails(
      {required String justification, required String destination}) {
    state = state.copyWith(
      justification: justification.trim(),
      deliveryDestination: destination.trim(),
    );
  }

  void clear() => state = const InventoryRequestDraft();
}
