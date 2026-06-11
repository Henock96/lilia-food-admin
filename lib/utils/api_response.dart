/// Helpers tolérants pour déballer les réponses backend pendant la migration
/// vers l'API Contract v2 (`{ data, message?, meta? }`).
///
/// L'`ApiResponseInterceptor` backend ré-enveloppe tout payload dont les clés
/// ne sont pas ⊆ `{data, message, meta}`. Une réponse paginée
/// `{ data: [...], total, page, limit }` devient donc
/// `{ data: { data: [...], total, page, limit } }` (**double-wrap**). Ces
/// helpers gèrent indifféremment : liste brute, simple wrap et double wrap.
class ApiResponse {
  /// Extrait la liste, qu'elle soit :
  /// - une liste brute `[...]`
  /// - un simple wrap `{ data: [...] }`
  /// - un double wrap `{ data: { data: [...], ... } }`
  static List<dynamic> listOf(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final inner = decoded['data'];
      if (inner is List) return inner;
      // Double-wrap interceptor : { data: { data: [...], total, ... } }
      if (inner is Map<String, dynamic> && inner['data'] is List) {
        return inner['data'] as List<dynamic>;
      }
    }
    return <dynamic>[];
  }

  static Map<String, dynamic> mapOf(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map<String, dynamic>) {
        return decoded['data'] as Map<String, dynamic>;
      }
      return decoded;
    }
    throw StateError('Expected Map response, got ${decoded.runtimeType}');
  }
}
