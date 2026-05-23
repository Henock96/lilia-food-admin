/// Enveloppe paginée générique pour les endpoints qui renvoient :
/// `{ data: [...], meta: { page, limit, total, totalPages } }`.
///
/// Construite via [Paginated.fromJson] qui prend la clé `data`, la clé `meta`
/// et un parseur d'élément. Tolère l'absence de `meta` en retombant sur les
/// clés racines `page`, `limit`, `total`, `totalPages` (utile pour les
/// anciens endpoints à plat).
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

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    final list = json['data'] as List<dynamic>? ?? <dynamic>[];
    final meta = json['meta'] as Map<String, dynamic>?;
    final source = meta ?? json;

    final page = (source['page'] as int?) ?? 1;
    final limit = (source['limit'] as int?) ?? list.length;
    final total = (source['total'] as int?) ?? list.length;
    final int totalPages;
    final rawTotalPages = source['totalPages'] as int?;
    if (rawTotalPages != null) {
      totalPages = rawTotalPages;
    } else if (limit > 0) {
      totalPages = ((total + limit - 1) ~/ limit).clamp(1, 1 << 31);
    } else {
      totalPages = 1;
    }

    return Paginated<T>(
      data: list
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(growable: false),
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  /// Enveloppe vide (utile comme état initial/erreur).
  static Paginated<T> empty<T>({int page = 1, int limit = 20}) {
    return Paginated<T>(
      data: const [],
      page: page,
      limit: limit,
      total: 0,
      totalPages: 1,
    );
  }
}
