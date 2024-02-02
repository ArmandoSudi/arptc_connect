import 'package:arptc_connect/modules/administration/screens/add_agent_screen.dart';
import 'package:arptc_connect/modules/administration/screens/add_direction_screen.dart';
import 'package:arptc_connect/modules/administration/screens/administration_screen.dart';
import 'package:arptc_connect/modules/administration/screens/agents_screen.dart';
import 'package:arptc_connect/modules/administration/screens/bureaux_screen.dart';
import 'package:arptc_connect/modules/administration/screens/directions_screen.dart';
import 'package:arptc_connect/modules/administration/screens/services_screen.dart';
import 'package:arptc_connect/modules/authentication/screens/login_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/add_annotation_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/add_courrier_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/details_courrier.dart';
import 'package:arptc_connect/modules/courrier/screens/list_courriers_screen.dart';
import 'package:arptc_connect/modules/dashboard/screens/main_dashboard_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/manage_items_screen.dart';
import 'package:arptc_connect/modules/service/screens/main_service_screen.dart';
import 'package:arptc_connect/modules/social/screens/main_social_screen.dart';
import 'package:arptc_connect/screens/navigators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'modules/administration/screens/add_bureau_screen.dart';
import 'modules/administration/screens/add_service_screen.dart';
import 'modules/authentication/providers/authentication_provider.dart';
import 'modules/dashboard/screens/dashboard_page.dart';
import 'modules/inventory/presentation/cart_screen.dart';

const routerInitialLocation = '/dashboard';

final goRouterProvider = Provider<GoRouter>((ref) {

  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorLoginKey = GlobalKey<NavigatorState>(debugLabel: 'shellLogin');
  final shellNavigatorErrorKey = GlobalKey<NavigatorState>(debugLabel: 'shellError');
  final shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
  final shellNavigatorServiceKey = GlobalKey<NavigatorState>(debugLabel: 'shellService');
  final shellNavigatorCourrierKey = GlobalKey<NavigatorState>(debugLabel: 'shellCourrier');
  final _shellNavigatorBKey = GlobalKey<NavigatorState>(debugLabel: 'shellB');

  return GoRouter(
    initialLocation: routerInitialLocation,
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: true,
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
                GoRoute(
                  path: '/service',
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: MainServiceScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: 'social',
                      builder: (context, state) => const MainSocialScreen(),
                    ),
                    GoRoute(
                      path: 'inventory',
                      pageBuilder: (context, state) => const NoTransitionPage(
                        child: ManageItemScreen(),
                      ),
                      routes: [
                        GoRoute(
                          path: 'cart',
                          builder: (context, state) => CartScreen(),
                        ),
                      ],
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
                    builder: (context, state) => AddAnnotationScreen(courrierId: state.pathParameters['courrierId'] as String),
                  ),
                ],
              ),
            ],
          ),

          // Administration branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBKey,
            routes: [
              // Administration
              GoRoute(
                path: '/administration',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: AdministrationScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'directions',
                    builder: (context, state) => DirectionsScreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        pageBuilder: (context, state) => const MaterialPage(
                          fullscreenDialog: true,
                          child: AddDirectionScreen(),
                        )
                      )
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
                    builder: (context, state) => AgentsScreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        pageBuilder: (context, state) => const MaterialPage(
                          fullscreenDialog: true,
                          child: AddAgentScreen(),
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

      return _authState.when(
          data: (data) {
            User? user = data;

            // if (user == null && state.location == '/'){
            if (user == null ){
              debugPrint(":: GO TO LOGIN SCREEN");
              return '/login';
            }
            // debugPrint(":: RETURNING LOGIN");
            // return '/login';
          },
          loading: () => '/login',
          error: (e, trace) => '/error');

    },
  );
}
);

final goRouterProviderTwo = Provider<GoRouter>((ref){
  return router(ref);
});

GoRouter router(ProviderRef ref) {

final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorCourrierKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellCourrier');
  final shellNavigatorDashboardKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
  final shellNavigatorErrorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellError');
  final shellNavigatorLoginKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellLogin');

  return GoRouter(
    initialLocation: '/courriers',
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: DashboardPage(),
        ),
      ),
      GoRoute(
        path: '/courriers',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ListCourriersScreen(),
        ),
        // routes: [
        //   GoRoute(
        //     path: 'details/:courrierId',
        //     pageBuilder: (context, state) {
        //
        //       return NoTransitionPage(
        //           child: DetailsCourrierScreen(state.pathParameters['courrierId'] as String));
        //     },
        //   ),
        // ],
      ),
      GoRoute(
        path: '/courriers/:courrierId',
        pageBuilder: (context, state) {

          return NoTransitionPage(
              child: DetailsCourrierScreen(state.pathParameters['courrierId'] as String));
        },
      ),
      GoRoute(
        path: '/error',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: Center(
            child: Text('Error'),
          ),
        ),
      )
    ],
    redirect: (context, state) async {

      final _authState = ref.watch(authStateProvider);

      return _authState.when(
          data: (data) {
            User? user = data;

            // if (user == null && state.location == '/'){
            if (user == null ){
              debugPrint(":: GO TO LOGIN SCREEN");
              return '/login';
            }
            // debugPrint(":: RETURNING LOGIN");
            // return '/login';
          },
          loading: () => '/login',
          error: (e, trace) => '/error');

    },
  );
}