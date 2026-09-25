import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/auth/controller/pending_mfa_sign_in.dart';
import 'package:lilia_admin/features/auth/presentation/signin_page.dart';

/// F3-08 — un administrateur inscrit à la double authentification (depuis
/// l'admin web) doit pouvoir se connecter à l'app : Firebase interrompt la
/// connexion et attend le code de son application.
void main() {
  test('un code d’application compte 6 chiffres', () {
    expect(isTotpCode('123456'), isTrue);
    for (final bad in ['12345', '1234567', 'abcdef', ' 12345']) {
      expect(isTotpCode(bad), isFalse, reason: bad);
    }
  });

  group('TotpCodeDialog', () {
    Future<List<String?>> open(WidgetTester tester) async {
      final results = <String?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => results.add(
                  await showDialog<String>(
                    context: context,
                    builder: (_) => const TotpCodeDialog(),
                  ),
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('« Valider » attend 6 chiffres, puis rend le code', (tester) async {
      final results = await open(tester);
      final submit = find.byKey(const Key('totp-submit'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);

      await tester.enterText(find.byKey(const Key('totp-code')), '12345');
      await tester.pump();
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);

      await tester.enterText(find.byKey(const Key('totp-code')), '123456');
      await tester.pump();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(results, ['123456']);
    });

    testWidgets('« Annuler » ne rend rien', (tester) async {
      final results = await open(tester);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(results, [null]);
    });
  });
}
