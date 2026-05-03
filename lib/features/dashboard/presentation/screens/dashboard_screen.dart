import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/user_sync_provider.dart';
import '../../../../models/role.dart';
import '../providers/dashboard_provider.dart';
import '../../data/dashboard_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(dashboardOverviewProvider);
    final userProfile = ref.watch(currentUserProfileProvider);
    final isAdmin = userProfile?.role == Role.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Tableau de bord global' : 'Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dashboardOverviewProvider);
              ref.invalidate(topProductsProvider);
              ref.invalidate(clientStatsProvider);
              if (isAdmin) ref.invalidate(restaurantRankingProvider);
            },
          ),
        ],
      ),
      body: overviewAsync.when(
        data: (overview) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardOverviewProvider);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCards(overview, isAdmin: isAdmin),
                const SizedBox(height: 24),
                _buildRevenueSection(overview),
                const SizedBox(height: 24),
                _buildOrdersSection(overview),
                const SizedBox(height: 24),
                if (isAdmin) ...[
                  const _RestaurantRankingSection(),
                  const SizedBox(height: 24),
                ],
                _TopProductsSection(),
                const SizedBox(height: 24),
                _ClientStatsSection(),
              ],
            ),
          ),
        ),
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
                onPressed: () => ref.invalidate(dashboardOverviewProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(DashboardOverview overview, {bool isAdmin = false}) {
    final cards = <Widget>[
      _StatCard(
        title: 'Commandes du jour',
        value: '${overview.orders.today}',
        subtitle: '${overview.orders.pending} en attente',
        icon: Icons.shopping_bag,
        color: Colors.blue,
      ),
      _StatCard(
        title: 'Revenus du jour',
        value: _formatCurrency(overview.revenue.today),
        subtitle: 'FCFA',
        icon: Icons.attach_money,
        color: Colors.green,
      ),
      _StatCard(
        title: 'Total clients',
        value: '${overview.totalClients}',
        subtitle: 'clients uniques',
        icon: Icons.people,
        color: Colors.orange,
      ),
      if (isAdmin && overview.totalRestaurants != null)
        _StatCard(
          title: 'Restaurants',
          value: '${overview.totalRestaurants}',
          subtitle: 'sur la plateforme',
          icon: Icons.restaurant,
          color: Colors.purple,
        )
      else
        _StatCard(
          title: 'Note moyenne',
          value: overview.rating.average.toStringAsFixed(1),
          subtitle: '${overview.rating.count} avis',
          icon: Icons.star,
          color: Colors.amber,
        ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: cards,
    );
  }

  Widget _buildRevenueSection(DashboardOverview overview) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenus',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _RevenueItem(
                    label: "Aujourd'hui",
                    amount: overview.revenue.today,
                  ),
                ),
                Expanded(
                  child: _RevenueItem(
                    label: 'Cette semaine',
                    amount: overview.revenue.week,
                  ),
                ),
                Expanded(
                  child: _RevenueItem(
                    label: 'Ce mois',
                    amount: overview.revenue.month,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total général',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  _formatCurrency(overview.revenue.total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersSection(DashboardOverview overview) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commandes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OrderItem(
                    label: "Aujourd'hui",
                    count: overview.orders.today,
                  ),
                ),
                Expanded(
                  child: _OrderItem(
                    label: 'Cette semaine',
                    count: overview.orders.week,
                  ),
                ),
                Expanded(
                  child: _OrderItem(
                    label: 'Ce mois',
                    count: overview.orders.month,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text(
                    '${overview.orders.pending} commande(s) en attente',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} FCFA';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueItem extends StatelessWidget {
  final String label;
  final double amount;

  const _RevenueItem({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          formatter.format(amount),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'FCFA',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}

class _OrderItem extends StatelessWidget {
  final String label;
  final int count;

  const _OrderItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'commandes',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}

class _TopProductsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topProductsAsync = ref.watch(topProductsProvider(limit: 5));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Produits les plus vendus',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            topProductsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Aucune donnée disponible'),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text(
                          '${product.rank}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      title: Text(product.product?.name ?? 'Produit inconnu'),
                      subtitle: Text('${product.totalSold} vendus'),
                      trailing: Text(
                        '${NumberFormat('#,###', 'fr_FR').format(product.totalRevenue)} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Erreur de chargement'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantRankingSection extends ConsumerWidget {
  const _RestaurantRankingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(restaurantRankingProvider());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Classement des restaurants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            rankingAsync.when(
              data: (rankings) {
                if (rankings.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Aucun restaurant'),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rankings.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final r = rankings[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: index < 3
                            ? Colors.amber.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: index < 3 ? Colors.amber[800] : Colors.grey,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(r.nom)),
                          if (!r.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Inactif',
                                style: TextStyle(fontSize: 10, color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text('${r.orderCount} commandes'),
                      trailing: Text(
                        '${NumberFormat('#,###', 'fr_FR').format(r.totalRevenue)} F',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Erreur de chargement'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientStatsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientStatsAsync = ref.watch(clientStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques clients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            clientStatsAsync.when(
              data: (stats) {
                final growthValue = double.tryParse(stats.growth) ?? 0;
                final isPositiveGrowth = growthValue >= 0;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ClientStatItem(
                            label: 'Ce mois',
                            value: '${stats.thisMonth.total}',
                            icon: Icons.people,
                          ),
                        ),
                        Expanded(
                          child: _ClientStatItem(
                            label: 'Nouveaux',
                            value: '${stats.thisMonth.newClients}',
                            icon: Icons.person_add,
                          ),
                        ),
                        Expanded(
                          child: _ClientStatItem(
                            label: 'Fidèles',
                            value: '${stats.thisMonth.returning}',
                            icon: Icons.favorite,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPositiveGrowth
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPositiveGrowth
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: isPositiveGrowth ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${isPositiveGrowth ? '+' : ''}${stats.growth}% par rapport au mois dernier',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isPositiveGrowth ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Erreur de chargement'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ClientStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
