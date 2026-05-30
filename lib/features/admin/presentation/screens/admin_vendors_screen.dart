import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_vendors_service.dart';
import '../providers/admin_vendors_provider.dart';

/// LIL-128 : écran admin pour gérer les vendeurs marketplace.
/// 2 tabs : "À valider" (queue d'approbation) et "Tous" (recherche/filtrage).
/// Actions : approve (vendeur pending) ou suspend (vendeur actif).
class AdminVendorsScreen extends ConsumerStatefulWidget {
  const AdminVendorsScreen({super.key});

  @override
  ConsumerState<AdminVendorsScreen> createState() => _AdminVendorsScreenState();
}

class _AdminVendorsScreenState extends ConsumerState<AdminVendorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approve(AdminVendorItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver ce vendeur ?'),
        content: Text(
          'Le vendeur "${item.restaurant.name}" sera visible publiquement sur '
          'la marketplace et pourra recevoir des commandes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref
          .read(adminVendorsListProvider.notifier)
          .approve(item.restaurant.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vendeur "${item.restaurant.name}" approuvé.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _suspend(AdminVendorItem item) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspendre ce vendeur ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le vendeur "${item.restaurant.name}" sera invisible pour les '
              'clients (isActive=false). Réversible.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Raison (obligatoire)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final r = reasonCtrl.text.trim();
              if (r.isEmpty) return;
              Navigator.pop(ctx, r);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspendre'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await ref
          .read(adminVendorsListProvider.notifier)
          .suspend(item.restaurant.id, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vendeur "${item.restaurant.name}" suspendu.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(adminPendingVendorsProvider);
    final allAsync = ref.watch(adminVendorsListProvider);

    final pendingCount = pendingAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendeurs marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adminVendorsListProvider);
              ref.invalidate(adminPendingVendorsProvider);
            },
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('À valider'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pendingCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Tous'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _VendorList(
            asyncList: pendingAsync,
            emptyMessage: 'Aucun vendeur en attente d\'approbation.',
            onApprove: _approve,
            onSuspend: null, // pas de suspend dans la queue pending
          ),
          _VendorList(
            asyncList: allAsync,
            emptyMessage: 'Aucun vendeur sur la marketplace.',
            onApprove: _approve,
            onSuspend: _suspend,
          ),
        ],
      ),
    );
  }
}

class _VendorList extends StatelessWidget {
  final AsyncValue<List<AdminVendorItem>> asyncList;
  final String emptyMessage;
  final void Function(AdminVendorItem)? onApprove;
  final void Function(AdminVendorItem)? onSuspend;

  const _VendorList({
    required this.asyncList,
    required this.emptyMessage,
    this.onApprove,
    this.onSuspend,
  });

  @override
  Widget build(BuildContext context) {
    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Erreur : $e',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (vendors) {
        if (vendors.isEmpty) {
          return Center(
            child: Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: vendors.length,
          itemBuilder: (_, i) => _VendorCard(
            item: vendors[i],
            onApprove: onApprove,
            onSuspend: onSuspend,
          ),
        );
      },
    );
  }
}

class _VendorCard extends StatelessWidget {
  final AdminVendorItem item;
  final void Function(AdminVendorItem)? onApprove;
  final void Function(AdminVendorItem)? onSuspend;

  const _VendorCard({
    required this.item,
    this.onApprove,
    this.onSuspend,
  });

  @override
  Widget build(BuildContext context) {
    final r = item.restaurant;
    final pending = !r.adminApproved;
    final suspended = r.adminApproved && !r.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(r.vendorType.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.vendorType.label,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(pending: pending, suspended: suspended),
              ],
            ),
            const SizedBox(height: 10),
            if (item.ownerName != null || item.ownerEmail != null) ...[
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      [
                        if (item.ownerName != null) item.ownerName!,
                        if (item.ownerEmail != null) item.ownerEmail!,
                      ].join(' · '),
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    r.address,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _MetaPill(
                  icon: Icons.inventory_2_outlined,
                  label: '${item.productCount} produits',
                ),
                const SizedBox(width: 6),
                _MetaPill(
                  icon: Icons.receipt_long_outlined,
                  label: '${item.orderCount} cmd',
                ),
                if (r.acceptsPreorders) ...[
                  const SizedBox(width: 6),
                  const _MetaPill(
                    icon: Icons.event_note_outlined,
                    label: 'Pré-commande',
                    color: Colors.orange,
                  ),
                ],
              ],
            ),
            if (onApprove != null || onSuspend != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (pending && onApprove != null) ...[
                    FilledButton.icon(
                      onPressed: () => onApprove!(item),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                  if (!pending && r.isActive && onSuspend != null) ...[
                    OutlinedButton.icon(
                      onPressed: () => onSuspend!(item),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Suspendre'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool pending;
  final bool suspended;

  const _StatusBadge({required this.pending, required this.suspended});

  @override
  Widget build(BuildContext context) {
    if (pending) {
      return _pill('À valider', Colors.orange);
    }
    if (suspended) {
      return _pill('Suspendu', Colors.red);
    }
    return _pill('Actif', Colors.green);
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MetaPill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[700]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
