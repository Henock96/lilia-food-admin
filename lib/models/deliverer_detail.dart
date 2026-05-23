import 'package:lilia_admin/models/admin_deliverer.dart';
import 'package:lilia_admin/models/deliverer_stats.dart';
import 'package:lilia_admin/models/delivery_mission_summary.dart';

/// Composition côté Flutter pour la fiche livreur de l'app admin.
///
/// Le backend n'expose pas un endpoint unique qui renvoie ce composé —
/// [AdminOperationsRepository.getDelivererDetail] agrège plusieurs appels :
/// - `GET /admin/deliverers` (paginé) → lookup du livreur par `id`
///   (mappé sur le modèle existant [AdminDeliverer]). À remplacer par un
///   futur `GET /admin/deliverers/:id` si la liste devient trop grosse.
/// - `GET /admin/deliverers/:id/stats` → [DelivererStats]
/// - `GET /admin/deliverers/:id/missions?status=EN_TRANSIT&limit=1` puis
///   fallback `ASSIGNER&limit=1` → [currentMission] (ou `null`).
class DelivererDetail {
  final AdminDeliverer user;
  final DeliveryMissionSummary? currentMission;
  final DelivererStats stats;

  const DelivererDetail({
    required this.user,
    required this.stats,
    this.currentMission,
  });

  DelivererDetail copyWith({
    AdminDeliverer? user,
    DeliveryMissionSummary? currentMission,
    DelivererStats? stats,
    bool clearCurrentMission = false,
  }) {
    return DelivererDetail(
      user: user ?? this.user,
      currentMission:
          clearCurrentMission ? null : (currentMission ?? this.currentMission),
      stats: stats ?? this.stats,
    );
  }
}
