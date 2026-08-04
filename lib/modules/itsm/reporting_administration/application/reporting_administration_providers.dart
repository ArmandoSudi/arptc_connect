import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/application/assets_configuration_contracts.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/application/assets_configuration_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/application/itsm_providers.dart';
import '../../shared/application/itsm_session.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../data/reporting_administration_data.dart';
import '../domain/reporting_administration_domain.dart';
import '../domain/catalogue_form_parameters.dart';
import 'audit_log_controller.dart';
import 'catalogue_configuration_controller.dart';
import 'catalogue_parameter_controller.dart';
import 'dashboard_controller.dart';
import 'reporting_administration_access_policy.dart';
import 'reporting_administration_command_controller.dart';
import 'sla_configuration_controller.dart';
import 'workflow_configuration_controller.dart';

final reportingAdministrationAccessPolicyProvider =
    Provider<ReportingAdministrationAccessPolicy>(
  (_) => const ReportingAdministrationAccessPolicy(),
);

final reportSnapshotRepositoryProvider = Provider<ReportSnapshotRepository>(
  (ref) => FirestoreReportSnapshotRepository(ref.watch(fireStoreProvider)),
);
final slaPolicyRepositoryProvider = Provider<SlaPolicyRepository>(
  (ref) => FirestoreSlaPolicyRepository(ref.watch(fireStoreProvider)),
);
final catalogueAdministrationRepositoryProvider =
    Provider<CatalogueAdministrationRepository>(
  (ref) =>
      FirestoreCatalogueAdministrationRepository(ref.watch(fireStoreProvider)),
);

class CatalogueReferenceData {
  const CatalogueReferenceData({
    required this.id,
    required this.type,
    required this.label,
  });

  final String id;
  final String type;
  final String label;
}

final catalogueReferenceDataProvider =
    StreamProvider.autoDispose<List<CatalogueReferenceData>>((ref) {
  final firestore = ref.watch(fireStoreProvider);
  return ref.watch(itsmSessionProvider).when(
        loading: _pending,
        error: (error, stack) => Stream.error(error, stack),
        data: (session) {
          if (session == null) {
            return Stream.error(const ItsmSessionRequiredException());
          }
          if (session.role != ItsmRole.manager) {
            return const Stream.empty();
          }
          return firestore
              .collection('itsmReferenceData')
              .where('active', isEqualTo: true)
              .limit(100)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs
                    .map((document) {
                      final data = document.data();
                      final label = _referenceLabel(data['label']);
                      return CatalogueReferenceData(
                        id: document.id,
                        type: data['type']?.toString().trim() ?? '',
                        label: label.isEmpty ? document.id : label,
                      );
                    })
                    .where((value) => value.type.isNotEmpty)
                    .toList(growable: false),
              );
        },
      );
});

final catalogueFormParametersProvider =
    Provider.autoDispose<AsyncValue<CatalogueFormParameters>>((ref) {
  final references = ref.watch(catalogueReferenceDataProvider);
  final workflows = ref.watch(
    workflowDefinitionsPageProvider(
      WorkflowDefinitionsPageRequest(
        query: const WorkflowConfigurationQuery(
          status: ItsmPublicationState.published,
          workItemType: ItsmWorkItemType.serviceRequest,
        ),
        page: PageRequest(limit: 100),
      ),
    ),
  );
  final slaPolicies = ref.watch(
    slaPoliciesPageProvider(
      SlaPoliciesPageRequest(
        query: const SlaPolicyQuery(
          status: ItsmPublicationState.published,
          workItemType: ItsmWorkItemType.serviceRequest,
        ),
        page: PageRequest(limit: 100),
      ),
    ),
  );
  final configurationItems = ref.watch(configurationItemsProvider(100));

  final states = [references, workflows, slaPolicies, configurationItems];
  for (final state in states) {
    if (state.hasError) {
      return AsyncError(state.error!, state.stackTrace!);
    }
  }
  if (states.any((state) => state.isLoading)) return const AsyncLoading();

  final referenceValues = references.valueOrNull ?? const [];
  Iterable<CatalogueFormOption> optionsForType(String type) => referenceValues
      .where((reference) => reference.type == type)
      .map((reference) => CatalogueFormOption(
            id: reference.id,
            label: reference.label,
          ));
  return AsyncData(
    CatalogueFormParameters(
      categories: optionsForType('catalogue_category'),
      fulfilmentGroups: optionsForType('assignment_group'),
      approvalPolicies: optionsForType('approval_policy'),
      workflows: (workflows.valueOrNull?.items ?? const [])
          .map((workflow) => CatalogueFormOption(
                id: workflow.id,
                label: workflow.name,
                version: workflow.currentPublishedVersion,
              )),
      slaPolicies: (slaPolicies.valueOrNull?.items ?? const [])
          .map((policy) => CatalogueFormOption(
                id: policy.id,
                label: policy.name,
                version: policy.currentPublishedVersion,
              )),
      configurationItems:
          (configurationItems.valueOrNull ?? const <ConfigurationItemSummary>[])
              .map((item) => CatalogueFormOption(
                    id: item.id,
                    label: item.name,
                  )),
    ),
  );
});
final workflowDefinitionRepositoryProvider =
    Provider<WorkflowDefinitionRepository>(
  (ref) => FirestoreWorkflowDefinitionRepository(ref.watch(fireStoreProvider)),
);
final reportingAdministrationCommandGatewayProvider =
    Provider<ReportingAdministrationCommandGateway>(
  (ref) => FirebaseReportingAdministrationCommandGateway(
    FirebaseReportingAdministrationCallableInvoker(
      ref.watch(firebaseFunctionsProvider),
    ),
  ),
);
final auditEventRepositoryProvider = Provider<AuditEventRepository>(
  (ref) => FirestoreAuditEventRepository(
    ref.watch(fireStoreProvider),
    ref.watch(reportingAdministrationCommandGatewayProvider),
  ),
);

