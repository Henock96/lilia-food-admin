import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/zones_provider.dart';
import '../../data/zones_service.dart';

class ZonesScreen extends ConsumerWidget {
  const ZonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(deliveryZonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zones de livraison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(deliveryZonesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: zonesAsync.when(
        data: (data) => _ZonesContent(data: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(deliveryZonesProvider.notifier).refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateZoneDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle zone'),
      ),
    );
  }

  void _showCreateZoneDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CreateZoneDialog(),
    );
  }
}

class _ZonesContent extends ConsumerWidget {
  final DeliveryZonesData data;

  const _ZonesContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat('#,###', 'fr_FR');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info sur le mode de livraison
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        data.deliveryPriceMode == 'ZONE_BASED'
                            ? Icons.map
                            : Icons.attach_money,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.deliveryPriceMode == 'ZONE_BASED'
                                  ? 'Mode: Tarification par zone'
                                  : 'Mode: Prix fixe',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (data.deliveryPriceMode == 'FIXED')
                              Text(
                                'Prix fixe: ${formatter.format(data.fixedDeliveryFee)} FCFA',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (data.deliveryPriceMode == 'FIXED') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Activez le mode "Zone" dans les paramètres de livraison pour utiliser les zones personnalisées.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Liste des zones
          Text(
            'Zones configurées (${data.zones.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (data.zones.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune zone de livraison configurée',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Créez des zones pour définir des tarifs différents selon les quartiers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...data.zones.map((zone) => _ZoneCard(zone: zone)),
        ],
      ),
    );
  }
}

class _ZoneCard extends ConsumerWidget {
  final DeliveryZone zone;

  const _ZoneCard({required this.zone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat('#,###', 'fr_FR');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          zone.zoneName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${formatter.format(zone.fee)} FCFA - ${zone.quartiers.length} quartier(s)',
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(Icons.location_on, color: Theme.of(context).primaryColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditZoneDialog(context, ref, zone),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _confirmDelete(context, ref, zone),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quartiers inclus:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                if (zone.quartiers.isEmpty)
                  const Text(
                    'Aucun quartier associé',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: zone.quartiers.map((zq) {
                      return Chip(
                        label: Text(zq.quartier?.nom ?? 'Inconnu'),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditZoneDialog(BuildContext context, WidgetRef ref, DeliveryZone zone) {
    showDialog(
      context: context,
      builder: (context) => _EditZoneDialog(zone: zone),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, DeliveryZone zone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la zone ?'),
        content: Text('Voulez-vous vraiment supprimer la zone "${zone.zoneName}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(deliveryZonesProvider.notifier).deleteZone(zone.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zone supprimée')),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _CreateZoneDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateZoneDialog> createState() => _CreateZoneDialogState();
}

class _CreateZoneDialogState extends ConsumerState<_CreateZoneDialog> {
  final _nameController = TextEditingController();
  final _feeController = TextEditingController(text: '500');
  final Set<String> _selectedQuartierIds = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quartiersAsync = ref.watch(allQuartiersProvider);

    return AlertDialog(
      title: const Text('Nouvelle zone de livraison'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la zone',
                  hintText: 'Ex: Zone 1, Centre-ville...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _feeController,
                decoration: const InputDecoration(
                  labelText: 'Frais de livraison (FCFA)',
                  border: OutlineInputBorder(),
                  suffixText: 'FCFA',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text(
                'Quartiers à inclure:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              quartiersAsync.when(
                data: (quartiers) => SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: quartiers.length,
                    itemBuilder: (context, index) {
                      final quartier = quartiers[index];
                      return CheckboxListTile(
                        title: Text(quartier.nom),
                        value: _selectedQuartierIds.contains(quartier.id),
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedQuartierIds.add(quartier.id);
                            } else {
                              _selectedQuartierIds.remove(quartier.id);
                            }
                          });
                        },
                        dense: true,
                      );
                    },
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Text('Erreur de chargement'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createZone,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Créer'),
        ),
      ],
    );
  }

  Future<void> _createZone() async {
    final name = _nameController.text.trim();
    final fee = double.tryParse(_feeController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom de zone')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(deliveryZonesProvider.notifier).createZone(
            name,
            fee,
            _selectedQuartierIds.toList(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zone créée avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _EditZoneDialog extends ConsumerStatefulWidget {
  final DeliveryZone zone;

  const _EditZoneDialog({required this.zone});

  @override
  ConsumerState<_EditZoneDialog> createState() => _EditZoneDialogState();
}

class _EditZoneDialogState extends ConsumerState<_EditZoneDialog> {
  late TextEditingController _nameController;
  late TextEditingController _feeController;
  late Set<String> _selectedQuartierIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.zone.zoneName);
    _feeController = TextEditingController(text: widget.zone.fee.toStringAsFixed(0));
    _selectedQuartierIds = widget.zone.quartiers.map((q) => q.quartierId).toSet();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quartiersAsync = ref.watch(allQuartiersProvider);

    return AlertDialog(
      title: const Text('Modifier la zone'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la zone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _feeController,
                decoration: const InputDecoration(
                  labelText: 'Frais de livraison (FCFA)',
                  border: OutlineInputBorder(),
                  suffixText: 'FCFA',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text(
                'Quartiers à inclure:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              quartiersAsync.when(
                data: (quartiers) => SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: quartiers.length,
                    itemBuilder: (context, index) {
                      final quartier = quartiers[index];
                      return CheckboxListTile(
                        title: Text(quartier.nom),
                        value: _selectedQuartierIds.contains(quartier.id),
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedQuartierIds.add(quartier.id);
                            } else {
                              _selectedQuartierIds.remove(quartier.id);
                            }
                          });
                        },
                        dense: true,
                      );
                    },
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Text('Erreur de chargement'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateZone,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _updateZone() async {
    final name = _nameController.text.trim();
    final fee = double.tryParse(_feeController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom de zone')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(deliveryZonesProvider.notifier).updateZone(
            widget.zone.id,
            zoneName: name,
            fee: fee,
            quartierIds: _selectedQuartierIds.toList(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zone mise à jour')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
