/// Heures d'arrivée qu'une plage propose, pour l'affichage seulement.
///
/// Règle D3 (Premium Lot 3) : départs à `start`, `start + step`… tant que
/// `≤ end` — `end` est la **dernière arrivée acceptée**, pas la fermeture.
/// La validation (chevauchements, horaires d'ouverture, bornes) reste celle du
/// serveur (`preview` / `PUT`) ; ce calcul ne sert qu'à montrer au vendeur ce
/// que sa saisie signifie, à chaque modification, sans aller-retour réseau.
/// Un test compare ce calcul aux créneaux réellement renvoyés par le serveur.
///
/// Rend une liste vide pour une plage invalide ou une heure illisible : le
/// constat du serveur dira quoi corriger.
List<String> arrivalTimes(String start, String end, int step) {
  final from = _minutes(start);
  final to = _minutes(end);
  if (from == null || to == null || step <= 0 || from >= to) return const [];
  return [for (var t = from; t <= to; t += step) _format(t)];
}

/// Liste lisible ; au-delà de six heures, le début, la fin et le nombre.
String arrivalSummary(List<String> times) {
  if (times.length <= 6) return times.join(', ');
  return '${times.take(3).join(', ')} … '
      '${times.skip(times.length - 2).join(', ')} · ${times.length} arrivées';
}

int? _minutes(String hhmm) {
  final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(hhmm);
  if (match == null) return null;
  return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
}

String _format(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';
