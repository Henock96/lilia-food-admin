import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lilia_admin/features/admin/data/admin_operations_repository.dart';
import 'package:lilia_admin/models/admin_payment.dart';
import 'package:lilia_admin/models/admin_deliverer.dart';
import 'package:lilia_admin/models/payments_stats.dart';
import 'package:lilia_admin/models/platform_settings.dart';
import 'package:lilia_admin/models/order_financials.dart';
import 'package:lilia_admin/core/network/api_client.dart';

part 'admin_operations_provider.g.dart';

@riverpod
AdminOperationsRepository adminOperationsRepository(Ref ref) {
  return AdminOperationsRepository(ref.watch(apiClientProvider));
}

/// Paiements paginés (ADMIN). `status` vide → vue "Tous statuts confondus".
@riverpod
Future<PaginatedPayments> adminPayments(
  Ref ref, {
  required int page,
  required String status,
}) {
  return ref
      .watch(adminOperationsRepositoryProvider)
      .fetchPayments(page: page, status: status);
}

/// KPI paiements (ADMIN) — pending à confirmer, encaissé ce mois, 7j roulants.
@riverpod
Future<PaymentsStats> adminPaymentsStats(Ref ref) {
  return ref.watch(adminOperationsRepositoryProvider).fetchPaymentsStats();
}

/// Livreurs paginés (ADMIN).
@riverpod
Future<PaginatedDeliverers> adminDeliverers(Ref ref, {required int page}) {
  return ref
      .watch(adminOperationsRepositoryProvider)
      .fetchDeliverers(page: page);
}

/// Configuration plateforme (ADMIN).
@riverpod
Future<PlatformSettings> platformSettings(Ref ref) {
  return ref.watch(adminOperationsRepositoryProvider).fetchPlatformSettings();
}

/// Récapitulatif financier d'une commande (ADMIN) : encaissement client,
/// reversement vendeur, marge Lilia Food — et l'éligibilité au paiement du
/// restaurant, **décidée par le serveur**.
///
/// `autoDispose` implicite (`@riverpod`) : la fiche n'est chargée que tant
/// qu'un écran l'affiche. Après un reversement, l'appelant invalide ce provider
/// pour relire l'état réel plutôt que de le supposer.
@riverpod
Future<OrderFinancials> orderFinancials(Ref ref, {required String orderId}) {
  return ref.watch(adminOperationsRepositoryProvider).fetchOrderFinancials(orderId);
}
