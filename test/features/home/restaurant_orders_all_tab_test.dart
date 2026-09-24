import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/auth/user_sync_provider.dart';
import 'package:lilia_admin/features/home/data/order_controller.dart';
import 'package:lilia_admin/features/home/data/order_service.dart';
import 'package:lilia_admin/features/home/presentation/screens/restaurant_orders_screen.dart';
import 'package:lilia_admin/features/auth/app_user_model.dart';
import 'package:lilia_admin/models/order.dart';
import 'package:lilia_admin/models/role.dart';
import 'package:lilia_admin/services/admin_tracking_socket_service.dart';

/// Reproduction : Commandes → « Toutes » chargeait indéfiniment (24/09/2026).
class _AdminProfile extends CurrentUserProfile {
  @override
  AppUser? build() => const AppUser(
    uid: 'fb-admin',
    id: 'admin',
    email: 'admin@lilia.cg',
    role: Role.admin,
  );
}

class _FakeOrders extends OrderService {
  _FakeOrders()
    : super(
        ApiClient.test(
          baseUrl: 'http://localhost',
          tokenProvider: () async => 't',
          forceRefreshToken: () async => 't',
        ),
      );

  final calls = <OrderStatus?>[];

  /// Fait échouer le chargement de « Toutes » (le seul onglet sans statut).
  bool failAll = false;

  @override
  Future<OrderPage> getRestaurantOrders({
    required bool isAdmin,
    int page = 1,
    OrderStatus? status,
    String search = '',
  }) async {
    calls.add(status);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (failAll && status == null) {
      throw const FormatException('Réponse illisible');
    }
    final orders = [
      for (final (i, s) in [
        'EN_ATTENTE',
        'PAYER',
        'ACCEPTEE',
        'EN_PREPARATION',
        'PRET',
        'EN_ROUTE',
        'LIVRER',
        'ANNULER',
        'ECHEC_LIVRAISON',
      ].indexed)
        Order.fromJson({
          'id': 'order-000$i',
          'status': s,
          'total': 5000,
          'createdAt': '2026-09-24T10:00:00.000Z',
          'isDelivery': true,
          'restaurant': {'nom': 'Chez Lili'},
          'user': {
            'id': 'u$i',
            'nom': null,
            'phone': null,
            'email': 'deleted-u$i@deleted.liliafood.com',
          },
          'items': [],
          'allowedActions': [],
        }),
    ].where((o) => status == null || o.status == status).toList();
    return OrderPage(
      items: orders,
      total: orders.length,
      page: 1,
      totalPages: 1,
      statusCounts: {for (final s in OrderStatus.values) s: 1},
    );
  }
}

class _FakeSocket implements AdminTrackingSocketService {
  final subscribed = <String>[];
  @override
  Stream<AdminOrderStatusEvent> get events => const Stream.empty();
  @override
  Future<void> subscribeToOrders(Iterable<String> orderIds) async =>
      subscribed.addAll(orderIds);
  @override
  bool get isConnected => false;
  @override
  Future<void> reconnect() async {}
  @override
  void disconnect() {}
  @override
  void dispose() {}
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('« Toutes » affiche ses commandes et ne recharge pas en boucle', (
    tester,
  ) async {
    final orders = _FakeOrders();
    final socket = _FakeSocket();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith(_AdminProfile.new),
          orderServiceRepositoryProvider.overrideWithValue(orders),
          adminTrackingSocketServiceProvider.overrideWithValue(socket),
        ],
        child: const MaterialApp(home: RestaurantOrdersScreen()),
      ),
    );
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(orders.calls.where((s) => s == null).length, lessThan(3));
  });

  testWidgets(
    '« Toutes » en échec : l’erreur s’affiche, pas un spinner sans fin',
    (tester) async {
      final orders = _FakeOrders()..failAll = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(_AdminProfile.new),
            orderServiceRepositoryProvider.overrideWithValue(orders),
            adminTrackingSocketServiceProvider.overrideWithValue(_FakeSocket()),
          ],
          child: const MaterialApp(home: RestaurantOrdersScreen()),
        ),
      );
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Réponse illisible'), findsOneWidget);

      // La relance automatique de Riverpod garde un minuteur : on démonte et
      // on laisse le temps s'écouler pour qu'il ne survive pas au test.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
    },
  );
}
