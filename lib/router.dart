import 'dart:async';

import 'package:arptc_connect/modules/authentication/screens/login_screen.dart';
import 'package:arptc_connect/modules/authentication/screens/account_access_screen.dart';
import 'package:arptc_connect/modules/authentication/screens/session_loading_screen.dart';
import 'package:arptc_connect/modules/authentication/screens/verify_email_screen.dart';
import 'package:arptc_connect/modules/authentication/screens/initial_password_change_screen.dart';
import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/courrier/screens/add_annotation_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/add_courrier_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/details_courrier.dart';
import 'package:arptc_connect/modules/courrier/screens/list_courriers_screen.dart';
import 'package:arptc_connect/modules/dashboard/presentation/screens/main_dashboard_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/create_incident_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/incident_role_gate_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/manager_incident_details_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/manager_incident_history_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/manager_incident_parameters_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/manager_incident_queue_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/my_incident_details_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/appro_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/inventory_main_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/livraison_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/product/manage_items_screen.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/application/assets_configuration_contracts.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/presentation/assets_configuration_presentation.dart';
import 'package:arptc_connect/modules/itsm/changes/presentation/screens/cab_approvals_screen.dart';
import 'package:arptc_connect/modules/itsm/changes/presentation/screens/change_calendar_screen.dart';
import 'package:arptc_connect/modules/itsm/changes/presentation/screens/change_request_detail_screen.dart';
import 'package:arptc_connect/modules/itsm/changes/presentation/screens/change_requests_screen.dart';
import 'package:arptc_connect/modules/itsm/changes/presentation/screens/create_change_screen.dart';
import 'package:arptc_connect/modules/itsm/knowledge/presentation/screens/knowledge_article_screen.dart';
import 'package:arptc_connect/modules/itsm/knowledge/presentation/screens/knowledge_base_screen.dart';
import 'package:arptc_connect/modules/itsm/knowledge/presentation/screens/knowledge_editor_screen.dart';
import 'package:arptc_connect/modules/itsm/knowledge/presentation/screens/knowledge_editor_loader_screen.dart';
import 'package:arptc_connect/modules/itsm/knowledge/presentation/screens/knowledge_manager_queue_screen.dart';
import 'package:arptc_connect/modules/itsm/knowledge/presentation/screens/knowledge_manager_review_screen.dart';
import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_navigation.dart';
import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_route_access.dart';
import 'package:arptc_connect/modules/itsm/presentation/screens/itsm_feature_access_screen.dart';
import 'package:arptc_connect/modules/itsm/presentation/screens/itsm_landing_screen.dart';
import 'package:arptc_connect/modules/itsm/presentation/screens/itsm_section_overview_screen.dart';
import 'package:arptc_connect/modules/itsm/presentation/widgets/itsm_route_guard.dart';
import 'package:arptc_connect/modules/itsm/reporting_administration/domain/reporting_administration_domain.dart';
import 'package:arptc_connect/modules/itsm/reporting_administration/presentation/reporting_administration_presentation.dart';
import 'package:arptc_connect/modules/itsm/security_compliance/presentation/security_compliance_presentation.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/support/presentation/screens/create_service_request_screen.dart';
import 'package:arptc_connect/modules/itsm/support/presentation/screens/my_requests_screen.dart';
import 'package:arptc_connect/modules/itsm/support/presentation/screens/service_catalogue_item_screen.dart';
import 'package:arptc_connect/modules/itsm/support/presentation/screens/service_catalogue_screen.dart';
import 'package:arptc_connect/modules/itsm/support/presentation/screens/service_request_detail_screen.dart';
import 'package:arptc_connect/modules/itsm/support/presentation/screens/service_request_queue_screen.dart';
import 'package:arptc_connect/modules/news/presentation/screens/news_editor_screen.dart';
import 'package:arptc_connect/modules/news/presentation/screens/news_module_screen.dart';
import 'package:arptc_connect/modules/news/presentation/screens/news_post_details_screen.dart';
import 'package:arptc_connect/modules/news/presentation/screens/news_review_screen.dart';
import 'package:arptc_connect/modules/notifications/presentation/screens/notifications_inbox_screen.dart';
import 'package:arptc_connect/modules/profile/presentation/screens/profile_screen.dart';
import 'package:arptc_connect/modules/service/screens/main_service_screen.dart';
import 'package:arptc_connect/modules/social/screens/social_agents_page.dart';
import 'package:arptc_connect/modules/task/presentation/screens/task_details_page.dart';
import 'package:arptc_connect/modules/task/presentation/screens/task_form_screen.dart';
import 'package:arptc_connect/modules/task/presentation/screens/tasks_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/agent_directory_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/module_details_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/modules_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/agent_details_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/organization_audit_history_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/organization_details_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/organization_structure_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/organization_unit_details_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/organizations_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/user_management_main_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_access_gate.dart';
import 'package:arptc_connect/screens/navigators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'modules/authentication/providers/authentication_provider.dart';
import 'modules/home/presentation/home_screen.dart';
import 'modules/inventory/presentation/cart/cart_screen.dart';
import 'package:arptc_connect/modules/meeting_hall/meeting_hall.dart';

const routerInitialLocation = '/home';

final goRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorHomeKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellHome');
  final shellNavigatorDashboardKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
  final shellNavigatorProfileKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellProfile');
  final shellNavigatorServiceKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellService');
  final shellNavigatorCourrierKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellCourrier');

  return GoRouter(
    initialLocation: routerInitialLocation,
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const NoTransitionPage(
          // child: RootScreen(label: 'A', detailsPath: '/courriers/details'),
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/session-loading',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SessionLoadingScreen(),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: VerifyEmailScreen(),
        ),
      ),
      GoRoute(
        path: '/change-initial-password',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: InitialPasswordChangeScreen(),
        ),
      ),
      GoRoute(
        path: '/account-access',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AccountAccessScreen(),
        ),
      ),
      GoRoute(
        path: '/error',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: Center(
            child: Text('Error'),
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // the UI shell
          return ScaffoldWithNestedNavigation(navigationShell: navigationShell);
        },
        branches: [
          // Home branch
          StatefulShellBranch(navigatorKey: shellNavigatorHomeKey, routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => const NoTransitionPage(
                // child: RootScreen(label: 'A', detailsPath: '/courriers/details'),
                child: HomeScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'news/:postId',
                  builder: (context, state) => NewsPostDetailsScreen(
                    postId: state.pathParameters['postId'] as String,
                  ),
                ),
                GoRoute(
                  path: 'notifications',
                  builder: (context, state) => const NotificationsInboxScreen(),
                ),
              ],
            ),
          ]),

          // Service branch
          StatefulShellBranch(navigatorKey: shellNavigatorServiceKey, routes: [
            // Service
            GoRoute(
              path: '/service',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: MainServiceScreen(),
              ),
              routes: [
                // Social
                GoRoute(
                  path: 'social',
                  builder: (context, state) => const SocialAgentsPage(),
                ),

                // News / company communication
                GoRoute(
                  path: 'news',
                  builder: (context, state) => const NewsModuleScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const NewsEditorScreen(),
                    ),
                    GoRoute(
                      path: 'edit/:postId',
                      builder: (context, state) => NewsEditorScreen(
                        postId: state.pathParameters['postId'] as String,
                      ),
                    ),
                    GoRoute(
                      path: 'review/:postId',
                      builder: (context, state) => NewsReviewScreen(
                        postId: state.pathParameters['postId'] as String,
                      ),
                    ),
                    GoRoute(
                      path: 'details/:postId',
                      builder: (context, state) => NewsPostDetailsScreen(
                        postId: state.pathParameters['postId'] as String,
                      ),
                    ),
                  ],
                ),

                // Inventory
                GoRoute(
                  path: 'inventory',
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: InventoryMainScreen(),
                  ),
                  routes: [
                    // Management
                    GoRoute(
                      path: 'management',
                      builder: (context, state) => const ManageItemScreen(),
                    ),

                    // Approvisionnement
                    GoRoute(
                      path: 'appro',
                      builder: (context, state) => const ApproScreen(),
                    ),

                    // Livraison
                    GoRoute(
                      path: 'livraison',
                      builder: (context, state) => const LivraisonScreen(),
                    ),

                    GoRoute(
                      path: 'cart',
                      builder: (context, state) => const CartScreen(),
                    ),
                  ],
                ),

                // Preserve legacy deep links while moving callers to the
                // canonical /services/itsm tree.
                ...buildItsmCompatibilityRoutes(),

                // Courriers
                GoRoute(
                  path: 'courriers',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: ListCourriersScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: ':courrierId',
                      builder: (context, state) => DetailsCourrierScreen(
                          state.pathParameters['courrierId'] as String),
                    ),
                    GoRoute(
                      path: 'enregistrer',
                      builder: (context, state) => const AddCourrierScreen(),
                    ),
                    GoRoute(
                      path: ':courrierId/annotations/enregistrer',
                      builder: (context, state) => AddAnnotationScreen(
                          courrierId:
                              state.pathParameters['courrierId'] as String),
                    ),
                  ],
                ),

                // Tasks
                GoRoute(
                  path: 'tasks',
                  pageBuilder: (context, state) => const MaterialPage(
                    child: TasksScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const TaskFormScreen(),
                    ),
                    GoRoute(
                      path: ':taskId',
                      builder: (context, state) => TaskDetailsPage(
                          state.pathParameters['taskId'] as String),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (context, state) => TaskFormScreen(
                            taskId: state.pathParameters['taskId'] as String,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Meeting Halls
                GoRoute(
                  path: 'meeting-hall',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: MeetingHallsScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (context, state) {
                        final hallId = state.pathParameters['id']!;
                        final selectedDate = _parseMeetingHallSelectedDate(
                          state.queryParameters['date'],
                        );
                        final reservationId = _parseMeetingHallReservationId(
                          state.queryParameters,
                        );
                        // return HallDetailsScreen(
                        //   hall: ref.read(meetingHallsProvider)
                        //       .firstWhere((hall) => hall.id == hallId),
                        // );
                        return HallDetailsScreen(
                          key: ValueKey(
                            'meeting-hall-$hallId-${_meetingHallDateKey(selectedDate)}-${reservationId ?? 'no-reservation'}',
                          ),
                          hallId: hallId,
                          initialSelectedDate: selectedDate,
                          initialReservationId: reservationId,
                        );
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'meetinghall',
                  redirect: (context, state) {
                    return state.location.replaceFirst(
                      '/service/meetinghall',
                      '/service/meeting-hall',
                    );
                  },
                  routes: [
                    GoRoute(
                      path: ':id',
                      redirect: (context, state) {
                        final hallId = state.pathParameters['id']!;
                        return Uri(
                          path: '/service/meeting-hall/$hallId',
                          queryParameters: state.queryParameters.isEmpty
                              ? null
                              : state.queryParameters,
                        ).toString();
                      },
                    ),
                  ],
                ),

                // User Management
                GoRoute(
                  path: 'usermanagement',
                  redirect: (context, state) {
                    if (state.location != '/service/usermanagement') {
                      return null;
                    }
                    final policy = ref.read(userManagementAccessPolicyProvider);
                    return policy.canReadPrivateProfiles
                        ? '/service/usermanagement/organizations'
                        : '/service/usermanagement/agents';
                  },
                  pageBuilder: (context, state) => const MaterialPage(
                    child: UserManagementAccessGate(
                      child: UserManagementMainScreen(),
                    ),
                  ),
                  routes: [
                    GoRoute(
                      path: 'organizations',
                      builder: (context, state) =>
                          const UserManagementAccessGate(
                        requirePrivateProfiles: true,
                        child: OrganizationsScreen(),
                      ),
                      routes: [
                        GoRoute(
                          path: ':organizationId',
                          builder: (context, state) => UserManagementAccessGate(
                            requirePrivateProfiles: true,
                            child: OrganizationDetailsScreen(
                              organizationId:
                                  state.pathParameters['organizationId']!,
                            ),
                          ),
                          routes: [
                            GoRoute(
                              path: 'audit',
                              builder: (context, state) =>
                                  UserManagementAccessGate(
                                requirePrivateProfiles: true,
                                child: OrganizationAuditHistoryScreen(
                                  organizationId:
                                      state.pathParameters['organizationId']!,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'structure',
                      builder: (context, state) =>
                          const UserManagementAccessGate(
                        requirePrivateProfiles: true,
                        child: OrganizationStructureScreen(),
                      ),
                      routes: [
                        GoRoute(
                          path: ':unitId',
                          redirect: (_, state) =>
                              (state.queryParameters['organizationId'] ?? '')
                                      .trim()
                                      .isEmpty
                                  ? '/service/usermanagement/structure'
                                  : null,
                          builder: (context, state) => UserManagementAccessGate(
                            requirePrivateProfiles: true,
                            child: OrganizationUnitDetailsScreen(
                              organizationId:
                                  state.queryParameters['organizationId']!,
                              unitId: state.pathParameters['unitId']!,
                            ),
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'departments',
                      redirect: (_, __) => '/service/usermanagement/structure',
                    ),
                    GoRoute(
                      path: 'services',
                      redirect: (_, __) => '/service/usermanagement/structure',
                    ),
                    GoRoute(
                      path: 'bureaux',
                      redirect: (_, __) => '/service/usermanagement/structure',
                    ),
                    GoRoute(
                      path: 'agents',
                      builder: (context, state) =>
                          const UserManagementAccessGate(
                        child: AgentDirectoryScreen(),
                      ),
                      routes: [
                        GoRoute(
                          path: 'add',
                          redirect: (_, __) => '/service/usermanagement/agents',
                        ),
                        GoRoute(
                          path: ':agentId',
                          pageBuilder: (context, state) => MaterialPage(
                            fullscreenDialog: true,
                            child: UserManagementAccessGate(
                              requirePrivateProfiles: true,
                              child: AgentDetailsScreen(
                                agentId:
                                    state.pathParameters['agentId'] as String,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'modules',
                      builder: (context, state) =>
                          const UserManagementAccessGate(
                        requirePrivateProfiles: true,
                        child: ModulesManagementScreen(),
                      ),
                      routes: [
                        GoRoute(
                          path: ':moduleId',
                          builder: (context, state) => UserManagementAccessGate(
                            requirePrivateProfiles: true,
                            child: ModuleDetailsScreen(
                              moduleId: state.pathParameters['moduleId']!,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            _buildItsmRoute(),
          ]),

          // Courriers branch
          StatefulShellBranch(
            navigatorKey: shellNavigatorCourrierKey,
            routes: [
              GoRoute(
                path: '/courriers',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ListCourriersScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':courrierId',
                    builder: (context, state) => DetailsCourrierScreen(
                        state.pathParameters['courrierId'] as String),
                  ),
                  GoRoute(
                    path: 'enregistrer',
                    builder: (context, state) => const AddCourrierScreen(),
                  ),
                  GoRoute(
                    path: ':courrierId/annotations/enregistrer',
                    builder: (context, state) => AddAnnotationScreen(
                        courrierId:
                            state.pathParameters['courrierId'] as String),
                  ),
                ],
              ),
            ],
          ),

          // Dashboard branch
          StatefulShellBranch(
              navigatorKey: shellNavigatorDashboardKey,
              routes: [
                GoRoute(
                  path: '/dashboard',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    // child: RootScreen(label: 'A', detailsPath: '/courriers/details'),
                    child: MainDashboardScreen(),
                  ),
                ),
              ]),

          // Profile branch
          StatefulShellBranch(
            navigatorKey: shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      )
    ],
    redirect: (context, state) {
      final authState = ref.watch(authStateProvider);
      final sessionState = ref.watch(authorizedSessionProvider);

      // log("1. REDIRECTING TO DASHBOARD SCREEN");

      return authState.when(
          data: (data) {
            User? user = data;
            final isLoginRoute = state.matchedLocation == '/login';
            final isSessionLoadingRoute =
                state.matchedLocation == '/session-loading';
            final isVerifyEmailRoute = state.matchedLocation == '/verify-email';
            final isInitialPasswordRoute =
                state.matchedLocation == '/change-initial-password';
            final isAccountAccessRoute =
                state.matchedLocation == '/account-access';

            // if (user == null && state.location == '/'){
            if (user == null) {
              if (isLoginRoute) {
                return null;
              }
              debugPrint(":: GO TO LOGIN SCREEN");
              final from = Uri.encodeComponent(state.location);
              return '/login?from=$from';
            }

            switch (sessionState.status) {
              case AuthenticationStatus.initializing:
              case AuthenticationStatus.profileLoading:
                if (isSessionLoadingRoute) {
                  return null;
                }
                return _authorizationRoute(
                  state,
                  '/session-loading',
                );
              case AuthenticationStatus.emailVerificationRequired:
                if (isVerifyEmailRoute) {
                  return null;
                }
                return _authorizationRoute(state, '/verify-email');
              case AuthenticationStatus.initialPasswordChangeRequired:
                if (isInitialPasswordRoute) {
                  return null;
                }
                return _authorizationRoute(
                  state,
                  '/change-initial-password',
                );
              case AuthenticationStatus.accountDisabled:
              case AuthenticationStatus.failure:
                if (isAccountAccessRoute) {
                  return null;
                }
                return _authorizationRoute(state, '/account-access');
              case AuthenticationStatus.authenticated:
                if (isSessionLoadingRoute ||
                    isVerifyEmailRoute ||
                    isInitialPasswordRoute ||
                    isAccountAccessRoute) {
                  return _postAuthorizationRedirectLocation(state);
                }
              case AuthenticationStatus.unauthenticated:
              case AuthenticationStatus.authenticating:
              case AuthenticationStatus.registrationInProgress:
                break;
            }

            final email = user.email;
            if (email != null && email.isNotEmpty) {
              unawaited(
                ref.read(authServiceProvider).warmLocalSessionIfNeeded(email),
              );
            }

            if (isLoginRoute) {
              return _postAuthorizationRedirectLocation(state);
            }

            return null;
          },
          loading: () => null,
          error: (e, trace) =>
              state.matchedLocation == '/error' ? null : '/error');
    },
  );
});

GoRoute _buildItsmRoute() {
  return GoRoute(
    path: ItsmRoutes.root,
    pageBuilder: (context, state) => const NoTransitionPage(
      child: ItsmRouteGuard(child: ItsmLandingScreen()),
    ),
    routes: [
      GoRoute(
        path: 'support',
        builder: (context, state) => const ItsmRouteGuard(
          section: ItsmSection.support,
          child: ItsmSectionOverviewScreen(section: ItsmSection.support),
        ),
        routes: [
          _buildCanonicalIncidentRoute(),
          _buildServiceCatalogueRoute(),
          _buildServiceRequestsRoute(),
          _buildMyRequestsRoute(),
          _buildKnowledgeBaseRoute(),
        ],
      ),
      _buildAssetsConfigurationRoute(),
      _buildChangesRoute(),
      _buildSecurityComplianceRoute(),
      _buildReportingAdministrationRoute(),
    ],
  );
}

GoRoute _buildReportingAdministrationRoute() {
  const section = ItsmSection.reportingAdministration;
  return GoRoute(
    path: section.route.substring('${ItsmRoutes.root}/'.length),
    builder: (context, state) => ItsmRouteGuard(
      section: section,
      requirement: ItsmRouteRequirement.operationalOrExecutive,
      child: ReportingAdministrationOverviewScreen(
        onOpen: (destination) => context.go(switch (destination) {
          ReportingAdministrationDestination.dashboards =>
            ItsmRoutes.reportingDashboards,
          ReportingAdministrationDestination.sla => ItsmRoutes.slaPolicies,
          ReportingAdministrationDestination.workflows =>
            ItsmRoutes.workflowAdministration,
          ReportingAdministrationDestination.audit => ItsmRoutes.auditLogs,
        }),
      ),
    ),
    routes: [
      GoRoute(
        path: 'dashboards',
        builder: (context, state) => const ItsmRouteGuard(
          section: section,
          feature: ItsmFeature.dashboards,
          requirement: ItsmRouteRequirement.operationalOrExecutive,
          child: ItsmDashboardRouter(),
        ),
        routes: [
          GoRoute(
            path: 'operations',
            builder: (context, state) => const ItsmRouteGuard(
              section: section,
              feature: ItsmFeature.dashboards,
              requirement: ItsmRouteRequirement.operational,
              child: ManagerItsmDashboardScreen(),
            ),
          ),
          GoRoute(
            path: 'executive',
            builder: (context, state) => const ItsmRouteGuard(
              section: section,
              feature: ItsmFeature.dashboards,
              requirement: ItsmRouteRequirement.executive,
              child: AdminItsmDashboardScreen(),
            ),
          ),
          GoRoute(
            path: 'incidents',
            builder: (context, state) => const ItsmRouteGuard(
              section: section,
              feature: ItsmFeature.dashboards,
              requirement: ItsmRouteRequirement.operationalOrExecutive,
              child: IncidentReportingDashboardScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: 'sla',
        builder: (context, state) => ItsmRouteGuard(
          section: section,
          feature: ItsmFeature.sla,
          requirement: ItsmRouteRequirement.operationalOrExecutive,
          child: SlaPoliciesScreen(
            onOpenPolicy: (policyId) =>
                context.push(ItsmRoutes.slaPolicyDetail(policyId)),
          ),
        ),
        routes: [
          GoRoute(
            path: ':policyId',
            builder: (context, state) => ItsmRouteGuard(
              section: section,
              feature: ItsmFeature.sla,
              requirement: ItsmRouteRequirement.operationalOrExecutive,
              child: SlaPolicyDetailScreen(
                policyId: state.pathParameters['policyId'] as String,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: 'service-catalogue',
        redirect: (_, __) => ItsmRoutes.catalogueAdministration,
      ),
      GoRoute(
        path: 'service-catalogue/:itemId',
        redirect: (_, state) => ItsmRoutes.catalogueAdministrationDetail(
          state.pathParameters['itemId'] as String,
        ),
      ),
      GoRoute(
        path: 'workflows',
        builder: (context, state) => ItsmRouteGuard(
          section: section,
          feature: ItsmFeature.workflowConfiguration,
          requirement: ItsmRouteRequirement.operationalOrExecutive,
          child: WorkflowDefinitionsScreen(
            onOpenWorkflow: (workflowId) => context
                .push(ItsmRoutes.workflowAdministrationDetail(workflowId)),
          ),
        ),
        routes: [
          GoRoute(
            path: ':workflowId',
            builder: (context, state) => ItsmRouteGuard(
              section: section,
              feature: ItsmFeature.workflowConfiguration,
              requirement: ItsmRouteRequirement.operationalOrExecutive,
              child: WorkflowDefinitionDetailScreen(
                workflowId: state.pathParameters['workflowId'] as String,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: 'audit-logs',
        builder: (context, state) => ItsmRouteGuard(
          section: section,
          feature: ItsmFeature.auditLogs,
          requirement: ItsmRouteRequirement.operationalOrExecutive,
          child: AuditLogsScreen(
            onOpenEvent: (event) => context.push(
              ItsmRoutes.auditLogDetail(event.id),
              extra: event,
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: ':eventId',
            redirect: (context, state) =>
                state.extra is GlobalAuditEvent ? null : ItsmRoutes.auditLogs,
            builder: (context, state) => ItsmRouteGuard(
              section: section,
              feature: ItsmFeature.auditLogs,
              requirement: ItsmRouteRequirement.operationalOrExecutive,
              child: AuditLogDetailScreen(
                event: state.extra! as GlobalAuditEvent,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

GoRoute _buildChangesRoute() {
  return GoRoute(
    path: ItsmSection.changes.route.substring('${ItsmRoutes.root}/'.length),
    builder: (context, state) => const ItsmRouteGuard(
      section: ItsmSection.changes,
      requirement: ItsmRouteRequirement.selfService,
      child: ItsmSectionOverviewScreen(section: ItsmSection.changes),
    ),
    routes: [
      GoRoute(
        path: ItsmFeature.changeRequests.routeSegment,
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.changes,
          feature: ItsmFeature.changeRequests,
          requirement: ItsmRouteRequirement.selfService,
          child: ChangeRequestsScreen(
            onBack: () => context.go(ItsmRoutes.changes),
            onNewChange: () => context.push('${ItsmRoutes.changeRequests}/new'),
            onSelected: (change) =>
                context.push(ItsmRoutes.changeRequestDetail(change.id)),
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => ItsmRouteGuard(
              section: ItsmSection.changes,
              feature: ItsmFeature.changeRequests,
              requirement: ItsmRouteRequirement.selfService,
              child: CreateChangeScreen(
                onBack: () => context.pop(),
                onCreated: (changeId) =>
                    context.go(ItsmRoutes.changeRequestDetail(changeId)),
              ),
            ),
          ),
          GoRoute(
            path: ':changeId',
            builder: (context, state) => ItsmRouteGuard(
              section: ItsmSection.changes,
              feature: ItsmFeature.changeRequests,
              requirement: ItsmRouteRequirement.selfService,
              child: ChangeRequestDetailScreen(
                changeId: state.pathParameters['changeId'] as String,
                onBack: () => context.pop(),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: ItsmFeature.approvalsCab.routeSegment,
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.changes,
          feature: ItsmFeature.approvalsCab,
          requirement: ItsmRouteRequirement.operational,
          child: CabApprovalsScreen(
            onBack: () => context.go(ItsmRoutes.changes),
            onSelected: (change) =>
                context.push(ItsmRoutes.changeRequestDetail(change.id)),
          ),
        ),
      ),
      GoRoute(
        path: ItsmFeature.changeCalendar.routeSegment,
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.changes,
          feature: ItsmFeature.changeCalendar,
          requirement: ItsmRouteRequirement.selfService,
          child: ChangeCalendarScreen(
            onBack: () => context.go(ItsmRoutes.changes),
            onSelected: (entry) =>
                context.push(ItsmRoutes.changeRequestDetail(entry.changeId)),
          ),
        ),
      ),
    ],
  );
}

GoRoute _buildAssetsConfigurationRoute() {
  return GoRoute(
    path: ItsmSection.assetsConfiguration.route
        .substring('${ItsmRoutes.root}/'.length),
    builder: (context, state) => ItsmRouteGuard(
      section: ItsmSection.assetsConfiguration,
      requirement: ItsmRouteRequirement.selfService,
      child: AssetsConfigurationOverviewScreen(
        onBack: () => context.go(ItsmRoutes.root),
        onMyAssets: () => context.go(ItsmRoutes.myAssets),
        onAssetRegister: () => context.go(ItsmRoutes.assetRegister),
        onStock: () => context.go(ItsmRoutes.stock),
        onLicences: () => context.go(ItsmRoutes.licences),
        onSuppliersWarranties: () => context.go(ItsmRoutes.suppliersWarranties),
        onCmdb: () => context.go(ItsmRoutes.cmdb),
      ),
    ),
    routes: [
      GoRoute(
        path: ItsmFeature.assets.routeSegment,
        // Only the bare /assets path should default to My Assets. Checking
        // matchedLocation also matches child routes such as /assets/register.
        redirect: (context, state) =>
            Uri.parse(state.location).path == ItsmRoutes.assets
                ? ItsmRoutes.myAssets
                : null,
        routes: [
          GoRoute(
            path: 'my',
            builder: (context, state) => ItsmRouteGuard(
              section: ItsmSection.assetsConfiguration,
              feature: ItsmFeature.assets,
              requirement: ItsmRouteRequirement.selfService,
              child: MyAssetsScreen(
                onBack: () => context.go(ItsmRoutes.assetsConfiguration),
                onAssetSelected: (asset) =>
                    context.push(ItsmRoutes.myAssetDetail(asset.id)),
              ),
            ),
            routes: [
              GoRoute(
                path: ':assetId',
                builder: (context, state) => ItsmRouteGuard(
                  section: ItsmSection.assetsConfiguration,
                  feature: ItsmFeature.assets,
                  requirement: ItsmRouteRequirement.selfService,
                  child: AssetDetailScreen(
                    assetId: state.pathParameters['assetId'] as String,
                    selfService: true,
                    onBack: () => context.pop(),
                    onCatalogueAction: (assetId, action) => context.push(
                      _assetCatalogueRoute(assetId, action),
                    ),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'register',
            builder: (context, state) => ItsmRouteGuard(
              section: ItsmSection.assetsConfiguration,
              feature: ItsmFeature.assets,
              requirement: ItsmRouteRequirement.operational,
              child: AssetRegisterScreen(
                onBack: () => context.go(ItsmRoutes.assetsConfiguration),
                onRegisterAsset: showAssetRegistrationDialog,
                onManageParameters: () =>
                    context.push(ItsmRoutes.assetParameters),
                onAssetSelected: (asset) =>
                    context.push(ItsmRoutes.assetRegisterDetail(asset.id)),
              ),
            ),
            routes: [
              GoRoute(
                path: 'parameters',
                builder: (context, state) => ItsmRouteGuard(
                  section: ItsmSection.assetsConfiguration,
                  feature: ItsmFeature.assets,
                  requirement: ItsmRouteRequirement.operational,
                  child: AssetParametersScreen(onBack: () => context.pop()),
                ),
              ),
              GoRoute(
                path: ':assetId',
                builder: (context, state) => ItsmRouteGuard(
                  section: ItsmSection.assetsConfiguration,
                  feature: ItsmFeature.assets,
                  requirement: ItsmRouteRequirement.operational,
                  child: AssetDetailScreen(
                    assetId: state.pathParameters['assetId'] as String,
                    selfService: false,
                    onBack: () => context.pop(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: ItsmFeature.stock.routeSegment,
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.assetsConfiguration,
          feature: ItsmFeature.stock,
          requirement: ItsmRouteRequirement.operational,
          child: StockScreen(
            onBack: () => context.go(ItsmRoutes.assetsConfiguration),
          ),
        ),
      ),
      GoRoute(
        path: ItsmFeature.licences.routeSegment,
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.assetsConfiguration,
          feature: ItsmFeature.licences,
          requirement: ItsmRouteRequirement.operational,
          child: LicencesScreen(
            onBack: () => context.go(ItsmRoutes.assetsConfiguration),
            onAddLicence: showRegisterLicenceDialog,
            onLicenceSelected: showLicenceActionDialog,
          ),
        ),
      ),
      GoRoute(
        path: ItsmFeature.suppliersWarranties.routeSegment,
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.assetsConfiguration,
          feature: ItsmFeature.suppliersWarranties,
          requirement: ItsmRouteRequirement.operational,
          child: SuppliersWarrantiesScreen(
            onBack: () => context.go(ItsmRoutes.assetsConfiguration),
            onAddSupplier: showAddSupplierDialog,
            onAddContract: showAddContractDialog,
            onAddWarranty: showAddWarrantyDialog,
            onWarrantySelected: showWarrantyClaimDialog,
          ),
        ),
      ),
      GoRoute(
        path: ItsmFeature.cmdb.routeSegment,
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.assetsConfiguration,
          feature: ItsmFeature.cmdb,
          requirement: ItsmRouteRequirement.operational,
          child: CmdbScreen(
            onBack: () => context.go(ItsmRoutes.assetsConfiguration),
            onAddConfigurationItem: showAddConfigurationItemDialog,
            onCreateRelationship: showCreateRelationshipDialog,
            onRetireRelationship: showRetireRelationshipDialog,
          ),
        ),
      ),
    ],
  );
}

String _assetCatalogueRoute(String assetId, AssetCatalogueAction action) {
  final catalogueItemId = switch (action) {
    AssetCatalogueAction.reportFault => 'report_it_incident',
    AssetCatalogueAction.requestRepair => 'equipment_repair',
    AssetCatalogueAction.requestReplacement => 'equipment_replacement',
    AssetCatalogueAction.requestConfiguration => 'asset_configuration',
    AssetCatalogueAction.requestReturn => 'equipment_return_transfer',
  };
  return '${ItsmRoutes.serviceCatalogue}/$catalogueItemId/create'
      '?assetId=${Uri.encodeQueryComponent(assetId)}'
      '&assetAction=${Uri.encodeQueryComponent(action.name)}';
}

GoRoute _buildServiceCatalogueRoute() {
  return GoRoute(
    path: ItsmFeature.serviceCatalogue.routeSegment,
    builder: (context, state) => ItsmRouteGuard(
      section: ItsmSection.support,
      feature: ItsmFeature.serviceCatalogue,
      requirement: ItsmRouteRequirement.selfService,
      child: ServiceCatalogueScreen(
        onItemSelected: (item) => context.push(
          '${ItsmRoutes.serviceCatalogue}/${Uri.encodeComponent(item.id)}',
        ),
        onManageCatalogue: () =>
            context.push(ItsmRoutes.catalogueAdministration),
      ),
    ),
    routes: [
      GoRoute(
        path: 'manage',
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.support,
          feature: ItsmFeature.serviceCatalogue,
          requirement: ItsmRouteRequirement.operational,
          child: ServiceCatalogueAdministrationScreen(
            onOpenItem: (itemId) => context.push(
              ItsmRoutes.catalogueAdministrationDetail(itemId),
            ),
            onManageParameters: () => context.push(
              '${ItsmRoutes.catalogueAdministration}/parameters',
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'parameters',
            builder: (context, state) => ItsmRouteGuard(
              section: ItsmSection.support,
              feature: ItsmFeature.serviceCatalogue,
              requirement: ItsmRouteRequirement.operational,
              child: ServiceCatalogueParametersScreen(
                onOpenWorkflows: () =>
                    context.push(ItsmRoutes.workflowAdministration),
                onOpenSlaPolicies: () => context.push(ItsmRoutes.slaPolicies),
                onOpenConfigurationItems: () => context.push(ItsmRoutes.cmdb),
              ),
            ),
          ),
          GoRoute(
            path: ':itemId',
            builder: (context, state) => ItsmRouteGuard(
              section: ItsmSection.support,
              feature: ItsmFeature.serviceCatalogue,
              requirement: ItsmRouteRequirement.operational,
              child: ServiceCatalogueAdministrationDetailScreen(
                itemId: state.pathParameters['itemId'] as String,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: ':catalogueItemId',
        builder: (context, state) {
          final catalogueItemId =
              state.pathParameters['catalogueItemId'] as String;
          return ItsmRouteGuard(
            section: ItsmSection.support,
            feature: ItsmFeature.serviceCatalogue,
            requirement: ItsmRouteRequirement.selfService,
            child: ServiceCatalogueItemScreen(
              catalogueItemId: catalogueItemId,
              onCreateRequest: (_) => context.push(
                '${ItsmRoutes.serviceCatalogue}/'
                '${Uri.encodeComponent(catalogueItemId)}/create',
              ),
            ),
          );
        },
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => ItsmRouteGuard(
              section: ItsmSection.support,
              feature: ItsmFeature.serviceCatalogue,
              requirement: ItsmRouteRequirement.selfService,
              child: CreateServiceRequestScreen(
                catalogueItemId:
                    state.pathParameters['catalogueItemId'] as String,
                initialResponses: _assetRequestInitialResponses(state),
                onSubmitted: (receipt) => context.go(
                  '${ItsmRoutes.serviceRequests}/'
                  '${Uri.encodeComponent(receipt.requestId)}',
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

GoRoute _buildServiceRequestsRoute() {
  return GoRoute(
    path: ItsmFeature.serviceRequests.routeSegment,
    builder: (context, state) => ItsmRouteGuard(
      section: ItsmSection.support,
      feature: ItsmFeature.serviceRequests,
      requirement: ItsmRouteRequirement.selfService,
      child: ServiceRequestQueueScreen(
        onRequestSelected: (request) => context.push(
          '${ItsmRoutes.serviceRequests}/${Uri.encodeComponent(request.id)}',
        ),
      ),
    ),
    routes: [
      // Keep previously shared catalogue links valid while making the Service
      // Catalog module the only owner of catalogue browsing and request entry.
      GoRoute(
        path: 'catalogue/:catalogueItemId/create',
        redirect: (_, state) => _catalogueCompatibilityLocation(
          state,
          suffix: '/create',
        ),
      ),
      GoRoute(
        path: 'catalogue/:catalogueItemId',
        redirect: (_, state) => _catalogueCompatibilityLocation(state),
      ),
      GoRoute(
        path: 'queue',
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.support,
          feature: ItsmFeature.serviceRequests,
          requirement: ItsmRouteRequirement.selfService,
          child: ServiceRequestQueueScreen(
            onRequestSelected: (request) => context.push(
              '${ItsmRoutes.serviceRequests}/'
              '${Uri.encodeComponent(request.id)}',
            ),
          ),
        ),
      ),
      GoRoute(
        path: ':requestId',
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.support,
          feature: ItsmFeature.serviceRequests,
          requirement: ItsmRouteRequirement.operational,
          child: ServiceRequestDetailScreen(
            requestId: state.pathParameters['requestId'] as String,
          ),
        ),
      ),
    ],
  );
}

String _catalogueCompatibilityLocation(
  GoRouterState state, {
  String suffix = '',
}) {
  final itemId = state.pathParameters['catalogueItemId'] as String;
  final uri = Uri.parse(state.location);
  return uri
      .replace(
        path: '${ItsmRoutes.serviceCatalogue}/'
            '${Uri.encodeComponent(itemId)}$suffix',
      )
      .toString();
}

Map<String, Object?> _assetRequestInitialResponses(GoRouterState state) {
  final queryParameters = Uri.parse(state.location).queryParameters;
  final assetId = queryParameters['assetId']?.trim() ?? '';
  if (assetId.isEmpty) return const {};
  final action = queryParameters['assetAction'];
  return {
    'assetId': assetId,
    if (action == 'requestReturn') 'movementType': 'return',
  };
}

GoRoute _buildMyRequestsRoute() {
  return GoRoute(
    path: ItsmFeature.myRequests.routeSegment,
    builder: (context, state) => ItsmRouteGuard(
      section: ItsmSection.support,
      feature: ItsmFeature.myRequests,
      requirement: ItsmRouteRequirement.selfService,
      child: MyRequestsScreen(
        onRequestSelected: (request) => context.push(
          '${ItsmRoutes.myRequests}/${request.type.value}/'
          '${Uri.encodeComponent(request.id)}',
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: ':type/:workItemId',
        builder: (context, state) {
          final type = ItsmWorkItemType.tryParse(state.pathParameters['type']);
          final id = state.pathParameters['workItemId'] as String;
          final child = switch (type) {
            ItsmWorkItemType.incident => MyIncidentDetailsScreen(ticketId: id),
            ItsmWorkItemType.serviceRequest =>
              MyRequestDetailScreen(requestId: id),
            ItsmWorkItemType.changeRequest => ChangeRequestDetailScreen(
                changeId: id,
                onBack: () => context.pop(),
              ),
            ItsmWorkItemType.securityFinding => SecurityFindingsScreen(
                onBack: () => context.pop(),
              ),
            ItsmWorkItemType.securityException => SecurityExceptionsScreen(
                onBack: () => context.pop(),
              ),
            null => const ItsmFeatureAccessScreen(
                section: ItsmSection.support,
                feature: ItsmFeature.myRequests,
              ),
          };
          return ItsmRouteGuard(
            section: ItsmSection.support,
            feature: ItsmFeature.myRequests,
            requirement: ItsmRouteRequirement.selfService,
            child: child,
          );
        },
      ),
      // Keep pre-index service-request links valid.
      GoRoute(
        path: ':requestId',
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.support,
          feature: ItsmFeature.myRequests,
          requirement: ItsmRouteRequirement.selfService,
          child: MyRequestDetailScreen(
            requestId: state.pathParameters['requestId'] as String,
          ),
        ),
      ),
    ],
  );
}

GoRoute _buildKnowledgeBaseRoute() {
  return GoRoute(
    path: ItsmFeature.knowledgeBase.routeSegment,
    builder: (context, state) => const ItsmRouteGuard(
      section: ItsmSection.support,
      feature: ItsmFeature.knowledgeBase,
      requirement: ItsmRouteRequirement.selfService,
      child: KnowledgeBaseScreen(),
    ),
    routes: [
      GoRoute(
        path: 'manage',
        builder: (context, state) => const ItsmRouteGuard(
          section: ItsmSection.support,
          feature: ItsmFeature.knowledgeBase,
          requirement: ItsmRouteRequirement.operational,
          child: KnowledgeManagerQueueScreen(),
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ItsmRouteGuard(
              section: ItsmSection.support,
              feature: ItsmFeature.knowledgeBase,
              requirement: ItsmRouteRequirement.operational,
              child: KnowledgeEditorScreen(),
            ),
          ),
          GoRoute(
            path: ':articleId/review',
            builder: (context, state) => ItsmRouteGuard(
              section: ItsmSection.support,
              feature: ItsmFeature.knowledgeBase,
              requirement: ItsmRouteRequirement.operational,
              child: KnowledgeManagerReviewScreen(
                articleId: state.pathParameters['articleId'] as String,
              ),
            ),
          ),
          GoRoute(
            path: ':articleId/edit',
            builder: (context, state) => ItsmRouteGuard(
              section: ItsmSection.support,
              feature: ItsmFeature.knowledgeBase,
              requirement: ItsmRouteRequirement.operational,
              child: KnowledgeEditorLoaderScreen(
                articleId: state.pathParameters['articleId'] as String,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: ':articleId',
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.support,
          feature: ItsmFeature.knowledgeBase,
          requirement: ItsmRouteRequirement.selfService,
          child: KnowledgeArticleScreen(
            articleId: state.pathParameters['articleId'] as String,
          ),
        ),
      ),
    ],
  );
}

GoRoute _buildSecurityComplianceRoute() {
  Widget guarded(
    ItsmFeature feature,
    Widget child, {
    ItsmRouteRequirement requirement = ItsmRouteRequirement.automatic,
  }) =>
      ItsmRouteGuard(
        section: ItsmSection.securityCompliance,
        feature: feature,
        requirement: requirement,
        child: child,
      );

  GoRoute featureRoute({
    required ItsmFeature feature,
    required String parameterName,
    required Widget Function(BuildContext context) screen,
    ItsmRouteRequirement requirement = ItsmRouteRequirement.automatic,
  }) =>
      GoRoute(
        path: feature.routeSegment,
        builder: (context, state) => guarded(
          feature,
          screen(context),
          requirement: requirement,
        ),
        routes: [
          GoRoute(
            path: ':$parameterName',
            builder: (context, state) => guarded(
              feature,
              screen(context),
              requirement: requirement,
            ),
          ),
        ],
      );

  return GoRoute(
    path: ItsmSection.securityCompliance.route
        .substring('${ItsmRoutes.root}/'.length),
    builder: (context, state) => const ItsmRouteGuard(
      section: ItsmSection.securityCompliance,
      child: ItsmSectionOverviewScreen(
        section: ItsmSection.securityCompliance,
      ),
    ),
    routes: [
      featureRoute(
        feature: ItsmFeature.securityFindings,
        parameterName: 'findingId',
        requirement: ItsmRouteRequirement.operational,
        screen: (context) => SecurityFindingsScreen(
          onBack: () => context.pop(),
        ),
      ),
      featureRoute(
        feature: ItsmFeature.securityExceptions,
        parameterName: 'exceptionId',
        screen: (context) => SecurityExceptionsScreen(
          onBack: () => context.pop(),
        ),
      ),
      featureRoute(
        feature: ItsmFeature.assetCompliance,
        parameterName: 'assessmentId',
        screen: (context) => AssetComplianceScreen(
          onBack: () => context.pop(),
        ),
      ),
      featureRoute(
        feature: ItsmFeature.accessReviews,
        parameterName: 'reviewItemId',
        screen: (context) => AccessReviewsScreen(
          onBack: () => context.pop(),
        ),
      ),
    ],
  );
}

GoRoute _buildCanonicalIncidentRoute() {
  return GoRoute(
    path: ItsmFeature.incidents.routeSegment,
    builder: (context, state) => const ItsmRouteGuard(
      section: ItsmSection.support,
      feature: ItsmFeature.incidents,
      requirement: ItsmRouteRequirement.selfService,
      child: IncidentRoleGateScreen(),
    ),
    routes: [
      GoRoute(
        path: 'dashboard',
        redirect: (context, state) => _replacePathPreservingParameters(
          state.location,
          ItsmRoutes.incidentReportingDashboard,
        ),
      ),
      GoRoute(
        path: 'create',
        builder: (context, state) => const ItsmRouteGuard(
          section: ItsmSection.support,
          feature: ItsmFeature.incidents,
          requirement: ItsmRouteRequirement.selfService,
          child: CreateIncidentScreen(),
        ),
      ),
      GoRoute(
        path: 'parameters',
        builder: (context, state) => const ItsmRouteGuard(
          section: ItsmSection.support,
          feature: ItsmFeature.incidents,
          requirement: ItsmRouteRequirement.operational,
          child: ManagerIncidentParametersScreen(),
        ),
      ),
      GoRoute(
        path: 'history',
        builder: (context, state) => const ItsmRouteGuard(
          section: ItsmSection.support,
          feature: ItsmFeature.incidents,
          requirement: ItsmRouteRequirement.operational,
          child: ManagerIncidentHistoryScreen(),
        ),
      ),
      GoRoute(
        path: 'queue/:queueKey',
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.support,
          feature: ItsmFeature.incidents,
          requirement: ItsmRouteRequirement.operational,
          child: ManagerIncidentQueueScreen(
            queueKey: state.pathParameters['queueKey'] as String,
          ),
        ),
      ),
      GoRoute(
        path: 'my/:ticketId',
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.support,
          feature: ItsmFeature.incidents,
          requirement: ItsmRouteRequirement.selfService,
          child: MyIncidentDetailsScreen(
            ticketId: state.pathParameters['ticketId'] as String,
          ),
        ),
      ),
      GoRoute(
        path: 'manager/:ticketId',
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.support,
          feature: ItsmFeature.incidents,
          requirement: ItsmRouteRequirement.operational,
          child: ManagerIncidentDetailsScreen(
            ticketId: state.pathParameters['ticketId'] as String,
          ),
        ),
      ),
      GoRoute(
        path: 'admin/:ticketId',
        builder: (context, state) => ItsmRouteGuard(
          section: ItsmSection.support,
          feature: ItsmFeature.incidents,
          requirement: ItsmRouteRequirement.selfService,
          child: MyIncidentDetailsScreen(
            ticketId: state.pathParameters['ticketId'] as String,
          ),
        ),
      ),
      // Preserve the two shapes provided by the former /service/ticketing
      // route while still converging on canonical incident destinations.
      GoRoute(
        path: 'add',
        redirect: (context, state) => _replacePathPreservingParameters(
          state.location,
          '${ItsmRoutes.incidents}/create',
        ),
      ),
      GoRoute(
        path: ':ticketId',
        redirect: (context, state) => _replacePathPreservingParameters(
          state.location,
          '${ItsmRoutes.incidents}/my/'
          '${state.pathParameters['ticketId'] as String}',
        ),
      ),
    ],
  );
}

String _replacePathPreservingParameters(String location, String path) {
  final uri = Uri.parse(location);
  return uri.replace(path: path).toString();
}

String _postAuthorizationRedirectLocation(GoRouterState state) {
  final from = state.queryParameters['from'];
  if (from == null || from.isEmpty || from == '/login') {
    return routerInitialLocation;
  }

  return from;
}

String _authorizationRoute(GoRouterState state, String route) {
  final requestedLocation = state.matchedLocation == '/login'
      ? state.queryParameters['from'] ?? routerInitialLocation
      : state.location;
  final from = Uri.encodeComponent(requestedLocation);
  return '$route?from=$from';
}

DateTime? _parseMeetingHallSelectedDate(String? rawDate) {
  final value = rawDate?.trim() ?? '';
  if (value.isEmpty) {
    return null;
  }

  final dateOnlyMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (dateOnlyMatch != null) {
    return DateTime(
      int.parse(dateOnlyMatch.group(1)!),
      int.parse(dateOnlyMatch.group(2)!),
      int.parse(dateOnlyMatch.group(3)!),
    );
  }

  return DateTime.tryParse(value);
}

String? _parseMeetingHallReservationId(Map<String, String> queryParameters) {
  final value =
      (queryParameters['reservationId'] ?? queryParameters['reservation'] ?? '')
          .trim();
  if (value.isEmpty) {
    return null;
  }
  return value;
}

String _meetingHallDateKey(DateTime? date) {
  if (date == null) {
    return 'today';
  }
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
