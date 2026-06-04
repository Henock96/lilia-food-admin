import 'package:intl/intl.dart';

/// Formatage centralisé des montants en Francs CFA (`XAF`).
///
/// Sépare les milliers selon la locale `fr_FR` et suffixe avec le code
/// devise standard du projet (`XAF`, pas `FCFA`) :
/// `150000` → « 150 000 XAF ».
///
/// `initializeDateFormatting('fr_FR')` est déjà appelé dans `main.dart`,
/// la locale est donc disponible.
String formatXaf(num amount) =>
    '${NumberFormat.decimalPattern('fr_FR').format(amount)} XAF';
