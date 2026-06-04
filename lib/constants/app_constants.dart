class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://lilia-backend.onrender.com',
  );
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'https://lilia-backend.onrender.com',
  );
  static const String trackingNamespace = '/tracking';

  /// Taille de page par défaut pour les listes paginées admin
  /// (paiements, livreurs, missions…).
  static const int adminPageSize = 20;
}
