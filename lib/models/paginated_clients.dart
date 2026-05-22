import 'package:lilia_admin/models/app_user.dart';

/// Enveloppe paginée de la liste clients (GET /admin/clients).
class PaginatedClients {
  final List<AppUser> clients;
  final int total;
  final int page;
  final int limit;

  PaginatedClients({
    required this.clients,
    required this.total,
    required this.page,
    required this.limit,
  });

  int get totalPages => limit > 0 ? ((total + limit - 1) ~/ limit).clamp(1, 1 << 31) : 1;
}
