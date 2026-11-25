import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/constants/app_constants.dart';
import 'package:lilia_admin/features/premium/presentation/premium_upsell.dart';

void main() {
  test('l’app renvoie vers l’espace Premium du web, jamais vers un prix', () {
    final uri = premiumWebUri();
    expect(uri.toString(), '${AppConstants.adminWebUrl}/premium');
    expect(uri.scheme, 'https');
  });

  testWidgets(
    'carte des statistiques réservées : texte et bouton de souscription',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PremiumStatsUpsellCard()),
          ),
        ),
      );

      expect(find.text('Statistiques avancées'), findsOneWidget);
      expect(find.byKey(const Key('premium-subscribe-web')), findsOneWidget);
      // Aucun montant écrit en dur : le prix vient du serveur, sur le web.
      expect(find.textContaining('FCFA'), findsNothing);
    },
  );

  testWidgets(
    'navigateur indisponible : l’adresse est affichée, rien n’est avalé',
    (tester) async {
      Uri? asked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openPremiumWeb(
                  context,
                  launcher: (uri) async {
                    asked = uri;
                    return false; // le système refuse d'ouvrir
                  },
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      expect(asked, premiumWebUri());
      expect(find.textContaining('/premium'), findsOneWidget);
    },
  );
}
