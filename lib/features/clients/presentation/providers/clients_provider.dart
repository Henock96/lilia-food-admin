import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lilia_admin/features/clients/data/client_repository.dart';
import 'package:lilia_admin/models/app_user.dart';
import 'package:lilia_admin/models/client_loyalty.dart';
import 'package:lilia_admin/models/client_referral.dart';
import 'package:lilia_admin/models/paginated_clients.dart';
import 'package:lilia_admin/core/network/api_client.dart';

part 'clients_provider.g.dart';

@riverpod
ClientRepository clientRepository(Ref ref) {
  return ClientRepository(ref.watch(apiClientProvider));
}

/// Clients d'un restaurant (vue restaurateur).
@riverpod
Future<List<AppUser>> restaurantClients(Ref ref, String restaurantId) {
  return ref.watch(clientRepositoryProvider).fetchClients(restaurantId);
}

/// Tous les clients de la plateforme — paginés et filtrables (ADMIN).
@riverpod
Future<PaginatedClients> allClients(
  Ref ref, {
  required int page,
  required String search,
}) {
  return ref.watch(clientRepositoryProvider).fetchAllClients(page: page, search: search);
}

/// Fidélité d'un client (ADMIN).
@riverpod
Future<ClientLoyalty> clientLoyalty(Ref ref, String clientId) {
  return ref.watch(clientRepositoryProvider).fetchClientLoyalty(clientId);
}

/// Parrainage d'un client (ADMIN).
@riverpod
Future<ClientReferral> clientReferral(Ref ref, String clientId) {
  return ref.watch(clientRepositoryProvider).fetchClientReferral(clientId);
}
