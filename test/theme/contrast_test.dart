// Contrastes WCAG AA des tokens de l'admin — mêmes seuils que l'app client
// (`lilia-app/test/theme/contrast_test.dart`). Phase 3 UI/UX, 29/09/2026 : le
// fond de tous les boutons d'action était à 3,67:1 (clair) et le blanc posé
// sur l'orange du thème sombre à 2,84:1.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/theme/app_theme.dart';
import 'package:lilia_admin/theme/lilia_tokens.dart';

double contrastRatio(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final la = lum(a), lb = lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

const _aa = 4.5;

void main() {
  for (final (nom, t) in [
    ('clair', LiliaSemantics.light),
    ('sombre', LiliaSemantics.dark),
  ]) {
    group(nom, () {
      test('texte sur action principale', () {
        expect(
          contrastRatio(t.textOnAction, t.actionPrimary),
          greaterThanOrEqualTo(_aa),
        );
      });

      test('textMuted sur les fonds', () {
        for (final bg in [t.bgPrimary, t.bgSecondary, t.bgElevated]) {
          expect(
            contrastRatio(t.textMuted, bg),
            greaterThanOrEqualTo(_aa),
            reason: '$bg',
          );
        }
      });
    });
  }

  test('ColorScheme : onPrimary sur primary, clair et sombre', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final cs = theme.colorScheme;
      expect(
        contrastRatio(cs.onPrimary, cs.primary),
        greaterThanOrEqualTo(_aa),
        reason: cs.brightness.name,
      );
    }
  });
}
