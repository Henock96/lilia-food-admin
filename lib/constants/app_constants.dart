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
}
