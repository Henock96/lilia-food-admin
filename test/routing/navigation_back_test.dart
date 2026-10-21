import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lilia_admin/features/auth/app_user_model.dart';
import 'package:lilia_admin/features/auth/user_sync_provider.dart';
import 'package:lilia_admin/features/home/presentation/bottom_navigation_bar.dart';
import 'package:lilia_admin/models/role.dart';

/// Retour dans l'app vendeurs : bouton de l'AppBar et bouton retour Android.
///
/// Le routeur ci-dessous reprend la forme de `app_router.dart` (onglets en
/// `StatefulShellRoute`, écrans de gestion déclarés à côté de `/profile`,
/// `/incidents` hors des onglets) avec des écrans factices et la vraie
/// `BottomNavigationPage`.
class _AdminProfile extends CurrentUserProfile {
  @override
  AppUser? build() => const AppUser(
    uid: 'fb-admin',
    id: 'admin',
    email: 'admin@lilia.cg',
    role: Role.admin,
  );
}

class _Page extends StatelessWidget {
  const _Page(this.title, {this.links = const {}});

  final String title;

  /// Libellé du bouton → nom de route ouverte par `pushNamed`.
  final Map<String, String> links;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          for (final e in links.entries)
            TextButton(
              onPressed: () => context.pushNamed(e.value),
              child: Text(e.key),
            ),
        ],
      ),
    );
  }
}

GoRoute _route(String path, String name, {Map<String, String> links = const {}, List<RouteBase> routes = const []}) =>
    GoRoute(
      path: path,
      name: name,
      routes: routes,
      pageBuilder: (context, state) =>
          MaterialPage(child: _Page(name, links: links)),
    );

GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    _route('/incidents', 'incidents'),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          BottomNavigationPage(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [_route('/', 'dashboard')]),
        StatefulShellBranch(
          routes: [
            _route(
              '/commandes',
              'commandes',
              links: {'ouvrir commande': 'order-detail'},
              routes: [_route('detail', 'order-detail')],
            ),
          ],
        ),
        StatefulShellBranch(routes: [_route('/clients', 'clients')]),
        StatefulShellBranch(
          routes: [
            _route('/settings', 'settings', links: {'ouvrir incidents': 'incidents'}),
          ],
        ),
        StatefulShellBranch(
          routes: [
            _route('/profile', 'profile', links: {'ouvrir produits': 'produits'}),
            _route('/produits', 'produits', links: {'ouvrir categories': 'categories'}),
            _route('/categories', 'categories'),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  late List<String> platformCalls;

  setUp(() {
    platformCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call.method);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final router = _router();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProfileProvider.overrideWith(_AdminProfile.new)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> androidBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  bool exited() => platformCalls.contains('SystemNavigator.pop');

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('Profil → Produits → Catégories : flèche retour, puis retour Android jusqu\'au Profil', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'Profil');

    await tester.tap(find.text('ouvrir produits'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'produits'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('ouvrir categories'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);

    await androidBack(tester);
    expect(find.widgetWithText(AppBar, 'produits'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'profile'), findsOneWidget);
    expect(exited(), isFalse);
  });

  testWidgets('Réglages → Incidents (hors onglets) : le retour Android revient aux Réglages', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'Admin');

    await tester.tap(find.text('ouvrir incidents'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'incidents'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await androidBack(tester);
    expect(find.widgetWithText(AppBar, 'settings'), findsOneWidget);
    expect(exited(), isFalse);
  });

  testWidgets('retour Android sur un autre onglet : revient à Stats sans quitter l\'app', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'Clients');

    await androidBack(tester);
    expect(find.widgetWithText(AppBar, 'dashboard'), findsOneWidget);
    expect(exited(), isFalse);
  });

  testWidgets('retour Android sur une fiche : dépile la fiche avant de changer d\'onglet', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'Commandes');
    await tester.tap(find.text('ouvrir commande'));
    await tester.pumpAndSettle();

    await androidBack(tester);
    expect(find.widgetWithText(AppBar, 'commandes'), findsOneWidget);

    await androidBack(tester);
    expect(find.widgetWithText(AppBar, 'dashboard'), findsOneWidget);
    expect(exited(), isFalse);
  });

  testWidgets('retour Android sur Stats : quitte l\'app', (tester) async {
    await pumpApp(tester);

    await androidBack(tester);
    expect(exited(), isTrue);
  });

  // Garde-fou sur les vrais écrans : ces destinations ne sont pas des
  // enfants de la route qui les ouvre. `goNamed` y remplacerait la pile
  // (aucun retour, et le retour Android quitterait l'app).
  test('les écrans de gestion s\'ouvrent par pushNamed, jamais par goNamed', () {
    const sites = {
      'lib/features/users/user_screen.dart': [
        'menus', 'produits', 'categories', 'options', 'banners', 'create-restaurant',
      ],
      'lib/features/products/presentation/screens/products_screen.dart': [
        'categories', 'options',
      ],
      'lib/features/settings/presentation/screens/settings_screen.dart': [
        'incidents',
      ],
    };
    for (final entry in sites.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final name in entry.value) {
        expect(source, isNot(contains("goNamed('$name')")), reason: '${entry.key} : $name');
        expect(source, contains("pushNamed('$name')"), reason: '${entry.key} : $name');
      }
    }
  });
}
