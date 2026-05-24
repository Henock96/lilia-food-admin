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
import 'package:lilia_admin/features/admin/presentation/screens/payments_screen.dart';
import 'package:lilia_admin/features/admin/presentation/screens/deliverers_screen.dart';
import 'package:lilia_admin/features/admin/presentation/screens/deliverer_detail_screen.dart';
import 'package:lilia_admin/features/admin/presentation/screens/quartiers_screen.dart';
import 'package:lilia_admin/features/admin/presentation/screens/platform_settings_screen.dart';
import 'package:lilia_admin/features/deliveries/presentation/screens/delivery_tracking_screen.dart';
import 'package:lilia_admin/features/incidents/presentation/screens/incidents_screen.dart';
import 'package:lilia_admin/features/incidents/presentation/screens/incident_detail_screen.dart';
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
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).authStateChanges(),
    ),
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
            const MaterialPage(child: SignInPage()),
      ),
      // ─── Routes plein écran (hors bottom nav) ──────────────────────────
      // Routes ADMIN-only — protégées via [_AdminOnlyGuard] qui redirige les
      // non-admins vers la racine.
      GoRoute(
        path: '/deliverers/:id',
        name: 'deliverer-detail',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage(
            child: _AdminOnlyGuard(
              child: DelivererDetailScreen(delivererId: id),
            ),
          );
        },
      ),
      GoRoute(
        path: '/incidents',
        name: 'incidents',
        pageBuilder: (context, state) => const MaterialPage(
          child: _AdminOnlyGuard(child: IncidentsScreen()),
        ),
        routes: [
          GoRoute(
            path: ':id',
            name: 'incident-detail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return MaterialPage(
                child: _AdminOnlyGuard(
                  child: IncidentDetailScreen(incidentId: id),
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/deliveries/:orderId/tracking',
        name: 'delivery-tracking',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return MaterialPage(
            child: _AdminOnlyGuard(
              child: DeliveryTrackingScreen(orderId: orderId),
            ),
          );
        },
      ),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/commandes',
                name: 'commandes',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: RestaurantOrdersScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'order-detail',
                    pageBuilder: (context, state) {
                      final extra = state.extra;
                      if (extra is! order_model.Order) {
                        return MaterialPage(
                          child: _MissingRouteDataScreen(
                            title: 'Commande indisponible',
                            message:
                                'Rechargez la liste des commandes puis ouvrez le détail à nouveau.',
                            backRouteName: 'commandes',
                          ),
                        );
                      }
                      return MaterialPage(
                        child: OrderDetailScreen(order: extra),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/clients',
                name: 'clients',
                pageBuilder: (context, state) {
                  return MaterialPage(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final userProfile = ref.watch(
                          currentUserProfileProvider,
                        );
                        final isAdmin = userProfile?.role == Role.admin;
                        if (isAdmin) {
                          return const ClientsScreen(restaurantId: '');
                        }
                        final restaurantId = ref.watch(
                          currentRestaurantIdProvider,
                        );
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
                      final extra = state.extra;
                      if (extra is! AppUser) {
                        return MaterialPage(
                          child: _MissingRouteDataScreen(
                            title: 'Client indisponible',
                            message:
                                'Rechargez la liste des clients puis ouvrez le détail à nouveau.',
                            backRouteName: 'clients',
                          ),
                        );
                      }
                      return MaterialPage(
                        child: ClientDetailScreen(client: extra),
                      );
                    },
                  ),
                ],
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
                  GoRoute(
                    path: 'paiements',
                    name: 'admin-payments',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: PaymentsScreen()),
                  ),
                  GoRoute(
                    path: 'livreurs',
                    name: 'admin-deliverers',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: DeliverersScreen()),
                  ),
                  GoRoute(
                    path: 'quartiers',
                    name: 'admin-quartiers',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: QuartiersScreen()),
                  ),
                  GoRoute(
                    path: 'parametres-plateforme',
                    name: 'platform-settings',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: PlatformSettingsScreen()),
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
              ),
              GoRoute(
                path: '/produits',
                name: 'produits',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: ProductsScreen()),
              ),
              GoRoute(
                path: '/categories',
                name: 'categories',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: CategoriesScreen()),
              ),
              GoRoute(
                path: '/menus',
                name: 'menus',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: MenusScreen()),
              ),
              GoRoute(
                path: '/banners',
                name: 'banners',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: BannersScreen()),
              ),
              GoRoute(
                path: '/create-restaurant',
                name: 'create-restaurant',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: CreateRestaurantScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Garde les routes admin-only : si l'utilisateur courant n'a pas le rôle
/// [Role.admin], on bascule sur un écran d'erreur 403 plutôt que de rendre
/// l'écran cible. Tant que le profil est en cours de chargement on affiche
/// un loader (évite les flashs vers 403 pendant le hot-reload / cold start).
class _AdminOnlyGuard extends ConsumerWidget {
  const _AdminOnlyGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);
    if (userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userProfile.role != Role.admin) {
      return _MissingRouteDataScreen(
        title: 'Accès refusé',
        message: 'Cette page est réservée aux administrateurs.',
        backRouteName: 'dashboard',
      );
    }
    return child;
  }
}

class _MissingRouteDataScreen extends StatelessWidget {
  const _MissingRouteDataScreen({
    required this.title,
    required this.message,
    required this.backRouteName,
  });

  final String title;
  final String message;
  final String backRouteName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.goNamed(backRouteName),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
