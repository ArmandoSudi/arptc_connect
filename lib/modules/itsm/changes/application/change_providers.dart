import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/application/itsm_providers.dart';
import '../../shared/application/itsm_session.dart';
import '../../shared/domain/collaboration.dart';
import '../../shared/domain/itsm_audit_event.dart';
import '../../shared/domain/pagination.dart';
import '../data/change_repository.dart';
import '../data/firebase_change_command_gateway.dart';
import '../data/firestore_change_repository.dart';
import '../domain/changes_domain.dart';
import 'change_access_policy.dart';
import 'change_command_controller.dart';
import 'change_commands.dart';

final changeAccessPolicyProvider = Provider<ChangeAccessPolicy>(
  (ref) => const ChangeAccessPolicy(),
);

final changeRepositoryProvider = Provider<ChangeRepository>(
  (ref) => FirestoreChangeRepository(ref.watch(fireStoreProvider)),
);

final changeCommandGatewayProvider = Provider<ChangeCommandGateway>(
  (ref) => FirebaseChangeCommandGateway(
    FirebaseChangeCallableInvoker(ref.watch(firebaseFunctionsProvider)),
  ),
);

final changeCommandControllerProvider =
    FutureProvider.autoDispose<ChangeCommandController>((ref) async {
  final session = await ref.watch(itsmSessionProvider.future);
  if (session == null) throw const ItsmSessionRequiredException();
  return ChangeCommandController(
    session: session,
    accessPolicy: ref.watch(changeAccessPolicyProvider),
    gateway: ref.watch(changeCommandGatewayProvider),
    executor: ref.watch(itsmCommandExecutorProvider),
  );
});

class ChangeFirstPageRequest {
  const ChangeFirstPageRequest({
    required this.query,
    this.limit = PageRequest.defaultLimit,
  });

  final ChangeRequestQuery query;
  final int limit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeFirstPageRequest &&
          query == other.query &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(query, limit);
}

class ChangePageRequest {
  const ChangePageRequest({required this.query, required this.page});

  final ChangeRequestQuery query;
  final PageRequest page;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangePageRequest &&
          query == other.query &&
          page.limit == other.page.limit &&
          page.cursor == other.page.cursor &&
          page.direction == other.page.direction;

  @override
  int get hashCode =>
      Object.hash(query, page.limit, page.cursor, page.direction);
}

class ChangeCollaborationRequest {
  factory ChangeCollaborationRequest({
    required String changeId,
    int limit = PageRequest.defaultLimit,
  }) {
    final normalizedId = changeId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
          changeId, 'changeId', 'A change ID is required.');
    }
    if (limit < 1 || limit > PageRequest.maximumLimit) {
      throw RangeError.range(limit, 1, PageRequest.maximumLimit, 'limit');
    }
    return ChangeCollaborationRequest._(
      changeId: normalizedId,
      limit: limit,
    );
  }

  const ChangeCollaborationRequest._({
    required this.changeId,
    required this.limit,
  });

  final String changeId;
  final int limit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeCollaborationRequest &&
          changeId == other.changeId &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(changeId, limit);
}

final changePageProvider = FutureProvider.autoDispose
    .family<PageResult<ChangeRequest>, ChangePageRequest>((ref, request) async {
  final session = await ref.watch(itsmSessionProvider.future);
  if (session == null) throw const ItsmSessionRequiredException();
  final policy = ref.read(changeAccessPolicyProvider);
  policy.authorizeRequestScope(session, request.query.scope);
  return ref.read(changeRepositoryProvider).fetchPage(
        principal: session.queryPrincipal,
        query: request.query,
        page: request.page,
      );
});

final changeFirstPageProvider = StreamProvider.autoDispose
    .family<List<ChangeRequest>, ChangeFirstPageRequest>((ref, request) {
  final session = ref.watch(itsmSessionProvider);
  final repository = ref.watch(changeRepositoryProvider);
  final policy = ref.read(changeAccessPolicyProvider);
  return session.when(
    loading: _pendingStream,
    error: (error, stackTrace) => Stream.error(error, stackTrace),
    data: (value) {
      if (value == null) {
        return Stream.error(const ItsmSessionRequiredException());
      }
      policy.authorizeRequestScope(value, request.query.scope);
      return repository.watchFirstPage(
        principal: value.queryPrincipal,
        query: request.query,
        limit: request.limit,
      );
    },
  );
});

