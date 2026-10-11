// Lot 1 — le vendeur règle livraison et retrait depuis l'app.
//
// Trois couches, testées chacune là où elle décide :
//  · `ServiceModeSwitches` : ce qu'on peut basculer (jamais le dernier mode) ;
//  · `RestaurantSettingsService` : ce qui part réellement sur le réseau ;
//  · `RestaurantSettings` : un refus ne fait pas croire à une sauvegarde.
// Aucun appel réseau réel, aucune donnée de prod.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/settings/data/restaurant_settings_service.dart';
import 'package:lilia_admin/features/settings/presentation/providers/settings_provider.dart';
import 'package:lilia_admin/features/settings/presentation/widgets/service_mode_switches.dart';
import 'package:lilia_admin/models/restaurant.dart';

Map<String, dynamic> _vendorJson({
  bool supportsDelivery = true,
  bool supportsPickup = true,
}) => {
  'id': 'r1',
  'nom': 'Chez Mode',
  'adresse': 'Moungali',
  'phone': '060000081',
  'ownerId': 'u1',
  'supportsDelivery': supportsDelivery,
  'supportsPickup': supportsPickup,
  'fixedDeliveryFee': 1500,
  'estimatedDeliveryTimeMin': 20,
  'estimatedDeliveryTimeMax': 40,
  'minimumOrderAmount': 2000,
  'deliveryPriceMode': 'FIXED',
};

