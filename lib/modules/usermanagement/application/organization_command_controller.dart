import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizationCommandState {
  const OrganizationCommandState({
    this.isSubmitting = false,
    this.errorMessage,
    this.completedAction,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final String? completedAction;
}

class OrganizationCommandController
    extends StateNotifier<OrganizationCommandState> {
  OrganizationCommandController({required this.canManage})
      : super(const OrganizationCommandState());

  final bool canManage;

  Future<T> runOrThrow<T>({
    required String action,
    required Future<T> Function() command,
  }) async {
    if (!mounted) {
      throw const OrganizationCommandControllerException(
        'The organization command session is no longer active.',
      );
    }
    if (!canManage) {
      const error = OrganizationCommandControllerException(
        'You have read-only access to organization management.',
      );
      state = OrganizationCommandState(errorMessage: error.message);
      throw error;
    }
    if (state.isSubmitting) {
      throw const OrganizationCommandControllerException(
        'An organization action is already in progress.',
      );
    }
    state = const OrganizationCommandState(isSubmitting: true);
    try {
      final result = await command();
      if (mounted) {
        state = OrganizationCommandState(completedAction: action);
      }
      return result;
    } catch (error) {
      if (mounted) {
        state = OrganizationCommandState(errorMessage: error.toString());
      }
      rethrow;
    }
  }

  Future<T?> run<T>({
    required String action,
    required Future<T> Function() command,
  }) async {
    if (!mounted) return null;
    if (!canManage) {
      state = const OrganizationCommandState(
        errorMessage: 'You have read-only access to organization management.',
      );
      return null;
    }
    if (state.isSubmitting) return null;
    state = const OrganizationCommandState(isSubmitting: true);
    try {
      final result = await command();
      if (mounted) {
        state = OrganizationCommandState(completedAction: action);
      }
      return result;
    } catch (error) {
      if (mounted) {
        state = OrganizationCommandState(errorMessage: error.toString());
      }
      return null;
    }
  }

  Future<bool> runVoid({
    required String action,
    required Future<void> Function() command,
  }) async {
    if (!mounted) return false;
    if (!canManage) {
      state = const OrganizationCommandState(
        errorMessage: 'You have read-only access to organization management.',
      );
      return false;
    }
    if (state.isSubmitting) return false;
    state = const OrganizationCommandState(isSubmitting: true);
    try {
      await command();
      if (mounted) {
        state = OrganizationCommandState(completedAction: action);
      }
      return true;
    } catch (error) {
      if (mounted) {
        state = OrganizationCommandState(errorMessage: error.toString());
      }
      return false;
    }
  }

  void clearFeedback() {
    if (mounted && !state.isSubmitting) {
      state = const OrganizationCommandState();
    }
  }
}

class OrganizationCommandControllerException implements Exception {
  const OrganizationCommandControllerException(this.message);

  final String message;

  @override
  String toString() => message;
}
