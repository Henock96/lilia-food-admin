import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lilia_admin/features/auth/app_user_model.dart';
import 'package:lilia_admin/features/auth/user_sync_provider.dart';
import 'package:lilia_admin/features/home/presentation/bottom_navigation_bar.dart';
import 'package:lilia_admin/models/role.dart';

/// Lot C (15/11/2026, D2) — le vendeur ne connaît pas ses clients : pas
/// d'onglet « Clients ». Les autres onglets mènent toujours à leur branche,
/// malgré le décalage d'index entre onglets affichés et branches du shell.
class _Profile extends CurrentUserProfile {
  _Profile(this.role);
  final Role role;

  @override
  AppUser? build() =>
      AppUser(uid: 'fb-u', id: 'u', email: 'u@lilia.cg', role: role);
}

GoRoute _route(String path, String name) => GoRoute(
  path: path,
  name: name,
  pageBuilder: (context, state) =>
      MaterialPage(child: Scaffold(body: Text('page:$name'))),
);

GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          BottomNavigationPage(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [_route('/', 'dashboard')]),
        StatefulShellBranch(routes: [_route('/commandes', 'commandes')]),
        StatefulShellBranch(routes: [_route('/clients', 'clients')]),
        StatefulShellBranch(routes: [_route('/settings', 'settings')]),
        StatefulShellBranch(routes: [_route('/profile', 'profile')]),
      ],
    ),
  ],
);

Future<void> _pump(WidgetTester tester, Role role) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWith(() => _Profile(role)),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('vendeur : quatre onglets, aucun « Clients »', (tester) async {
    await _pump(tester, Role.restaurateur);

    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Clients'), findsNothing);
  });

  testWidgets('vendeur : chaque onglet ouvre sa branche', (tester) async {
    await _pump(tester, Role.restaurateur);

    await _tap(tester, 'Commandes');
    expect(find.text('page:commandes'), findsOneWidget);

    await _tap(tester, 'Paramètres');
    expect(find.text('page:settings'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await _tap(tester, 'Profil');
    expect(find.text('page:profile'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
  });

  testWidgets('admin : l’onglet « Clients » reste', (tester) async {
    await _pump(tester, Role.admin);

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    await _tap(tester, 'Clients');
    expect(find.text('page:clients'), findsOneWidget);
  });
}
