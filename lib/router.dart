import 'dart:async';

import 'package:arptc_connect/modules/authentication/screens/login_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/add_annotation_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/add_courrier_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/details_courrier.dart';
import 'package:arptc_connect/modules/courrier/screens/list_courriers_screen.dart';
import 'package:arptc_connect/modules/dashboard/presentation/screens/main_dashboard_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/create_incident_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/incident_dashboard_router.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/incident_role_gate_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/manager_incident_details_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/manager_incident_parameters_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/manager_incident_queue_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/my_incident_details_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/appro_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/inventory_main_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/livraison_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/product/manage_items_screen.dart';
import 'package:arptc_connect/modules/news/presentation/screens/news_editor_screen.dart';
import 'package:arptc_connect/modules/news/presentation/screens/news_module_screen.dart';
import 'package:arptc_connect/modules/news/presentation/screens/news_post_details_screen.dart';
import 'package:arptc_connect/modules/news/presentation/screens/news_review_screen.dart';
import 'package:arptc_connect/modules/notifications/presentation/screens/notifications_inbox_screen.dart';
import 'package:arptc_connect/modules/profile/presentation/screens/profile_screen.dart';
import 'package:arptc_connect/modules/service/screens/main_service_screen.dart';
import 'package:arptc_connect/modules/social/screens/social_agents_page.dart';
import 'package:arptc_connect/modules/task/presentation/screens/task_details_page.dart';
import 'package:arptc_connect/modules/task/presentation/screens/tasks_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/agents_list_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/bureau_details_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/bureaux_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/department_details_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/departments_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/module_details_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/modules_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/service_details_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/services_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/agent_details_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/user_management_main_screen.dart';
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

                // Incident Management
                GoRoute(
                  path: 'incidents',
                  builder: (context, state) => const IncidentRoleGateScreen(),
                  routes: [
                    GoRoute(
                      path: 'dashboard',
                      builder: (context, state) =>
                          const IncidentDashboardRouter(),
                    ),
                    GoRoute(
                      path: 'create',
                      builder: (context, state) => const CreateIncidentScreen(),
                    ),
                    GoRoute(
                      path: 'parameters',
                      builder: (context, state) =>
                          const ManagerIncidentParametersScreen(),
                    ),
                    GoRoute(
                      path: 'queue/:queueKey',
                      builder: (context, state) => ManagerIncidentQueueScreen(
                        queueKey: state.pathParameters['queueKey'] as String,
                      ),
                    ),
                    GoRoute(
                      path: 'my/:ticketId',
                      builder: (context, state) => MyIncidentDetailsScreen(
                        ticketId: state.pathParameters['ticketId'] as String,
                      ),
                    ),
                    GoRoute(
                      path: 'manager/:ticketId',
                      builder: (context, state) => ManagerIncidentDetailsScreen(
                        ticketId: state.pathParameters['ticketId'] as String,
                      ),
                    ),
                    GoRoute(
                      path: 'admin/:ticketId',
                      builder: (context, state) => MyIncidentDetailsScreen(
                        ticketId: state.pathParameters['ticketId'] as String,
                        showInternalNotes: true,
                      ),
                    ),
                  ],
                ),

                // Legacy Ticketing route kept as a compatibility alias.
                GoRoute(
                  path: 'ticketing',
                  builder: (context, state) => const IncidentRoleGateScreen(),
                  routes: [
                    GoRoute(
                      path: 'add',
                      builder: (context, state) => const CreateIncidentScreen(),
                    ),
                    GoRoute(
                      path: ':ticketId',
                      builder: (context, state) => MyIncidentDetailsScreen(
                        ticketId: state.pathParameters['ticketId'] as String,
                      ),
                    ),
                  ],
                ),

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
                      path: ':taskId',
                      builder: (context, state) => TaskDetailsPage(
                          state.pathParameters['taskId'] as String),
                    ),
                  ],
                ),

                // Meeting Halls
                GoRoute(
                  path: 'meetinghall',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: MeetingHallsScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (context, state) {
                        final hallId = state.pathParameters['id']!;
                        // return HallDetailsScreen(
                        //   hall: ref.read(meetingHallsProvider)
                        //       .firstWhere((hall) => hall.id == hallId),
                        // );
                        return HallDetailsScreen(hallId: hallId);
                      },
                    ),
                  ],
                ),

                // User Management
                GoRoute(
                  path: 'usermanagement',
                  pageBuilder: (context, state) => const MaterialPage(
                    child: UserManagementMainScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: 'departments',
                      builder: (context, state) => const DepartmentsScreen(),
                      routes: [
                        GoRoute(
                          path: ':departmentId',
                          pageBuilder: (context, state) => MaterialPage(
                              fullscreenDialog: true,
                              child: DepartmentDetailsScreen(
                                departmentId: state
                                    .pathParameters['departmentId'] as String,
                              )),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'services',
                      builder: (context, state) =>
                          const ServicesManagementScreen(),
                      routes: [
                        GoRoute(
                          path: ':serviceId',
                          builder: (context, state) => ServiceDetailsScreen(
                            serviceId:
                                state.pathParameters['serviceId'] as String,
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'bureaux',
                      builder: (context, state) =>
                          const BureauxManagementScreen(),
                      routes: [
                        GoRoute(
                          path: ':bureauId',
                          builder: (context, state) => BureauDetailsScreen(
                            bureauId:
                                state.pathParameters['bureauId'] as String,
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'agents',
                      builder: (context, state) =>
                          const AgentsManagementScreen(),
                      routes: [
                        GoRoute(
                          path: 'add',
                          pageBuilder: (context, state) => const MaterialPage(
                            fullscreenDialog: true,
                            child: AddAgentSheet(),
                          ),
                        ),
                        GoRoute(
                          path: ':agentId',
                          pageBuilder: (context, state) => MaterialPage(
                            fullscreenDialog: true,
                            child: AgentDetailsScreen(
                              agentId:
                                  state.pathParameters['agentId'] as String,
                            ),
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'modules',
                      builder: (context, state) =>
                          const ModulesManagementScreen(),
                      routes: [
                        GoRoute(
                          path: ':moduleId',
                          builder: (context, state) => ModuleDetailsScreen(
                            moduleId:
                                state.pathParameters['moduleId'] as String,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
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

      // log("1. REDIRECTING TO DASHBOARD SCREEN");

      return authState.when(
          data: (data) {
            User? user = data;
            final isLoginRoute = state.matchedLocation == '/login';

            // if (user == null && state.location == '/'){
            if (user == null) {
              if (isLoginRoute) {
                return null;
              }
              debugPrint(":: GO TO LOGIN SCREEN");
              final from = Uri.encodeComponent(state.location);
              return '/login?from=$from';
            }

            final email = user.email;
            if (email != null && email.isNotEmpty) {
              unawaited(
                ref.read(authServiceProvider).warmLocalSessionIfNeeded(email),
              );
            }

            if (isLoginRoute) {
              return _postLoginRedirectLocation(state);
            }

            return null;
          },
          loading: () => null,
          error: (e, trace) =>
              state.matchedLocation == '/error' ? null : '/error');
    },
  );
});

String _postLoginRedirectLocation(GoRouterState state) {
  final from = state.queryParameters['from'];
  if (from == null || from.isEmpty || from == '/login') {
    return routerInitialLocation;
  }

  return from;
}
