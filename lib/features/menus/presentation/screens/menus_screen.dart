import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../models/menu.dart';
import '../providers/menus_provider.dart';
import 'menu_form_screen.dart';

class MenusScreen extends ConsumerWidget {
  const MenusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusAsync = ref.watch(menusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menus du Jour'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(menusProvider.notifier).refresh(),
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MenuFormScreen(),
                ),
              );
            },
            tooltip: 'Ajouter un menu',
          ),
        ],
      ),
      body: menusAsync.when(
        data: (menus) {
          if (menus.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun menu',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Appuyez sur + pour créer un menu du jour',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(menusProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: menus.length,
              itemBuilder: (context, index) {
                final menu = menus[index];
                return _MenuCard(menu: menu);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(menusProvider.notifier).refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MenuFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau menu'),
      ),
    );
  }
}

class _MenuCard extends ConsumerWidget {
  final MenuDuJour menu;

  const _MenuCard({required this.menu});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isValid = menu.isCurrentlyValid;
    final isExpired = menu.isExpired;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isExpired) {
      statusColor = Colors.grey;
      statusText = 'Expiré';
      statusIcon = Icons.schedule;
    } else if (isValid) {
      statusColor = Colors.green;
      statusText = 'Actif';
      statusIcon = Icons.check_circle;
    } else if (!menu.isActive) {
      statusColor = Colors.orange;
      statusText = 'Désactivé';
      statusIcon = Icons.pause_circle;
    } else {
      statusColor = Colors.blue;
      statusText = 'Planifié';
      statusIcon = Icons.event;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (menu.imageUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                menu.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.restaurant_menu, size: 48),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        menu.nom,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Badge type
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: menu.isPlatSpecial
                            ? Colors.orange[50]
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        menu.isPlatSpecial ? 'Plat Special' : 'Combo',
                        style: TextStyle(
                          color: menu.isPlatSpecial
                              ? Colors.orange[800]
                              : Colors.blue[800],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Badge statut
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${menu.prix.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                if (menu.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    menu.description!,
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${dateFormat.format(menu.dateDebut)} - ${dateFormat.format(menu.dateFin)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                if (menu.isPlatSpecial &&
                    menu.ingredients != null &&
                    menu.ingredients!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.restaurant, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          menu.ingredients!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ] else if (!menu.isPlatSpecial && menu.products.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: menu.products
                        .take(3)
                        .map((p) => Chip(
                              label: Text(
                                p.product?.name ?? 'Produit',
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                  if (menu.products.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${menu.products.length - 3} autres produits',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isExpired
                            ? null
                            : () async {
                                try {
                                  await ref
                                      .read(menusProvider.notifier)
                                      .toggleMenuStatus(menu.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(menu.isActive
                                            ? 'Menu désactivé'
                                            : 'Menu activé'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erreur: $e')),
                                    );
                                  }
                                }
                              },
                        icon: Icon(
                          menu.isActive ? Icons.pause : Icons.play_arrow,
                          size: 18,
                        ),
                        label: Text(menu.isActive ? 'Désactiver' : 'Activer'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MenuFormScreen(menu: menu),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Supprimer le menu'),
                            content: Text(
                                'Voulez-vous vraiment supprimer "${menu.nom}" ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await ref
                                .read(menusProvider.notifier)
                                .deleteMenu(menu.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Menu supprimé')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