final reportingAdministrationAccessProvider =
    Provider.autoDispose<AsyncValue<ReportingAdministrationAccessState>>((ref) {
  final policy = ref.watch(reportingAdministrationAccessPolicyProvider);
  return ref.watch(itsmSessionProvider).whenData((session) {
    if (session == null ||
        !policy.allows(session, ReportingAdministrationCapability.section)) {
      return const ReportingAdministrationAccessState.denied();
    }
    return ReportingAdministrationAccessState(
      role: session.role,
      canAccess: true,
      canOperate: policy.allows(
        session,
        ReportingAdministrationCapability.mutateConfiguration,
      ),
      isReadOnly: policy.getReadOnly(session),
    );
  });
});

final dashboardControllerProvider = Provider<DashboardController>(
  (ref) => DashboardController(
    accessPolicy: ref.watch(reportingAdministrationAccessPolicyProvider),
  ),
);

final currentReportSnapshotProvider = StreamProvider.autoDispose
    .family<ItsmReportSnapshot?, ReportSnapshotType?>((ref, requestedType) {
  final sessionState = ref.watch(itsmSessionProvider);
  final repository = ref.watch(reportSnapshotRepositoryProvider);
  final controller = ref.watch(dashboardControllerProvider);
  return sessionState.when(
    loading: _pending,
    error: (error, stack) => Stream.error(error, stack),
    data: (session) {
      if (session == null) {
        return Stream.error(const ItsmSessionRequiredException());
      }
      return repository.watchCurrent(
        principal: session.queryPrincipal,
        query: controller.queryFor(session, type: requestedType),
      );
    },
  );
});

class SlaPoliciesPageRequest {
  const SlaPoliciesPageRequest({required this.query, required this.page});
  final SlaPolicyQuery query;
  final PageRequest page;

  @override
  bool operator ==(Object other) =>
      other is SlaPoliciesPageRequest &&
      query.status == other.query.status &&
      query.workItemType == other.query.workItemType &&
      query.serviceId == other.query.serviceId &&
      _samePage(page, other.page);

  @override
  int get hashCode => Object.hash(
        query.status,
        query.workItemType,
        query.serviceId,
        page.limit,
        page.cursor,
        page.direction,
      );
}

final slaPoliciesPageProvider = FutureProvider.autoDispose
    .family<PageResult<SlaPolicyConfiguration>, SlaPoliciesPageRequest>(
  (ref, request) => _withSession(ref, (session) {
    return ref.watch(slaPolicyRepositoryProvider).fetchPolicies(
          principal: session.queryPrincipal,
          query: request.query,
          page: request.page,
        );
  }),
);

class CatalogueItemsPageRequest {
  const CatalogueItemsPageRequest({required this.query, required this.page});
  final CatalogueAdministrationQuery query;
  final PageRequest page;

