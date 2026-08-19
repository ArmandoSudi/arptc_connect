import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/application/itsm_providers.dart';
import '../../shared/application/itsm_session.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../data/security_compliance_data.dart';
import '../domain/security_compliance_domain.dart';
import 'security_compliance_access.dart';
import 'security_compliance_command_controller.dart';
import 'security_compliance_commands.dart';

final securityComplianceApplicationPolicyProvider =
    Provider<SecurityComplianceApplicationPolicy>(
  (ref) => const SecurityComplianceApplicationPolicy(),
);

final securityComplianceRepositoryProvider =
    Provider<SecurityComplianceRepository>(
  (ref) => FirestoreSecurityComplianceRepository(ref.watch(fireStoreProvider)),
);

final securityComplianceCommandGatewayProvider =
    Provider<SecurityComplianceCommandGateway>(
  (ref) => FirebaseSecurityComplianceCommandGateway(
    FirebaseSecurityComplianceCallableInvoker(
      ref.watch(firebaseFunctionsProvider),
    ),
  ),
);

final securityComplianceCommandControllerProvider =
    FutureProvider.autoDispose<SecurityComplianceCommandController>(
  (ref) async {
    _invalidateWhenSessionChanges(ref);
    final session = await ref.watch(itsmSessionProvider.future);
    if (session == null) throw const ItsmSessionRequiredException();
    return SecurityComplianceCommandController(
      session: session,
      policy: ref.watch(securityComplianceApplicationPolicyProvider),
      gateway: ref.watch(securityComplianceCommandGatewayProvider),
      executor: ref.watch(itsmCommandExecutorProvider),
    );
  },
);

final securityComplianceRevisionProvider = FutureProvider.autoDispose
    .family<int, SecurityComplianceIdentity>((ref, identity) {
  return _sessionFuture(ref, identity.scope, (repository, session) {
    return repository.fetchRevision(
      principal: session.queryPrincipal,
      identity: identity,
    );
  });
});

class SecurityComplianceAccessState {
  const SecurityComplianceAccessState({
    required this.canUseSelfService,
    required this.canOperate,
    required this.canSubmitException,
    required this.canViewOwnCompliance,
  });

  const SecurityComplianceAccessState.denied()
      : canUseSelfService = false,
        canOperate = false,
        canSubmitException = false,
        canViewOwnCompliance = false;

  final bool canUseSelfService;
  final bool canOperate;
  final bool canSubmitException;
  final bool canViewOwnCompliance;
}

final securityComplianceAccessProvider =
    Provider.autoDispose<AsyncValue<SecurityComplianceAccessState>>((ref) {
  final policy = ref.watch(securityComplianceApplicationPolicyProvider);
  return ref.watch(itsmSessionProvider).whenData((session) {
    if (session == null) {
      return const SecurityComplianceAccessState.denied();
    }
    return SecurityComplianceAccessState(
      canUseSelfService: policy.canUseSelfService(session),
      canOperate: policy.canOperate(session),
      canSubmitException: policy.canSubmitException(session),
      canViewOwnCompliance: session.role == ItsmRole.user,
    );
  });
});

final securityFindingsFirstPageProvider = StreamProvider.autoDispose
    .family<List<SecurityFinding>, SecurityComplianceFirstPageRequest>(
        (ref, request) {
  return _sessionStream(ref, request.query.scope, (repository, session) {
    return repository.watchFindings(
      principal: session.queryPrincipal,
      request: request,
    );
  });
});

final securityFindingsPageProvider = FutureProvider.autoDispose
    .family<PageResult<SecurityFinding>, SecurityCompliancePageRequest>(
  (ref, request) =>
      _sessionFuture(ref, request.query.scope, (repository, session) {
    return repository.fetchFindings(
      principal: session.queryPrincipal,
      request: request,
    );
  }),
);

final securityExceptionsFirstPageProvider = StreamProvider.autoDispose
    .family<List<SecurityException>, SecurityComplianceFirstPageRequest>(
        (ref, request) {
  return _sessionStream(ref, request.query.scope, (repository, session) {
    return repository.watchExceptions(
      principal: session.queryPrincipal,
      request: request,
    );
  });
});

final securityExceptionsPageProvider = FutureProvider.autoDispose
    .family<PageResult<SecurityException>, SecurityCompliancePageRequest>(
  (ref, request) =>
      _sessionFuture(ref, request.query.scope, (repository, session) {
    return repository.fetchExceptions(
      principal: session.queryPrincipal,
      request: request,
    );
  }),
);

final assetComplianceAssessmentsFirstPageProvider = StreamProvider.autoDispose
    .family<List<AssetComplianceAssessment>,
        SecurityComplianceFirstPageRequest>(
  (ref, request) {
    return _sessionStream(ref, SecurityComplianceScope.operational,
        (repository, session) {
      return repository.watchAssessments(
        principal: session.queryPrincipal,
        request: request,
      );
    });
  },
);

final assetComplianceAssessmentsPageProvider = FutureProvider.autoDispose
    .family<PageResult<AssetComplianceAssessment>,
        SecurityCompliancePageRequest>(
  (ref, request) => _sessionFuture(
    ref,
    SecurityComplianceScope.operational,
    (repository, session) => repository.fetchAssessments(
      principal: session.queryPrincipal,
      request: request,
    ),
  ),
);

