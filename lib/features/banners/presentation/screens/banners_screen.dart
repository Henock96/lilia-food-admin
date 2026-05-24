import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/banner.dart';
import '../providers/banners_provider.dart';
import 'banner_form_screen.dart';

class BannersScreen extends ConsumerWidget {
  const BannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bannières'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const BannerFormScreen()),
          );
          if (result == true) {
            ref.read(bannersProvider.notifier).refresh();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: bannersAsync.when(
        data: (banners) {
          if (banners.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune bannière',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Appuyez sur + pour ajouter une bannière',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(bannersProvider.notifier).refresh(),
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: banners.length,
              onReorderItem: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final reordered = List<AppBanner>.from(banners);
                final item = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, item);
                ref.read(bannersProvider.notifier).reorderBanners(reordered);
              },
              itemBuilder: (context, index) {
                final banner = banners[index];
                return _BannerTile(
                  key: ValueKey(banner.id),
                  banner: banner,
                  onEdit: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => BannerFormScreen(banner: banner),
                      ),
                    );
                    if (result == true) {
                      ref.read(bannersProvider.notifier).refresh();
                    }
                  },
                  onToggle: () {
                    ref
                        .read(bannersProvider.notifier)
                        .toggleBannerStatus(banner);
                  },
                  onDelete: () => _confirmDelete(context, ref, banner),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(bannersProvider.notifier).refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, AppBanner banner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la bannière'),
        content: Text('Voulez-vous supprimer "${banner.title ?? 'cette bannière'}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(bannersProvider.notifier).deleteBanner(banner.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bannière supprimée')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _BannerTile extends StatelessWidget {
  final AppBanner banner;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _BannerTile({
    super.key,
    required this.banner,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aperçu image
          SizedBox(
            height: 120,
            width: double.infinity,
            child: Image.network(
              banner.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (banner.title != null && banner.title!.isNotEmpty)
                        Text(
                          banner.title!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: banner.isActive
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              banner.isActive ? 'Actif' : 'Inactif',
                              style: TextStyle(
                                fontSize: 12,
                                color: banner.isActive
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ordre: ${banner.displayOrder}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Switch(
                  value: banner.isActive,
                  onChanged: (_) => onToggle(),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