  @override
  bool operator ==(Object other) =>
      other is CatalogueItemsPageRequest &&
      query.status == other.query.status &&
      query.categoryId == other.query.categoryId &&
      _samePage(page, other.page);

  @override
  int get hashCode => Object.hash(
        query.status,
        query.categoryId,
        page.limit,
        page.cursor,
        page.direction,
      );
}

final catalogueItemsPageProvider = FutureProvider.autoDispose
    .family<PageResult<CatalogueItemConfiguration>, CatalogueItemsPageRequest>(
  (ref, request) => _withSession(ref, (session) {
    return ref.watch(catalogueAdministrationRepositoryProvider).fetchItems(
          principal: session.queryPrincipal,
          query: request.query,
          page: request.page,
        );
  }),
);

class WorkflowDefinitionsPageRequest {
  const WorkflowDefinitionsPageRequest(
      {required this.query, required this.page});
  final WorkflowConfigurationQuery query;
  final PageRequest page;

  @override
  bool operator ==(Object other) =>
      other is WorkflowDefinitionsPageRequest &&
      query.status == other.query.status &&
      query.module == other.query.module &&
      query.workItemType == other.query.workItemType &&
      _samePage(page, other.page);

  @override
  int get hashCode => Object.hash(
        query.status,
        query.module,
        query.workItemType,
        page.limit,
        page.cursor,
        page.direction,
      );
}

final workflowDefinitionsPageProvider = FutureProvider.autoDispose
    .family<PageResult<WorkflowConfiguration>, WorkflowDefinitionsPageRequest>(
  (ref, request) => _withSession(ref, (session) {
    return ref.watch(workflowDefinitionRepositoryProvider).fetchDefinitions(
          principal: session.queryPrincipal,
          query: request.query,
          page: request.page,
        );
  }),
);

class AuditEventsPageRequest {
  const AuditEventsPageRequest({required this.query, required this.page});
  final AuditQuery query;
  final PageRequest page;

  @override
  bool operator ==(Object other) =>
      other is AuditEventsPageRequest &&
      query.from == other.query.from &&
      query.to == other.query.to &&
      query.dimension == other.query.dimension &&
      query.value == other.query.value &&
      _samePage(page, other.page);

  @override
  int get hashCode => Object.hash(
        query.from,
        query.to,
        query.dimension,
        query.value,
        page.limit,
        page.cursor,
        page.direction,
      );
}

final auditEventsPageProvider = FutureProvider.autoDispose
    .family<PageResult<GlobalAuditEvent>, AuditEventsPageRequest>(
  (ref, request) => _withSession(ref, (session) {
    return ref.watch(auditEventRepositoryProvider).fetchEvents(
          principal: session.queryPrincipal,
          query: request.query,
          page: request.page,
        );
  }),
);

final slaPolicyProvider = StreamProvider.autoDispose
    .family<SlaPolicyConfiguration?, String>((ref, policyId) {
  return _sessionStream(ref, (session) {
    return ref.watch(slaPolicyRepositoryProvider).watchPolicy(
          principal: session.queryPrincipal,
          policyId: policyId,
        );
  });
});

final catalogueItemProvider = StreamProvider.autoDispose
    .family<CatalogueItemConfiguration?, String>((ref, itemId) {
  return _sessionStream(ref, (session) {
    return ref.watch(catalogueAdministrationRepositoryProvider).watchItem(
          principal: session.queryPrincipal,
          itemId: itemId,
        );
  });
});

final workflowDefinitionProvider = StreamProvider.autoDispose
    .family<WorkflowConfiguration?, String>((ref, workflowId) {
  return _sessionStream(ref, (session) {
    return ref.watch(workflowDefinitionRepositoryProvider).watchDefinition(
          principal: session.queryPrincipal,
          workflowId: workflowId,
        );
  });
});

class ConfigurationVersionsPageRequest {
  const ConfigurationVersionsPageRequest({
    required this.parentId,
    required this.page,
  });

  final String parentId;
  final PageRequest page;

  @override
  bool operator ==(Object other) =>
      other is ConfigurationVersionsPageRequest &&
      parentId == other.parentId &&
      _samePage(page, other.page);

  @override
  int get hashCode =>
      Object.hash(parentId, page.limit, page.cursor, page.direction);
}

final slaPolicyVersionsProvider = FutureProvider.autoDispose.family<
    PageResult<SlaPolicyVersionConfiguration>,
    ConfigurationVersionsPageRequest>((ref, request) {
  return _withSession(ref, (session) {
    return ref.watch(slaPolicyRepositoryProvider).fetchVersions(
          principal: session.queryPrincipal,
          policyId: request.parentId,
          page: request.page,
        );
  });
});

