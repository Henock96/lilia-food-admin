import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lilia_admin/models/app_user.dart';
import 'package:lilia_admin/models/role.dart';
import 'package:lilia_admin/features/auth/user_sync_provider.dart';
import 'package:lilia_admin/features/clients/presentation/providers/clients_provider.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const ClientsScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  int _page = 1;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _search = value;
        _page = 1;
      });
    });
  }

  // Filtrage local — utilisé uniquement pour la vue restaurateur (liste complète).
  List<AppUser> _filterLocal(List<AppUser> clients) {
    if (_search.isEmpty) return clients;
    final q = _search.toLowerCase();
    return clients.where((c) {
      return (c.nom?.toLowerCase().contains(q) ?? false) ||
          c.email.toLowerCase().contains(q) ||
          (c.phone?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final isAdmin = userProfile?.role == Role.admin;

    if (!isAdmin && widget.restaurantId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Clients du Restaurant'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Tous les clients' : 'Clients du Restaurant'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () {
              if (isAdmin) {
                setState(() => _page = 1);
                ref.invalidate(allClientsProvider);
              } else {
                ref.invalidate(restaurantClientsProvider(widget.restaurantId));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: isAdmin ? _buildAdminList() : _buildRestaurantList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, email ou téléphone...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ── Vue ADMIN : pagination + recherche serveur ──────────────────────────
  Widget _buildAdminList() {
    final clientsAsync = ref.watch(allClientsProvider(page: _page, search: _search));
    return clientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _errorView(error, () => ref.invalidate(allClientsProvider)),
      data: (result) {
        if (result.clients.isEmpty) {
          return _emptyView(
            _search.isNotEmpty ? 'Aucun résultat pour "$_search"' : 'Aucun client trouvé.',
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: result.clients.length,
                itemBuilder: (context, index) =>
                    _ClientCard(client: result.clients[index], showLoyalty: true),
              ),
            ),
            _buildPagination(result.total, result.totalPages),
          ],
        );
      },
    );
  }

  Widget _buildPagination(int total, int totalPages) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$total client${total > 1 ? 's' : ''} · page $_page/$totalPages',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Page précédente',
                onPressed: _page > 1 ? () => setState(() => _page--) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Page suivante',
                onPressed: _page < totalPages ? () => setState(() => _page++) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Vue RESTAURATEUR : liste complète + filtrage local ──────────────────
  Widget _buildRestaurantList() {
    final clientsAsync = ref.watch(restaurantClientsProvider(widget.restaurantId));
    return clientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _errorView(
        error,
        () => ref.invalidate(restaurantClientsProvider(widget.restaurantId)),
      ),
      data: (clients) {
        final filtered = _filterLocal(clients);
        if (filtered.isEmpty) {
          return _emptyView(
            _search.isNotEmpty ? 'Aucun résultat pour "$_search"' : 'Aucun client trouvé.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(restaurantClientsProvider(widget.restaurantId).future),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _ClientCard(client: filtered[index]),
          ),
        );
      },
    );
  }

  Widget _emptyView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _errorView(Object error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur de chargement', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final AppUser client;
  /// Affiche le solde de fidélité — uniquement en vue ADMIN, où l'endpoint
  /// `/admin/clients` renvoie `loyaltyPoints` (la vue restaurateur ne l'a pas).
  final bool showLoyalty;

  const _ClientCard({required this.client, this.showLoyalty = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: client.imageUrl != null ? NetworkImage(client.imageUrl!) : null,
                child: client.imageUrl == null
                    ? Text(
                        client.initials,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.nom ?? 'Nom non disponible',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            client.email,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (client.phone != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(client.phone!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showLoyalty) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars, size: 13, color: Colors.amber[700]),
                        const SizedBox(width: 3),
                        Text(
                          '${client.loyaltyPoints}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (client.phone != null)
                    InkWell(
                      onTap: () => _launchPhone(client.phone!),
                      child: Icon(Icons.call, color: Colors.green[600], size: 20),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    if (client.id.isNotEmpty) {
      context.goNamed('client-detail', pathParameters: {'id': client.id}, extra: client);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
