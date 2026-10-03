// Phase 3.7 — `Colors.white` codé en dur dans l'admin : ce qui reste blanc
// doit l'être sur un fond qui le porte (AA, 4,5:1), et un indicateur de
// chargement doit rester visible sur le fond d'un bouton désactivé.
//
// Couleurs lues à la source (`orderActionLook`, jetons) : une régression de
// palette fait échouer ce test, pas seulement une revue visuelle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/home/presentation/widgets/order_actions_panel.dart';
import 'package:lilia_admin/models/order_actions.dart';
import 'package:lilia_admin/theme/app_theme.dart';
import 'package:lilia_admin/theme/lilia_tokens.dart';

import 'contrast_test.dart' show contrastRatio;

const _aa = 4.5;

/// Contraste minimal d'un élément graphique (WCAG 1.4.11).
const _nonTexte = 3.0;

void main() {
  // `AppTheme.light` charge des polices : sans liaison, bruit dans la sortie.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('gestes de commande (libellé blanc)', () {
    for (final action in OrderAction.values) {
      test(action.name, () {
        final fond = orderActionLook(action).color;
        expect(
          contrastRatio(Colors.white, fond),
          greaterThanOrEqualTo(_aa),
          reason: '$fond',
        );
      });
    }
  });

  test('fonds sous un texte blanc : jetons ajoutés et remplacements', () {
    for (final fond in [
      LiliaColors.green700, // succès, « Accepter », « Prête »
      LiliaColors.red500, // refus, annulation, erreurs
      LiliaColors.orange600, // action, compteurs
      Colors.teal.shade700, // « Remise au client »
    ]) {
      expect(
        contrastRatio(Colors.white, fond),
        greaterThanOrEqualTo(_aa),
        reason: '$fond',
      );
    }
  });

  test('orange700 sur orange.shade50 (filtre « aujourd’hui » inactif)', () {
    expect(
      contrastRatio(LiliaColors.orange700, Colors.orange.shade50),
      greaterThanOrEqualTo(_aa),
    );
  });

  test('indicateur de chargement visible sur un bouton désactivé', () {
    final t = LiliaSemantics.light;
    final cs = AppTheme.light.colorScheme;
    // ElevatedButton du thème : action à 40 % ; FilledButton par défaut :
    // onSurface à 12 %. Les deux sur le fond de l'écran.
    final fonds = [
      Color.alphaBlend(t.actionPrimary.withValues(alpha: 0.4), t.bgPrimary),
      Color.alphaBlend(cs.onSurface.withValues(alpha: 0.12), t.bgPrimary),
    ];
    for (final fond in fonds) {
      expect(
        contrastRatio(LiliaColors.charcoal700, fond),
        greaterThanOrEqualTo(_nonTexte),
        reason: '$fond',
      );
      // Ce que faisait `Colors.white` : sous le seuil, d'où le correctif.
      expect(contrastRatio(Colors.white, fond), lessThan(_nonTexte));
    }
  });
}
