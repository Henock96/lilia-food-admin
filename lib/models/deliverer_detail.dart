import 'package:lilia_admin/models/app_user.dart';
import 'package:lilia_admin/models/deliverer_stats.dart';
import 'package:lilia_admin/models/delivery_mission_summary.dart';

/// Vue détaillée d'un livreur pour la fiche admin
/// (route `GET /admin/deliverers/:id`).
///
/// **Stub LIL-85** — l'API publique (champs, types) doit rester identique à
/// celle livrée par LIL-84.
///
/// Le champ `user` est typé `AppUser` (modèle existant). Si LIL-84 décide de
/// renommer le champ (`user` → `profile` par exemple), c'est ici et dans le
/// provider `delivererDetailProvider` que ça change.
class DelivererDetail {
  final AppUser user;
  final DeliveryMissionSummary? currentMission;
  final DelivererStats stats;

  const DelivererDetail({
    required this.user,
    required this.stats,
    this.currentMission,
  });

  factory DelivererDetail.fromJson(Map<String, dynamic> json) {
    return DelivererDetail(
      user: AppUser.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? const {},
      ),
      currentMission: json['currentMission'] != null
          ? DeliveryMissionSummary.fromJson(
              json['currentMission'] as Map<String, dynamic>,
            )
          : null,
      stats: DelivererStats.fromJson(
        (json['stats'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}
