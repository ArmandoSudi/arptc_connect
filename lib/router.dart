import 'dart:developer';

import 'package:arptc_connect/core/shared_preferences_provider.dart';
import 'package:arptc_connect/modules/administration/presentation/screens/add_agent_screen.dart';
import 'package:arptc_connect/modules/administration/presentation/screens/add_direction_screen.dart';
import 'package:arptc_connect/modules/administration/presentation/screens/add_user_screen.dart';
import 'package:arptc_connect/modules/administration/presentation/screens/administration_screen.dart';
import 'package:arptc_connect/modules/administration/presentation/screens/agents_screen.dart';
import 'package:arptc_connect/modules/administration/presentation/screens/bureaux_screen.dart';
import 'package:arptc_connect/modules/administration/presentation/screens/direction_details_screen.dart';
import 'package:arptc_connect/modules/administration/presentation/screens/directions_screen.dart';
import 'package:arptc_connect/modules/administration/presentation/screens/services_screen.dart';
import 'package:arptc_connect/modules/administration/presentation/screens/users_screen.dart';
import 'package:arptc_connect/modules/authentication/screens/login_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/add_annotation_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/add_courrier_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/details_courrier.dart';
import 'package:arptc_connect/modules/courrier/screens/list_courriers_screen.dart';
import 'package:arptc_connect/modules/dashboard/presentation/screens/main_dashboard_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/appro_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/inventory_main_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/livraison_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/product/manage_items_screen.dart';
import 'package:arptc_connect/modules/service/screens/main_service_screen.dart';
import 'package:arptc_connect/modules/social/screens/main_social_screen.dart';
import 'package:arptc_connect/modules/task/presentation/screens/tasks_screen.dart';
import 'package:arptc_connect/modules/ticketing/presentation/screens/add_ticket_screen.dart';
import 'package:arptc_connect/modules/ticketing/presentation/screens/ticket_details_screen.dart';
import 'package:arptc_connect/modules/ticketing/presentation/screens/tickets_screen.dart';
import 'package:arptc_connect/screens/navigators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'modules/administration/presentation/screens/add_bureau_screen.dart';
import 'modules/administration/presentation/screens/add_service_screen.dart';
import 'modules/authentication/providers/authentication_provider.dart';
import 'modules/dashboard/screens/dashboard_page.dart';
import 'modules/inventory/presentation/cart/cart_screen.dart';

const routerInitialLocation = '/dashboard';

