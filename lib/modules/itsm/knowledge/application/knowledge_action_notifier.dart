import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/knowledge_command_gateway.dart';

class KnowledgeActionNotifier
    extends StateNotifier<AsyncValue<KnowledgeCommandReceipt?>> {
  KnowledgeActionNotifier() : super(const AsyncData(null));

  Future<KnowledgeCommandReceipt> run(
    Future<KnowledgeCommandReceipt> Function() action,
  ) async {
    if (state.isLoading) {
      throw const KnowledgeActionInProgressException();
    }
    state = const AsyncLoading();
    try {
      final receipt = await action();
      state = AsyncData(receipt);
      return receipt;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void clear() {
    state = const AsyncData(null);
  }
}

class KnowledgeActionInProgressException implements Exception {
  const KnowledgeActionInProgressException();

  @override
  String toString() => 'KnowledgeActionInProgressException()';
}
