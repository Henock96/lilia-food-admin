/// Enveloppe générique de pagination (`{ data, page, limit, total, totalPages }`).
///
/// **Stub LIL-85** — l'API publique (champs / types) doit rester identique à
/// celle livrée par LIL-84.
class Paginated<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const Paginated({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  /// Construit un [Paginated] à partir d'une enveloppe JSON et d'un parser
  /// d'item. La forme attendue par défaut (alignée backend) est :
  /// `{ data: [...], page, limit, total, totalPages? }`.
  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parseItem,
  ) {
    final list = (json['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(parseItem)
        .toList(growable: false);

    final limit = (json['limit'] as num?)?.toInt() ?? list.length;
    final total = (json['total'] as num?)?.toInt() ?? list.length;
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final totalPages = (json['totalPages'] as num?)?.toInt() ??
        (limit > 0 ? ((total + limit - 1) ~/ limit).clamp(1, 1 << 31) : 1);

    return Paginated<T>(
      data: list,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  bool get hasMore => page < totalPages;
}
