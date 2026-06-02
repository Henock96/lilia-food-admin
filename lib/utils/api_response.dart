class ApiResponse {
  static List<dynamic> listOf(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return decoded['data'] as List<dynamic>;
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
