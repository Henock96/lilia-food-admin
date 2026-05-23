import 'package:lilia_admin/features/admin/data/admin_operations_repository.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/models/delivery.dart';
import 'package:lilia_admin/models/delivery_mission_summary.dart';
import 'package:lilia_admin/models/delivery_status.dart';
import 'package:lilia_admin/models/deliverer_detail.dart';
import 'package:lilia_admin/models/deliverer_stats.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deliverer_detail_provider.g.dart';

/// Fiche détaillée d'un livreur (user + stats + mission en cours).
///
/// Composé côté repository à partir de 3 appels HTTP — voir
/// [AdminOperationsRepository.getDelivererDetail].
@riverpod
Future<DelivererDetail> delivererDetail(Ref ref, String id) {
  return ref.watch(adminOperationsRepositoryProvider).getDelivererDetail(id);
}

/// Stats seules d'un livreur — utile si l'écran veut rafraîchir les stats
/// sans recharger toute la fiche.
@riverpod
Future<DelivererStats> delivererStats(Ref ref, String id) {
  return ref.watch(adminOperationsRepositoryProvider).getDelivererStats(id);
}

/// Livraison associée à une commande — point d'entrée pour
/// [DeliveryTrackingScreen] (LIL-86) qui a besoin de l'adresse client +
/// info livreur avant d'ouvrir le stream WebSocket.
@riverpod
Future<Delivery> deliveryByOrder(Ref ref, String orderId) {
  return ref.watch(adminOperationsRepositoryProvider).getDeliveryByOrder(orderId);
}

/// État immuable de la liste paginée des missions d'un livreur.
class DelivererMissionsState {
  final List<DeliveryMissionSummary> items;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final DeliveryStatus? statusFilter;

  const DelivererMissionsState({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.isLoadingMore,
    required this.statusFilter,
  });

  bool get hasMore => page < totalPages;

  DelivererMissionsState copyWith({
    List<DeliveryMissionSummary>? items,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    DeliveryStatus? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return DelivererMissionsState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

/// Contrôleur paginé des missions d'un livreur.
///
/// API publique :
/// - `loadMore()` — appelle la page suivante et accumule dans `state.items`.
/// - `setStatusFilter(status)` — réinitialise et refetch avec le nouveau filtre.
/// - `refresh()` — repart de la page 1 en gardant le filtre courant.
@riverpod
class DelivererMissionsController extends _$DelivererMissionsController {
  static const int _pageSize = 20;

  @override
  Future<DelivererMissionsState> build(String delivererId) async {
    return _fetchPage(delivererId, page: 1, statusFilter: null);
  }

  Future<DelivererMissionsState> _fetchPage(
    String id, {
    required int page,
    required DeliveryStatus? statusFilter,
  }) async {
    final paginated =
        await ref.read(adminOperationsRepositoryProvider).getDelivererMissions(
              id,
              status: statusFilter,
              page: page,
              limit: _pageSize,
            );
    return DelivererMissionsState(
      items: paginated.data,
      page: paginated.page,
      totalPages: paginated.totalPages,
      isLoadingMore: false,
      statusFilter: statusFilter,
    );
  }

  /// Charge la page suivante. No-op si déjà à la fin ou si un chargement
  /// est en cours.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final next = await ref
          .read(adminOperationsRepositoryProvider)
          .getDelivererMissions(
            delivererId,
            status: current.statusFilter,
            page: current.page + 1,
            limit: _pageSize,
          );
      state = AsyncData(current.copyWith(
        items: [...current.items, ...next.data],
        page: next.page,
        totalPages: next.totalPages,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      // On préserve les items déjà chargés et on remonte l'erreur via le state.
      state = AsyncError(e, st);
    }
  }

  /// Change le filtre statut et repart de la page 1.
  Future<void> setStatusFilter(DeliveryStatus? status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(
          delivererId,
          page: 1,
          statusFilter: status,
        ));
  }

  /// Refetch la page 1 avec le filtre courant.
  Future<void> refresh() async {
    final filter = state.value?.statusFilter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(
          delivererId,
          page: 1,
          statusFilter: filter,
        ));
  }
}