final goRouterProvider = Provider<GoRouter>((ref) {

  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorLoginKey = GlobalKey<NavigatorState>(debugLabel: 'shellLogin');
  final shellNavigatorErrorKey = GlobalKey<NavigatorState>(debugLabel: 'shellError');
  final shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
  final shellNavigatorAdministrationKey = GlobalKey<NavigatorState>(debugLabel: 'shellAdministration');
  final shellNavigatorServiceKey = GlobalKey<NavigatorState>(debugLabel: 'shellService');
  final shellNavigatorCourrierKey = GlobalKey<NavigatorState>(debugLabel: 'shellCourrier');
  final shellNavigatorTicketingKey = GlobalKey<NavigatorState>(debugLabel: 'shellTicketing');

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
          return ScaffoldWithNestedNavigation(
              navigationShell: navigationShell);
        },
        branches: [
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
              ]
          ),

          // Service branch
          StatefulShellBranch(
            navigatorKey: shellNavigatorServiceKey,
              routes: [
                // Service
                GoRoute(
                  path: '/service',
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: MainServiceScreen(),
                  ),
                  routes: [
                    // Social
                    GoRoute(
                      path: 'social',
                      builder: (context, state) => const MainSocialScreen(),
                    ),

                    // Inventory
                    GoRoute(
                      path: 'inventory',
                      pageBuilder: (context, state) =>  NoTransitionPage(
                        child: InventoryMainScreen(),
                      ),
                      routes: [

                        // Management
                        GoRoute(
                          path: 'management',
                          builder: (context, state) => ManageItemScreen(),
                        ),

                        // Approvisionnement
                        GoRoute(
                          path: 'appro',
                          builder: (context, state) => ApproScreen(),
                        ),

                        // Livraison
                        GoRoute(
                          path: 'livraison',
                          builder: (context, state) => LivraisonScreen(),
                        ),

                        GoRoute(
                          path: 'cart',
                          builder: (context, state) => CartScreen(),
                        ),
                      ],
                    ),

                    // Ticketing
                    GoRoute(
                      path: 'ticketing',
                      builder: (context, state)
                        => const TicketsScreen(),
                      routes: [
                        GoRoute(
                          path: 'add',
                          builder: (context, state)
                            => AddTicketScreen(),
                        ),
                        GoRoute(
                          path: ':ticketId',
                          builder: (context, state)
                            => TicketDetailsScreen(
                                ticketId: state.pathParameters['ticketId'] as String),
                        ),
                      ]
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
                          builder: (context, state) => DetailsCourrierScreen(state.pathParameters['courrierId'] as String),
                        ),
                        GoRoute(
                          path: 'enregistrer',
                          builder: (context, state) => const AddCourrierScreen(),
                        ),GoRoute(
                          path: ':courrierId/annotations/enregistrer',
                          builder: (context, state) =>
                              AddAnnotationScreen(courrierId: state.pathParameters['courrierId'] as String),
                        ),
                      ],
                    ),

                    // Tasks
                    GoRoute(
                      path: 'tasks',
                      pageBuilder: (context, state) => const NoTransitionPage(
                        child: TasksScreen(),
                      ),
                      // routes: [
                      //   GoRoute(
                      //     path: ':courrierId',
                      //     builder: (context, state) => DetailsCourrierScreen(state.pathParameters['courrierId'] as String),
                      //   ),
                      //   GoRoute(
                      //     path: 'enregistrer',
                      //     builder: (context, state) => const AddCourrierScreen(),
                      //   ),GoRoute(
                      //     path: ':courrierId/annotations/enregistrer',
                      //     builder: (context, state) =>
                      //         AddAnnotationScreen(courrierId: state.pathParameters['courrierId'] as String),
                      //   ),
                      // ],
                    ),

                  ],
                ),
              ]
          ),

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
                    builder: (context, state) => DetailsCourrierScreen(state.pathParameters['courrierId'] as String),
                  ),
                  GoRoute(
                    path: 'enregistrer',
                    builder: (context, state) => const AddCourrierScreen(),
                  ),GoRoute(
                    path: ':courrierId/annotations/enregistrer',
                    builder: (context, state) =>
                        AddAnnotationScreen(courrierId: state.pathParameters['courrierId'] as String),
                  ),
                ],
              ),
            ],
          ),

          // Administration branch
          StatefulShellBranch(
            navigatorKey: shellNavigatorAdministrationKey,
            routes: [
              // Administration
              GoRoute(
                path: '/administration',
                pageBuilder: (context, state) =>
                    NoTransitionPage(
                  child: AdministrationScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'directions',
                    builder: (context, state) =>
                        DirectionsScreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        pageBuilder: (context, state) =>
                        const MaterialPage(
                          fullscreenDialog: true,
                          child: AddDirectionScreen(),
                        )
                      ),
                      GoRoute(
                        path: ':directionId',
                        pageBuilder: (context, state) =>
                        MaterialPage(
                          fullscreenDialog: true,
                          child: DirectionDetailsScreen(directionId: state.pathParameters['directionId'] as String),
                        )
                      ),
                    ]
                  ),
                  GoRoute(
                    path: 'services',
                    builder: (context, state) => ServicesScreen(),
                    routes: [
                      GoRoute(
                          path: 'add',
                          pageBuilder: (context, state) => const MaterialPage(
                            fullscreenDialog: true,
                            child: AddServiceScreen(),
                          )
                      )
                    ]
                  ),
                  GoRoute(
                    path: 'bureaux',
                    builder: (context, state) => BureauxScreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        pageBuilder: (context, state) => const MaterialPage(
                          fullscreenDialog: true,
                          child: AddBureauScreen(),
                        ),
                      ),
                    ]
                  ),
                  GoRoute(
                    path: 'agents',
                    builder: (context, state) => UsersSreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        pageBuilder: (context, state) => const MaterialPage(
                          fullscreenDialog: true,
                          child: AddUserScreen(),
                        ),
                      ),
                    ]
                  ),
                ],
              ),
            ],
          ),

        ],
      )
    ],
    redirect: (context, state)  {

      final _authState = ref.watch(authStateProvider);

      // log("1. REDIRECTING TO DASHBOARD SCREEN");

      return _authState.when(
          data: (data) async {
            User? user = data;

            // if (user == null && state.location == '/'){
            if (user == null ){
              debugPrint(":: GO TO LOGIN SCREEN");
              return '/login';
            }

            var email = user.email;
            await  ref.read(authServiceProvider).getUser(email!);
            await ref.read(authServiceProvider).saveAgent(email);
            // await ref.read(sharedPrefUtilityProvider).setRoles(roles)

          },
          loading: () => '/login',
          error: (e, trace) => '/error');

    },
  );
}
);
