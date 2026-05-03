import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lilia_admin/features/auth/presentation/signin_page.dart';
import 'package:lilia_admin/features/clients/presentation/screens/client_detail_screen.dart';
import 'package:lilia_admin/features/clients/presentation/screens/clients_screen.dart';
import 'package:lilia_admin/features/home/presentation/screens/restaurant_orders_screen.dart';
import 'package:lilia_admin/features/home/presentation/screens/order_detail_screen.dart';
import 'package:lilia_admin/models/order.dart' as order_model;
import 'package:lilia_admin/features/home/presentation/bottom_navigation_bar.dart';
import 'package:lilia_admin/features/products/presentation/screens/products_screen.dart';
import 'package:lilia_admin/features/categories/presentation/screens/categories_screen.dart';
import 'package:lilia_admin/features/menus/presentation/screens/menus_screen.dart';
import 'package:lilia_admin/features/banners/presentation/screens/banners_screen.dart';
import 'package:lilia_admin/features/admin/presentation/screens/create_restaurant_screen.dart';
import 'package:lilia_admin/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:lilia_admin/features/settings/presentation/screens/settings_screen.dart';
import 'package:lilia_admin/features/zones/presentation/screens/zones_screen.dart';
import 'package:lilia_admin/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:lilia_admin/features/auth/user_sync_provider.dart';
import 'package:lilia_admin/models/role.dart';
import 'package:lilia_admin/models/app_user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/auth/repository/firebase_auth_repository.dart';
import '../features/users/user_screen.dart';
import 'go_router_refresh_stream.dart';

part 'app_router.g.dart';

final _key = GlobalKey<NavigatorState>();

@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authStateChangeProvider);

  return GoRouter(
    navigatorKey: _key,
    initialLocation: '/sign-in',
    refreshListenable:
        GoRouterRefreshStream(ref.watch(authRepositoryProvider).authStateChanges()),
    redirect: (context, state) {
      final bool isLoggedIn = authState.when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, _) => false,
      );

      final bool isLoggingIn = state.matchedLocation == '/sign-in';

      if (!isLoggedIn && !isLoggingIn) {
        return '/sign-in';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
          path: '/sign-in',
          name: 'sign-in',
          pageBuilder: (context, state) =>
              const MaterialPage(child: SignInPage())),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavigationPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'dashboard',
                pageBuilder: (context, state) =>
                const MaterialPage(child: DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/commandes',
                name: 'commandes',
                pageBuilder: (context, state) => const MaterialPage(
                    child: RestaurantOrdersScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'order-detail',
                    pageBuilder: (context, state) {
                      final order = state.extra as order_model.Order;
                      return MaterialPage(
                        child: OrderDetailScreen(order: order),
                      );
                    },
                  ),
                ]),
          ]),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/clients',
                name: 'clients',
                pageBuilder: (context, state) {
                  return MaterialPage(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final userProfile = ref.watch(currentUserProfileProvider);
                        final isAdmin = userProfile?.role == Role.admin;
                        if (isAdmin) {
                          return const ClientsScreen(restaurantId: '');
                        }
                        final restaurantId = ref.watch(currentRestaurantIdProvider);
                        return ClientsScreen(restaurantId: restaurantId);
                      },
                    ),
                  );
                },
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'client-detail',
                    pageBuilder: (context, state) {
                      final client = state.extra as AppUser;
                      return MaterialPage(
                        child: ClientDetailScreen(client: client),
                      );
                    },
                  ),
                ]
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                pageBuilder: (context, state) =>
                const MaterialPage(child: SettingsScreen()),
                routes: [
                  GoRoute(
                    path: 'zones',
                    name: 'delivery-zones',
                    pageBuilder: (context, state) =>
                    const MaterialPage(child: ZonesScreen()),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(

            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) =>
                const MaterialPage(child: UserPage()),
                routes: [
                  GoRoute(
                    path: '/produits',
                    name: 'produits',
                    pageBuilder: (context, state) => const MaterialPage(
                        child: ProductsScreen()),
                  ),
                  GoRoute(
                      path: '/categories',
                      name: 'categories',
                      pageBuilder: (context, state) => const MaterialPage(
                          child: CategoriesScreen()),),
                  GoRoute(
                      path: '/menus',
                      name: 'menus',
                      pageBuilder: (context, state) => const MaterialPage(
                          child: MenusScreen()),),
                  GoRoute(
                      path: '/banners',
                      name: 'banners',
                      pageBuilder: (context, state) => const MaterialPage(
                          child: BannersScreen()),),
                  GoRoute(
                      path: '/create-restaurant',
                      name: 'create-restaurant',
                      pageBuilder: (context, state) => const MaterialPage(
                          child: CreateRestaurantScreen()),),
                ]
              ),

            ],
          ),
        ],
      ),
    ],
  );
}
