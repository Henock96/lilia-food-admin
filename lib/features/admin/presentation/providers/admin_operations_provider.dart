import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lilia_admin/features/admin/data/admin_operations_repository.dart';
import 'package:lilia_admin/models/admin_payment.dart';
import 'package:lilia_admin/models/admin_deliverer.dart';
import 'package:lilia_admin/models/platform_settings.dart';

part 'admin_operations_provider.g.dart';

@riverpod
AdminOperationsRepository adminOperationsRepository(Ref ref) {
  return AdminOperationsRepository();
}

/// Paiements paginés, filtrés par statut (ADMIN).
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