final changeRequestProvider =
    StreamProvider.autoDispose.family<ChangeRequest?, String>((ref, changeId) {
  final session = ref.watch(itsmSessionProvider);
  final repository = ref.watch(changeRepositoryProvider);
  return session.when(
    loading: _pendingStream,
    error: (error, stackTrace) => Stream.error(error, stackTrace),
    data: (value) {
      if (value == null) {
        return Stream.error(const ItsmSessionRequiredException());
      }
      return repository.watchById(
        principal: value.queryPrincipal,
        id: changeId,
      );
    },
  );
});

final changeCommentsProvider = StreamProvider.autoDispose
    .family<List<ItsmComment>, ChangeCollaborationRequest>((ref, request) {
  final session = ref.watch(itsmSessionProvider);
  final repository = ref.watch(changeRepositoryProvider);
  return session.when(
    loading: _pendingStream,
    error: (error, stackTrace) => Stream.error(error, stackTrace),
    data: (value) {
      if (value == null) {
        return Stream.error(const ItsmSessionRequiredException());
      }
      return repository.watchComments(
        principal: value.queryPrincipal,
        changeId: request.changeId,
        limit: request.limit,
      );
    },
  );
});

final changeAttachmentsProvider = StreamProvider.autoDispose
    .family<List<ItsmAttachment>, ChangeCollaborationRequest>((ref, request) {
  final session = ref.watch(itsmSessionProvider);
  final repository = ref.watch(changeRepositoryProvider);
  return session.when(
    loading: _pendingStream,
    error: (error, stackTrace) => Stream.error(error, stackTrace),
    data: (value) {
      if (value == null) {
        return Stream.error(const ItsmSessionRequiredException());
      }
      return repository.watchAttachments(
        principal: value.queryPrincipal,
        changeId: request.changeId,
        limit: request.limit,
      );
    },
  );
});

final changeAuditTimelineProvider = StreamProvider.autoDispose
    .family<List<ItsmAuditEvent>, ChangeCollaborationRequest>((ref, request) {
  final session = ref.watch(itsmSessionProvider);
  final repository = ref.watch(changeRepositoryProvider);
  return session.when(
    loading: _pendingStream,
    error: (error, stackTrace) => Stream.error(error, stackTrace),
    data: (value) {
      if (value == null) {
        return Stream.error(const ItsmSessionRequiredException());
      }
      return repository.watchAuditTimeline(
        principal: value.queryPrincipal,
        changeId: request.changeId,
        limit: request.limit,
      );
    },
  );
});

final changeCabMeetingsProvider = StreamProvider.autoDispose
    .family<List<CabMeeting>, String>((ref, changeId) {
  final session = ref.watch(itsmSessionProvider);
  final repository = ref.watch(changeRepositoryProvider);
  final policy = ref.read(changeAccessPolicyProvider);
  return session.when(
    loading: _pendingStream,
    error: (error, stackTrace) => Stream.error(error, stackTrace),
    data: (value) {
      if (value == null) {
        return Stream.error(const ItsmSessionRequiredException());
      }
      policy.authorizeCab(value);
      return repository.watchCabMeetings(
        principal: value.queryPrincipal,
        changeId: changeId,
      );
    },
  );
});

final changeCalendarProvider = StreamProvider.autoDispose
    .family<List<ChangeCalendarEntry>, ChangeCalendarQuery>((ref, query) {
  final session = ref.watch(itsmSessionProvider);
  final repository = ref.watch(changeRepositoryProvider);
  final policy = ref.read(changeAccessPolicyProvider);
  return session.when(
    loading: _pendingStream,
    error: (error, stackTrace) => Stream.error(error, stackTrace),
    data: (value) {
      if (value == null) {
        return Stream.error(const ItsmSessionRequiredException());
      }
      policy.authorizeCalendar(value, query.scope);
      return repository.watchCalendar(
        principal: value.queryPrincipal,
        query: query,
      );
    },
  );
});

Stream<T> _pendingStream<T>() => Stream<T>.multi((_) {});
