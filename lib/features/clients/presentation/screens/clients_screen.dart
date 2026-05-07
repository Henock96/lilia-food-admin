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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUser> _filterClients(List<AppUser> clients) {
    if (_searchQuery.isEmpty) return clients;
    final query = _searchQuery.toLowerCase();
    return clients.where((c) {
      return (c.nom?.toLowerCase().contains(query) ?? false) ||
          (c.email.toLowerCase().contains(query)) ||
          (c.phone?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final isAdmin = userProfile?.role == Role.admin;

    if (!isAdmin && widget.restaurantId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Clients du Restaurant'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final clientsAsync = isAdmin
        ? ref.watch(allClientsProvider)
        : ref.watch(restaurantClientsProvider(widget.restaurantId));

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
                ref.invalidate(allClientsProvider);
              } else {
                ref.invalidate(restaurantClientsProvider(widget.restaurantId));
              }
            },
          ),
        ],
      ),
      body: clientsAsync.when(
        data: (clients) {
          if (clients.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun client trouvé.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final filteredClients = _filterClients(clients);

          return RefreshIndicator(
            onRefresh: () async {
              if (isAdmin) {
                return ref.refresh(allClientsProvider.future);
              } else {
                return ref.refresh(
                    restaurantClientsProvider(widget.restaurantId).future);
              }
            },
            child: Column(
              children: [
                // Barre de recherche + stats
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    children: [
                      // Stats rapides
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people, color: Theme.of(context).colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${clients.length} client${clients.length > 1 ? 's' : ''} au total',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Barre de recherche
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher par nom, email ou téléphone...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
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
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${filteredClients.length} résultat${filteredClients.length > 1 ? 's' : ''}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                // Liste des clients
                Expanded(
                  child: filteredClients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'Aucun résultat pour "$_searchQuery"',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: filteredClients.length,
                          itemBuilder: (context, index) {
                            return _ClientCard(client: filteredClients[index]);
                          },
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (isAdmin) {
                      ref.invalidate(allClientsProvider);
                    } else {
                      ref.invalidate(restaurantClientsProvider(widget.restaurantId));
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final AppUser client;

  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final clientId = client.id;
          if (clientId.isNotEmpty) {
            context.goNamed(
              'client-detail',
              pathParameters: {'id': clientId},
              extra: client,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
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
              // Infos
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
                          Text(
                            client.phone!,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Actions rapides
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (client.phone != null)
                    IconButton(
                      icon: Icon(Icons.call, color: Colors.green[600], size: 22),
                      tooltip: 'Appeler',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      onPressed: () => _launchPhone(client.phone!),
                    ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                    tooltip: 'Voir le détail',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      final clientId = client.id;
                      if (clientId.isNotEmpty) {
                        context.goNamed(
                          'client-detail',
                          pathParameters: {'id': clientId},
                          extra: client,
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
