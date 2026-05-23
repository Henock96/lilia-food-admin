import 'dart:math' as math;

/// Outils géographiques basiques utilisés côté admin pour estimer la distance
/// et l'ETA d'un livreur quand le backend n'envoie pas (encore) d'ETA dans
/// l'event `driver:position`.
///
/// Implémentation volontairement simple — pas de dépendance externe, pas de
/// projection cartographique : suffisant pour Brazzaville (zone urbaine
/// quelques dizaines de km).
///
/// Conventions :
///   - lat/lng en degrés décimaux (WGS84)
///   - distances en kilomètres
///   - vitesse en km/h, ETA en minutes entières

/// Rayon moyen de la Terre en kilomètres, valeur standard utilisée par
/// l'implémentation classique de la formule de Haversine.
const double _earthRadiusKm = 6371.0;

/// Vitesse moyenne par défaut d'un livreur à moto/scooter en zone urbaine
/// Brazzaville (trafic + arrêts intersections inclus). Volontairement
/// conservatrice — sous-estime un peu pour éviter d'afficher un ETA trop
/// optimiste au client.
const double kDefaultDelivererSpeedKmh = 25.0;

double _toRadians(double degrees) => degrees * math.pi / 180.0;

/// Calcule la distance "vol d'oiseau" entre deux points GPS en kilomètres,
/// via la formule de Haversine.
///
/// Cette distance ne tient pas compte du réseau routier — c'est une borne
/// inférieure de la distance réelle. Pour l'ETA on compense en utilisant
/// une vitesse moyenne basse ([kDefaultDelivererSpeedKmh]).
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return _earthRadiusKm * c;
}

/// Convertit une distance (km) en ETA en minutes entières, à partir d'une
/// vitesse moyenne en km/h.
///
/// Retourne `0` si la distance ou la vitesse sont nulles/négatives — la UI
/// peut alors afficher "Arrivé" ou un fallback.
int etaMinutes(double distanceKm, {double avgKmh = kDefaultDelivererSpeedKmh}) {
  if (distanceKm <= 0 || avgKmh <= 0) return 0;
  final hours = distanceKm / avgKmh;
  return (hours * 60).round();
}