final ownDeviceComplianceProvider = StreamProvider.autoDispose
    .family<List<OwnDeviceComplianceProjection>, int>((ref, limit) {
  _validateLimit(limit);
  return _sessionStream(ref, SecurityComplianceScope.selfService,
      (repository, session) {
    if (session.role != ItsmRole.user) {
      throw const SecurityComplianceAccessDenied(
        'Own-device compliance is available to USER self-service only.',
      );
    }
    return repository.watchOwnCompliance(
      principal: session.queryPrincipal,
      limit: limit,
    );
  });
});

final ownDeviceCompliancePageProvider = FutureProvider.autoDispose
    .family<PageResult<OwnDeviceComplianceProjection>, PageRequest>(
  (ref, page) => _sessionFuture(
    ref,
    SecurityComplianceScope.selfService,
    (repository, session) {
      if (session.role != ItsmRole.user) {
        throw const SecurityComplianceAccessDenied(
          'Own-device compliance is available to USER self-service only.',
        );
      }
      return repository.fetchOwnCompliance(
        principal: session.queryPrincipal,
        page: page,
      );
    },
  ),
);

final accessReviewCampaignsFirstPageProvider = StreamProvider.autoDispose
    .family<List<AccessReviewCampaign>, SecurityComplianceFirstPageRequest>(
  (ref, request) {
    return _sessionStream(ref, SecurityComplianceScope.operational,
        (repository, session) {
      return repository.watchCampaigns(
        principal: session.queryPrincipal,
        request: request,
      );
    });
  },
);

final accessReviewCampaignsPageProvider = FutureProvider.autoDispose
    .family<PageResult<AccessReviewCampaign>, SecurityCompliancePageRequest>(
  (ref, request) => _sessionFuture(
    ref,
    SecurityComplianceScope.operational,
    (repository, session) => repository.fetchCampaigns(
      principal: session.queryPrincipal,
      request: request,
    ),
  ),
);

final accessReviewItemsFirstPageProvider = StreamProvider.autoDispose
    .family<List<AccessReviewItem>, SecurityComplianceFirstPageRequest>(
        (ref, request) {
  return _sessionStream(ref, request.query.scope, (repository, session) {
    return repository.watchAccessReviewItems(
      principal: session.queryPrincipal,
      request: request,
    );
  });
});

final accessReviewItemsPageProvider = FutureProvider.autoDispose
    .family<PageResult<AccessReviewItem>, SecurityCompliancePageRequest>(
  (ref, request) =>
      _sessionFuture(ref, request.query.scope, (repository, session) {
    return repository.fetchAccessReviewItems(
      principal: session.queryPrincipal,
      request: request,
    );
  }),
);

final accessCorrectionRequestsProvider = StreamProvider.autoDispose
    .family<List<AccessCorrectionRequest>, int>((ref, limit) {
  _validateLimit(limit);
  final repository = ref.watch(securityComplianceRepositoryProvider);
  final sessionState = ref.watch(itsmSessionProvider);
  return sessionState.when(
    loading: _pendingStream,
    error: (error, stackTrace) => Stream.error(error, stackTrace),
    data: (session) {
      if (session == null) {
        return Stream.error(const ItsmSessionRequiredException());
      }
      return repository.watchCorrectionRequests(
        principal: session.queryPrincipal,
        limit: limit,
      );
    },
  );
});

Stream<T> _sessionStream<T>(
  Ref ref,
  SecurityComplianceScope scope,
  Stream<T> Function(SecurityComplianceRepository, ItsmSession) load,
) {
  final repository = ref.watch(securityComplianceRepositoryProvider);
  final sessionState = ref.watch(itsmSessionProvider);
  final policy = ref.read(securityComplianceApplicationPolicyProvider);
  return sessionState.when(
    loading: _pendingStream,
    error: (error, stackTrace) => Stream.error(error, stackTrace),
    data: (session) {
      if (session == null) {
        return Stream.error(const ItsmSessionRequiredException());
      }
      policy.authorize(session, scope);
      return load(repository, session);
    },
  );
}

Future<T> _sessionFuture<T>(
  Ref ref,
  SecurityComplianceScope scope,
  Future<T> Function(SecurityComplianceRepository, ItsmSession) load,
) async {
  _invalidateWhenSessionChanges(ref);
  final session = await ref.watch(itsmSessionProvider.future);
  if (session == null) throw const ItsmSessionRequiredException();
  ref
      .read(securityComplianceApplicationPolicyProvider)
      .authorize(session, scope);
  return load(ref.read(securityComplianceRepositoryProvider), session);
}

void _invalidateWhenSessionChanges(Ref ref) {
  ref.listen<String?>(currentAuthorizedSessionKeyProvider, (previous, next) {
    if (previous != null && previous != next) ref.invalidateSelf();
  });
}

void _validateLimit(int limit) {
  if (limit < 1 || limit > PageRequest.maximumLimit) {
    throw RangeError.range(limit, 1, PageRequest.maximumLimit, 'limit');
  }
}

Stream<T> _pendingStream<T>() => Stream<T>.multi((_) {});
