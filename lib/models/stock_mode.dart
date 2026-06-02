// ignore_for_file: constant_identifier_names

/// Mode de gestion du stock (cf. backend `StockMode`).
///
/// `DAILY` est reset chaque nuit par le cron 5h Brazzaville. `PERMANENT`
/// décrémente uniquement (épicerie, vendeurs sans rotation quotidienne).
enum StockMode {
  DAILY,
  PERMANENT;

  String get label {
    switch (this) {
      case StockMode.DAILY:
        return 'Stock journalier';
      case StockMode.PERMANENT:
        return 'Stock permanent';
    }
  }

  static StockMode fromString(String? value) {
    return StockMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StockMode.DAILY,
    );
  }
}
