import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/admin/domain/platform_settings_form.dart';

/// Un 409 n'est pas toujours un conflit entre administrateurs (24/09/2026).
void main() {
  test('SETTINGS_STALE : conflit', () {
    expect(
      isStaleSettingsConflict(
        const ApiException('x', statusCode: 409, code: 'SETTINGS_STALE'),
      ),
      isTrue,
    );
  });

  test('grille non publiée : message métier, pas un conflit', () {
    expect(
      isStaleSettingsConflict(
        const ApiException(
          'Publiez une grille de livraison…',
          statusCode: 409,
          code: 'DELIVERY_TARIFF_NOT_PUBLISHED',
        ),
      ),
      isFalse,
    );
  });

  test('serveur antérieur au code : reconnu par son texte', () {
    expect(
      isStaleSettingsConflict(
        const ApiException(
          'La configuration a été modifiée par un autre administrateur depuis…',
          statusCode: 409,
        ),
      ),
      isTrue,
    );
  });
}
