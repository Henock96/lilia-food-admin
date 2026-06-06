import 'package:intl/intl.dart';

/// Décalage horaire de Brazzaville (WAT, UTC+1, pas de changement d'heure).
const Duration _brazzavilleOffset = Duration(hours: 1);

/// Convertit un instant (généralement reçu en UTC du backend) vers l'heure
/// locale de Brazzaville. À utiliser pour tout affichage de date/heure afin de
/// ne pas dépendre du fuseau de l'appareil.
DateTime toBrazzaville(DateTime dt) => dt.toUtc().add(_brazzavilleOffset);

/// Date + heure courte à Brazzaville, ex. « 30/05/2026 à 14:30 ».
String formatBrazzavilleDateTime(DateTime dt) =>
    DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(toBrazzaville(dt));
