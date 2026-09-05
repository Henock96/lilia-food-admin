import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/models/delivery_status.dart';
import 'package:lilia_admin/models/location_precision.dart';

void main() {
  group('DeliveryStatus', () {
    /// Le test qui manquait. `ACCEPTER` a été ajouté côté backend le
    /// 29/08/2026 ; l'enum de l'admin l'ignorait, `fromWire` le convertissait
    /// silencieusement en `EN_ATTENTE`, et l'écran de suivi en déduisait
    /// « pas en livraison ». Résultat : aucune carte entre l'acceptation de la
    /// mission et la récupération du repas.
    test('reconnaît ACCEPTER', () {
      expect(DeliveryStatus.fromWire('ACCEPTER'), DeliveryStatus.accepter);
      expect(DeliveryStatus.accepter.wireValue, 'ACCEPTER');
    });

    test('couvre les six valeurs du backend', () {
      const wire = [
        'EN_ATTENTE',
        'ASSIGNER',
        'ACCEPTER',
        'EN_TRANSIT',
        'LIVRER',
        'ECHEC',
      ];
      // Chaque valeur du fil a un pendant dans l'enum, et réciproquement :
      // c'est la double implication qui attrape une divergence, pas la simple.
      expect(wire.length, DeliveryStatus.values.length);
      for (final value in wire) {
        expect(DeliveryStatus.fromWire(value).wireValue, value);
      }
      for (final status in DeliveryStatus.values) {
        expect(wire, contains(status.wireValue));
      }
    });

    test('une valeur inconnue ne casse pas l’écran', () {
      // Le repli reste, mais il est désormais bruyant (assert + log) : ce
      // silence est ce qui a laissé passer `ACCEPTER` pendant des jours.
      expect(DeliveryStatus.fromWire(null), DeliveryStatus.enAttente);
    });
  });

  group('LocationPrecision', () {
    test('parse les trois valeurs', () {
      expect(LocationPrecision.fromWire('EXACT'), LocationPrecision.exact);
      expect(
        LocationPrecision.fromWire('APPROXIMATE'),
        LocationPrecision.approximate,
      );
      expect(LocationPrecision.fromWire('UNKNOWN'), LocationPrecision.unknown);
    });

    test('retombe sur unknown — la carte se tait au lieu de mentir', () {
      expect(LocationPrecision.fromWire(null), LocationPrecision.unknown);
      expect(LocationPrecision.fromWire('ROOFTOP'), LocationPrecision.unknown);
    });

    test('hasPosition n’autorise le marqueur que si un point existe', () {
      expect(LocationPrecision.exact.hasPosition, isTrue);
      expect(LocationPrecision.approximate.hasPosition, isTrue);
      expect(LocationPrecision.unknown.hasPosition, isFalse);
    });
  });
}