void main() {
  group('ServiceModeSwitches', () {
    Future<List<(bool, bool)>> pump(
      WidgetTester tester, {
      required bool delivery,
      required bool pickup,
    }) async {
      final calls = <(bool, bool)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceModeSwitches(
              delivery: delivery,
              pickup: pickup,
              onChanged: (d, p) => calls.add((d, p)),
            ),
          ),
        ),
      );
      return calls;
    }

    SwitchListTile tile(WidgetTester tester, String key) =>
        tester.widget<SwitchListTile>(find.byKey(Key(key)));

    testWidgets('affiche les deux valeurs chargées', (tester) async {
      await pump(tester, delivery: true, pickup: false);
      expect(tile(tester, 'service-mode-delivery').value, isTrue);
      expect(tile(tester, 'service-mode-pickup').value, isFalse);
      expect(find.text('Proposer la livraison'), findsOneWidget);
      expect(find.text('Proposer le retrait sur place'), findsOneWidget);
    });

    testWidgets('les deux actifs : désactiver la livraison garde le retrait',
        (tester) async {
      final calls = await pump(tester, delivery: true, pickup: true);
      await tester.tap(find.byKey(const Key('service-mode-delivery')));
      expect(calls, [(false, true)]);
    });

    testWidgets('les deux actifs : désactiver le retrait garde la livraison',
        (tester) async {
      final calls = await pump(tester, delivery: true, pickup: true);
      await tester.tap(find.byKey(const Key('service-mode-pickup')));
      expect(calls, [(true, false)]);
    });

    testWidgets('livraison seule : activer le retrait', (tester) async {
      final calls = await pump(tester, delivery: true, pickup: false);
      await tester.tap(find.byKey(const Key('service-mode-pickup')));
      expect(calls, [(true, true)]);
    });

    testWidgets('retrait seul : activer la livraison', (tester) async {
      final calls = await pump(tester, delivery: false, pickup: true);
      await tester.tap(find.byKey(const Key('service-mode-delivery')));
      expect(calls, [(true, true)]);
    });

    testWidgets('le dernier mode actif ne peut pas être coupé, et on dit pourquoi',
        (tester) async {
      final calls = await pump(tester, delivery: true, pickup: false);
      expect(tile(tester, 'service-mode-delivery').onChanged, isNull);
      await tester.tap(find.byKey(const Key('service-mode-delivery')));
      expect(calls, isEmpty);
      expect(find.textContaining('Au moins un mode doit rester actif'),
          findsOneWidget);
    });

    testWidgets('retrait seul : c’est le retrait qui est verrouillé',
        (tester) async {
      await pump(tester, delivery: false, pickup: true);
      expect(tile(tester, 'service-mode-pickup').onChanged, isNull);
      expect(tile(tester, 'service-mode-delivery').onChanged, isNotNull);
    });
  });

  group('ServiceModeDraft — ne pas écraser un changement plus récent', () {
    const lu = ServiceModeDraft.fromServer(delivery: true, pickup: true);

    test('non touché : rien n’est envoyé, le serveur garde sa valeur', () {
      expect(lu.payload, (delivery: null, pickup: null));
    });

    test('scénario de la revue : un admin passe en retrait seul pendant que '
        'le vendeur corrige ses frais — les modes ne repartent pas', () {
      // L'écran rafraîchi adopte la valeur de l'admin…
      final rafraichi = lu.syncWith(delivery: false, pickup: true);
      expect((rafraichi.delivery, rafraichi.pickup), (false, true));
      // … et l'enregistrement des frais n'y touche pas.
      expect(rafraichi.payload, (delivery: null, pickup: null));
    });

    test('touché : les deux valeurs saisies partent', () {
      final saisi = lu.edit(delivery: false, pickup: true);
      expect(saisi.payload, (delivery: false, pickup: true));
    });

    test('une saisie en cours n’est pas effacée par une relecture', () {
      final saisi = lu.edit(delivery: true, pickup: false);
      final relu = saisi.syncWith(delivery: true, pickup: true);
      expect((relu.delivery, relu.pickup), (true, false));
      expect(relu.touched, isTrue);
    });
  });

  group('RestaurantSettingsService.updateDeliverySettings', () {
    test('envoie les deux modes sur PATCH /vendors/:id/delivery', () async {
      final adapter = _RecordingAdapter(
        200,
        {
          'data': {
            'vendor': _vendorJson(supportsPickup: false),
            'readiness': {},
          },
        },
      );
      final service = RestaurantSettingsService(_apiWith(adapter));

      final updated = await service.updateDeliverySettings(
        'r1',
        supportsDelivery: true,
        supportsPickup: false,
      );

      expect(adapter.method, 'PATCH');
      expect(adapter.path, '/vendors/r1/delivery');
      expect(adapter.body, {'supportsDelivery': true, 'supportsPickup': false});
      // La réponse du serveur fait foi : c'est elle qui rafraîchit l'écran.
      expect(updated.supportsDelivery, isTrue);
      expect(updated.supportsPickup, isFalse);
    });

    test('modes non fournis : non envoyés, le serveur garde sa valeur',
        () async {
      final adapter = _RecordingAdapter(200, {
        'data': {'vendor': _vendorJson(), 'readiness': {}},
      });
      await RestaurantSettingsService(_apiWith(adapter))
          .updateDeliverySettings('r1', fixedDeliveryFee: 1500);

      expect(adapter.body, {'fixedDeliveryFee': 1500});
    });
  });

  group('RestaurantSettings.updateDeliverySettings', () {
    ProviderContainer containerWith(_FakeSettingsService fake) {
      final container = ProviderContainer(
        overrides: [restaurantSettingsServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('succès : l’état prend la configuration renvoyée par le serveur',
        () async {
      final fake = _FakeSettingsService(
        onUpdate: () async =>
            Restaurant.fromJson(_vendorJson(supportsDelivery: false)),
      );
      final container = containerWith(fake);
      await container.read(restaurantSettingsProvider.future);

      await container
          .read(restaurantSettingsProvider.notifier)
          .updateDeliverySettings(supportsDelivery: false, supportsPickup: true);

      final state = container.read(restaurantSettingsProvider);
      expect(state.value?.supportsDelivery, isFalse);
      expect(fake.sent, (false, true));
    });

    test('refus du serveur : l’erreur remonte, la configuration connue reste',
        () async {
      final fake = _FakeSettingsService(
        onUpdate: () async => throw Exception(
          'Un vendeur doit accepter au moins la livraison ou le retrait',
        ),
      );
      final container = containerWith(fake);
      await container.read(restaurantSettingsProvider.future);

      await expectLater(
        container
            .read(restaurantSettingsProvider.notifier)
            .updateDeliverySettings(
              supportsDelivery: false,
              supportsPickup: false,
            ),
        throwsA(isA<Exception>()),
      );

      final state = container.read(restaurantSettingsProvider);
      // Ni chargement ni erreur : l'écran reste en place, l'onglet affiche
      // le refus et la saisie du vendeur n'est pas perdue.
      expect(state.hasError, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.value?.supportsDelivery, isTrue);
      expect(state.value?.supportsPickup, isTrue);
    });
  });
}

ApiClient _apiWith(HttpClientAdapter adapter) {
  final api = ApiClient.test(
    baseUrl: 'https://api.test',
    tokenProvider: () async => 'token',
    forceRefreshToken: () async => 'token',
  );
  api.dio.httpClientAdapter = adapter;
  return api;
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.status, this.response);

  final int status;
  final Map<String, dynamic> response;
  String? method;
  String? path;
  Object? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.path;
    body = options.data;
    return ResponseBody.fromString(
      jsonEncode(response),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeSettingsService extends RestaurantSettingsService {
  _FakeSettingsService({required this.onUpdate})
    : super(
        ApiClient.test(
          baseUrl: 'https://api.test',
          tokenProvider: () async => null,
          forceRefreshToken: () async => null,
        ),
      );

  final Future<Restaurant> Function() onUpdate;
  (bool?, bool?)? sent;

  @override
  Future<Restaurant> getMyRestaurant() async =>
      Restaurant.fromJson(_vendorJson());

  @override
  Future<Restaurant> updateDeliverySettings(
    String restaurantId, {
    int? fixedDeliveryFee,
    int? estimatedDeliveryTimeMin,
    int? estimatedDeliveryTimeMax,
    int? minimumOrderAmount,
    String? deliveryPriceMode,
    bool? supportsDelivery,
    bool? supportsPickup,
  }) {
    sent = (supportsDelivery, supportsPickup);
    return onUpdate();
  }
}
