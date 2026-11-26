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

  /// Espace web Lilia (administration et restaurateurs). Domaine canonique
  /// en `www` (CORS du backend).
  static const String adminWebUrl = String.fromEnvironment(
    'ADMIN_WEB_URL',
    defaultValue: 'https://www.liliafood-admin.com',
  );

  /// Premium S1 (25/11/2026) — la souscription et son paiement pawaPay se
  /// font sur l'espace web, pas dans l'app : elle y renvoie.
  static const String premiumWebUrl = '$adminWebUrl/premium';
}