final catalogueItemVersionsProvider = FutureProvider.autoDispose.family<
    PageResult<CatalogueItemVersionConfiguration>,
    ConfigurationVersionsPageRequest>((ref, request) {
  return _withSession(ref, (session) {
    return ref.watch(catalogueAdministrationRepositoryProvider).fetchVersions(
          principal: session.queryPrincipal,
          itemId: request.parentId,
          page: request.page,
        );
  });
});

final workflowVersionsProvider = FutureProvider.autoDispose.family<
    PageResult<WorkflowVersionConfiguration>,
    ConfigurationVersionsPageRequest>((ref, request) {
  return _withSession(ref, (session) {
    return ref.watch(workflowDefinitionRepositoryProvider).fetchVersions(
          principal: session.queryPrincipal,
          workflowId: request.parentId,
          page: request.page,
        );
  });
});

final reportingAdministrationCommandControllerProvider =
    FutureProvider.autoDispose<ReportingAdministrationCommandController>(
  (ref) async {
    final session = await ref.watch(itsmSessionProvider.future);
    if (session == null) throw const ItsmSessionRequiredException();
    return ReportingAdministrationCommandController(
      session: session,
      accessPolicy: ref.watch(reportingAdministrationAccessPolicyProvider),
      gateway: ref.watch(reportingAdministrationCommandGatewayProvider),
    );
  },
);

final slaConfigurationControllerProvider =
    FutureProvider.autoDispose<SlaConfigurationController>(
  (ref) async => SlaConfigurationController(
    await ref.watch(reportingAdministrationCommandControllerProvider.future),
  ),
);
final catalogueConfigurationControllerProvider =
    FutureProvider.autoDispose<CatalogueConfigurationController>(
  (ref) async => CatalogueConfigurationController(
    await ref.watch(reportingAdministrationCommandControllerProvider.future),
  ),
);
final catalogueParameterControllerProvider =
    FutureProvider.autoDispose<CatalogueParameterController>(
  (ref) async => CatalogueParameterController(
    await ref.watch(reportingAdministrationCommandControllerProvider.future),
  ),
);
final workflowConfigurationControllerProvider =
    FutureProvider.autoDispose<WorkflowConfigurationController>(
  (ref) async => WorkflowConfigurationController(
    await ref.watch(reportingAdministrationCommandControllerProvider.future),
  ),
);
final auditLogControllerProvider =
    FutureProvider.autoDispose<AuditLogController>(
  (ref) async {
    final session = await ref.watch(itsmSessionProvider.future);
    if (session == null) throw const ItsmSessionRequiredException();
    return AuditLogController(
      session: session,
      policy: ref.watch(reportingAdministrationAccessPolicyProvider),
      repository: ref.watch(auditEventRepositoryProvider),
    );
  },
);

String _referenceLabel(Object? value) {
  if (value is Map) {
    final english = value['en']?.toString().trim() ?? '';
    if (english.isNotEmpty) return english;
    return value['fr']?.toString().trim() ?? '';
  }
  return value?.toString().trim() ?? '';
}

Future<T> _withSession<T>(
  Ref ref,
  Future<T> Function(ItsmSession session) execute,
) async {
  final session = await ref.watch(itsmSessionProvider.future);
  if (session == null) throw const ItsmSessionRequiredException();
  ref.watch(reportingAdministrationAccessPolicyProvider).authorize(
        session,
        ReportingAdministrationCapability.section,
      );
  return execute(session);
}

Stream<T> _pending<T>() => Stream<T>.multi((_) {});

Stream<T> _sessionStream<T>(
  Ref ref,
  Stream<T> Function(ItsmSession session) execute,
) {
  final sessionState = ref.watch(itsmSessionProvider);
  return sessionState.when(
    loading: _pending,
    error: (error, stack) => Stream.error(error, stack),
    data: (session) {
      if (session == null) {
        return Stream.error(const ItsmSessionRequiredException());
      }
      ref.read(reportingAdministrationAccessPolicyProvider).authorize(
            session,
            ReportingAdministrationCapability.section,
          );
      return execute(session);
    },
  );
}

bool _samePage(PageRequest left, PageRequest right) =>
    left.limit == right.limit &&
    left.cursor == right.cursor &&
    left.direction == right.direction;
