import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lilia_admin/core/utils/currency.dart';
import 'package:lilia_admin/core/utils/date_format.dart';
import '../../../../models/order.dart';
import '../../../../services/admin_tracking_socket_service.dart';
import '../../data/order_controller.dart';
import '../../data/order_service.dart';

class RestaurantOrdersScreen extends ConsumerStatefulWidget {
  const RestaurantOrdersScreen({super.key});

  @override
  ConsumerState<RestaurantOrdersScreen> createState() =>
      _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState extends ConsumerState<RestaurantOrdersScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  StreamSubscription<AdminOrderStatusEvent>? _wsSubscription;

  /// LIL-125 : filtre transverse "Pré-commandes du jour" (Brazzaville UTC+1).
  /// S'applique avant le filtre par statut, pour aider le restaurateur à voir
  /// les commandes à préparer aujourd'hui en priorité.
  bool _todayOnly = false;

  /// Recherche libre, appliquée par le serveur sur tout l'historique.
  ///
  /// Deux états : ce qui est tapé, et ce qui est envoyé. Sans le second, chaque
  /// frappe créerait une instance de provider — donc une requête — aussitôt
  /// jetée. 350 ms, comme les écrans Clients et Livreurs.
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _search = '';

  /// Statuts considérés "actifs" — on s'abonne en WebSocket à chaque
  /// commande dans l'un de ces états. LIVRER et ANNULER sont terminaux,
  /// pas de mise à jour à attendre.
  static const Set<OrderStatus> _activeStatuses = {
    OrderStatus.enattente,
    OrderStatus.payer,
    OrderStatus.enpreparation,
    OrderStatus.pret,
    OrderStatus.enRoute,
  };

  final List<OrderStatus?> _filterStatuses = [
    null, // Toutes
    OrderStatus.enattente,
    OrderStatus.payer,
    OrderStatus.enpreparation,
    OrderStatus.pret,
    OrderStatus.enRoute,
    OrderStatus.livrer,
    OrderStatus.annuler,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterStatuses.length, vsync: this);
    WidgetsBinding.instance.addObserver(this);

    // Abonnement WebSocket aux events `order:status`. Quand un event arrive,
    // on invalide `restaurantOrdersProvider` → la liste se rafraîchit toute
    // seule, plus besoin de pull-to-refresh (LIL-77).
    _wsSubscription = ref
        .read(adminTrackingSocketServiceProvider)
        .events
        .listen((_) {
      if (!mounted) return;
      ref.invalidate(restaurantOrdersProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wsSubscription?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || _search == value.trim()) return;
      setState(() => _search = value.trim());
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _search = '');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final socket = ref.read(adminTrackingSocketServiceProvider);
    if (state == AppLifecycleState.resumed) {
      // Retour foreground → reconnecter et re-watch les commandes actives.
      // `reconnect()` rafraîchit aussi le token Firebase si nécessaire.
      socket.reconnect();
    } else if (state == AppLifecycleState.paused) {
      // App backgroundée → on coupe pour économiser la batterie. Les events
      // ratés seront rattrapés par le refetch au resume + FCM en fallback.
      socket.disconnect();
    }
  }

  /// Abonne le socket aux commandes actives chaque fois que la liste
  /// arrive ou change. Le diff interne du service évite les doublons.
  void _syncSocketSubscriptions(List<Order> orders) {
    final activeIds = orders
        .where((o) => _activeStatuses.contains(o.status))
        .map((o) => o.id)
        .toList(growable: false);
    if (activeIds.isEmpty) return;
    unawaited(
      ref
          .read(adminTrackingSocketServiceProvider)
          .subscribeToOrders(activeIds),
    );
  }

  String _getTabLabel(OrderStatus? status) {
    if (status == null) return 'Toutes';
    return _getStatusLabel(status);
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.enattente:
        return 'En attente';
      case OrderStatus.payer:
        return 'Payée';
      case OrderStatus.enpreparation:
        return 'En préparation';
      case OrderStatus.pret:
        return 'Prête';
      case OrderStatus.enRoute:
        return 'En route';
      case OrderStatus.livrer:
        return 'Livrée';
      case OrderStatus.annuler:
        return 'Annulée';
      default:
        return 'Inconnu';
    }
  }

  List<Order> _applyTodayFilter(List<Order> orders) {
    if (!_todayOnly) return orders;
    final todayBzv = _brazzavilleDateString(DateTime.now());
    final filtered = orders
        .where((o) =>
            o.isPreorder &&
            o.scheduledFor != null &&
            o.status != OrderStatus.annuler &&
            _brazzavilleDateString(o.scheduledFor!) == todayBzv)
        .toList();
    filtered.sort((a, b) => a.scheduledFor!.compareTo(b.scheduledFor!));
    return filtered;
  }

  /// Compteur d'un onglet, pris dans `meta.statusCounts` — donc calculé par le
  /// serveur sur le périmètre entier. Il était auparavant calculé sur les
  /// vingt lignes reçues : « En attente (2) » pouvait s'afficher pendant que
  /// quarante commandes attendaient.
  int _countByStatus(OrderPage page, OrderStatus? status) {
    if (status == null) {
      return page.statusCounts.values.fold(0, (a, b) => a + b);
    }
    return page.statusCounts[status] ?? 0;
  }

  int _todayPreorderCount(List<Order> orders) {
    final todayBzv = _brazzavilleDateString(DateTime.now());
    return orders
        .where((o) =>
            o.isPreorder &&
            o.scheduledFor != null &&
            o.status != OrderStatus.annuler &&
            _brazzavilleDateString(o.scheduledFor!) == todayBzv)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    // Les compteurs d'onglets viennent de `meta.statusCounts` de l'onglet
    // « Toutes ». Ils portent sur le périmètre entier, donc la barre reste
    // chiffrée même quand on consulte un onglet filtré — et un onglet vide
    // affiche « (0) » au lieu de disparaître.
    final countsState = ref.watch(restaurantOrdersProvider(null, _search));

    final todayPreorderCount = countsState.maybeWhen(
      data: (page) => _todayPreorderCount(page.items),
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Commandes'),
        centerTitle: true,
        actions: [
          if (todayPreorderCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: _todayOnly ? Colors.white : Colors.orange[700],
                  backgroundColor: _todayOnly ? Colors.orange : Colors.orange.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => setState(() => _todayOnly = !_todayOnly),
                icon: const Icon(Icons.event_note_outlined, size: 16),
                // Le compte porte sur la page chargée, faute de filtre serveur
                // sur `scheduledFor` : le libellé le dit plutôt que de laisser
                // croire qu'il balaie tout l'historique.
                label: Text(
                  'Aujourd\'hui ($todayPreorderCount sur cette page)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(restaurantOrdersProvider),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: _OrdersHeader(
          searchController: _searchController,
          onSearchChanged: _onSearchChanged,
          onClearSearch: _clearSearch,
          hasSearch: _search.isNotEmpty,
          tabBar: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _filterStatuses.map((status) {
            final count = countsState.maybeWhen(
              data: (page) => _countByStatus(page, status),
              orElse: () => null,
            );
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getTabLabel(status)),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: status == OrderStatus.enattente && count > 0
                            ? Colors.orange
                            : Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: status == OrderStatus.enattente && count > 0
                              ? Colors.white
                              : Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
            }).toList(),
          ),
        ),
      ),
      // Chaque onglet a sa propre requête, filtrée par le serveur. L'écran
      // chargeait auparavant une seule liste — les vingt dernières commandes
      // de la plateforme — que les sept onglets filtraient en mémoire.
      body: TabBarView(
        controller: _tabController,
        children: _filterStatuses
            .map(
              (status) => _OrdersTab(
                status: status,
                search: _search,
                todayOnly: _todayOnly,
                applyTodayFilter: _applyTodayFilter,
                emptyLabel: _search.isNotEmpty
                    ? 'Aucune commande ne correspond à « $_search »'
                    : status == null
                        ? 'Aucune commande'
                        : 'Aucune commande ${_getStatusLabel(status).toLowerCase()}',
                onOrdersLoaded: _syncSocketSubscriptions,
              ),
            )
            .toList(),
      ),
    );
  }
}

/// En-tête de l'écran : champ de recherche puis onglets de statut.
///
/// Les deux vivent dans le `bottom` de l'`AppBar` parce qu'ils doivent rester
/// visibles pendant que la liste défile — chercher une commande en ayant à
/// remonter d'abord serait un aller-retour de plus à chaque appel client.
///
/// `PreferredSizeWidget` est requis par `AppBar.bottom` : la hauteur doit être
/// annoncée, elle ne peut pas être mesurée.
class _OrdersHeader extends StatelessWidget implements PreferredSizeWidget {
  const _OrdersHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.hasSearch,
    required this.tabBar,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final bool hasSearch;
  final TabBar tabBar;

  static const double _searchFieldHeight = 60;

  @override
  Size get preferredSize =>
      Size.fromHeight(tabBar.preferredSize.height + _searchFieldHeight);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                hintText: 'Numéro, client, téléphone ou vendeur…',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: hasSearch || searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Effacer la recherche',
                        onPressed: onClearSearch,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        tabBar,
      ],
    );
  }
}

/// Contenu d'un onglet : une requête paginée, filtrée par le serveur.
///
/// Séparé de l'écran pour que chaque onglet observe **sa** requête. Un onglet
/// qui filtrerait la liste d'un autre ne montrerait que les commandes de la
/// page reçue, en annonçant qu'il n'y en a pas d'autres.
class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({
    required this.status,
    required this.search,
    required this.todayOnly,
    required this.applyTodayFilter,
    required this.emptyLabel,
    required this.onOrdersLoaded,
  });

  final OrderStatus? status;
  final String search;
  final bool todayOnly;
  final List<Order> Function(List<Order>) applyTodayFilter;
  final String emptyLabel;
  final void Function(List<Order>) onOrdersLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restaurantOrdersProvider(status, search));

    ref.listen<AsyncValue<OrderPage>>(restaurantOrdersProvider(status, search), (
      _,
      next,
    ) {
      next.whenData((page) => onOrdersLoaded(page.items));
    });

    return state.when(
      data: (page) {
        final orders = applyTodayFilter(page.items);

        if (orders.isEmpty) {
          return _TabEmptyState(
            todayOnly: todayOnly,
            label: todayOnly
                ? 'Aucune pré-commande programmée pour aujourd\'hui sur cette page'
                : emptyLabel,
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(restaurantOrdersProvider(status, search).future),
          child: ListView.builder(
            padding: const EdgeInsets.all(12.0),
            // +1 pour le pied de liste : compte serveur et bouton « charger
            // plus ». Il porte l'information qui manquait — combien de
            // commandes existent au-delà de celles affichées.
            itemCount: orders.length + 1,
            itemBuilder: (context, index) {
              if (index < orders.length) {
                return OrderCard(order: orders[index]);
              }
              return _OrdersFooter(
                page: page,
                shown: orders.length,
                // Le filtre local du jour masque une partie de la page :
                // proposer « charger plus » chargerait des commandes qu'il
                // masquerait aussi. On affiche alors le seul décompte.
                onLoadMore: todayOnly
                    ? null
                    : () => ref
                        .read(restaurantOrdersProvider(status, search).notifier)
                        .loadMore(),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorState(
        error: error.toString(),
        onRetry: () => ref.invalidate(restaurantOrdersProvider(status, search)),
      ),
    );
  }
}

/// Pied de liste : ce que le serveur dit du reste.
class _OrdersFooter extends StatefulWidget {
  const _OrdersFooter({
    required this.page,
    required this.shown,
    required this.onLoadMore,
  });

  final OrderPage page;
  final int shown;
  final Future<void> Function()? onLoadMore;

  @override
  State<_OrdersFooter> createState() => _OrdersFooterState();
}

class _OrdersFooterState extends State<_OrdersFooter> {
  bool _loading = false;

  Future<void> _load() async {
    final callback = widget.onLoadMore;
    if (callback == null || _loading) return;
    setState(() => _loading = true);
    try {
      await callback();
    } catch (e) {
      // L'échec est rapporté ici, où le geste a eu lieu. Le contrôleur, lui,
      // a conservé la liste déjà affichée : une page suivante qui n'arrive pas
      // ne doit pas effacer les commandes qu'on est en train de lire.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de charger la suite : $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final total = page.total;
    final canLoadMore = page.hasMore && widget.onLoadMore != null;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        children: [
          Text(
            '${widget.shown} affichée${widget.shown > 1 ? 's' : ''} '
            'sur $total commande${total > 1 ? 's' : ''}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (canLoadMore) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loading ? null : _load,
              icon: _loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more, size: 18),
              label: Text(_loading ? 'Chargement…' : 'Charger plus'),
            ),
          ],
        ],
      ),
    );
  }
}

/// État vide d'un onglet.
class _TabEmptyState extends StatelessWidget {
  const _TabEmptyState({required this.todayOnly, required this.label});

  final bool todayOnly;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            todayOnly ? Icons.event_note_outlined : Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
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

/// LIL-125 : conversion d'un DateTime en clé `YYYY-MM-DD` dans le fuseau
/// Brazzaville (UTC+1, pas de DST). Approche simple : on convertit en UTC
/// puis on ajoute 1h. Évite de dépendre d'`Intl` pour ce cas trivial.
String _brazzavilleDateString(DateTime dt) {
  final bzv = toBrazzaville(dt);
  final m = bzv.month.toString().padLeft(2, '0');
  final d = bzv.day.toString().padLeft(2, '0');
  return '${bzv.year}-$m-$d';
}

/// LIL-125 : format compact pour les badges, ex "30 mai à 14:30".
String _formatScheduledShort(DateTime dt) {
  final bzv = toBrazzaville(dt);
  final day = DateFormat('d MMM', 'fr_FR').format(bzv);
  final time = DateFormat('HH:mm').format(bzv);
  return '$day à $time';
}

class OrderCard extends ConsumerWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusInfo = _getStatusInfo(order.status);

    return GestureDetector(
      onTap: () {
        context.goNamed(
          'order-detail',
          pathParameters: {'id': order.id},
          extra: order,
        );
      },
      child: Card(
        elevation: 2.0,
        margin: const EdgeInsets.only(bottom: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: statusInfo.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusInfo.color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(statusInfo.icon, color: statusInfo.color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    statusInfo.label,
                    style: TextStyle(
                      color: statusInfo.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Bouton suivi carte — visible uniquement pour les commandes
                  // EN_ROUTE (livreur en transit). Permet à l'admin d'ouvrir
                  // l'écran de tracking temps réel sans passer par le détail.
                  if (order.status == OrderStatus.enRoute) ...[
                    SizedBox(
                      height: 28,
                      width: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        tooltip: 'Suivre sur la carte',
                        icon: Icon(Icons.map_outlined,
                            color: statusInfo.color),
                        onPressed: () => context.push(
                          '/deliveries/${order.id}/tracking',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '#${order.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du client
                  if (order.customerName != null ||
                      order.customerPhone != null) ...[
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.blue[400]),
                        const SizedBox(width: 4),
                        Text(
                          order.customerName ?? 'Client',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (order.customerPhone != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.phone, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 2),
                          Text(
                            order.customerPhone!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Nom du restaurant (pour ADMIN)
                  if (order.restaurantName != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 16,
                          color: Colors.purple[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.restaurantName!,
                          style: TextStyle(
                            color: Colors.purple[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // LIL-125 : badge pré-commande au-dessus de la date — bien
                  // visible pour rappeler le créneau de retrait au restaurateur.
                  if (order.isPreorder && order.scheduledFor != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_note_outlined,
                            size: 16,
                            color: Colors.orange[800],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Programmée pour ',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatScheduledShort(order.scheduledFor!),
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Date et montant
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatBrazzavilleDateTime(order.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          formatXaf(order.total),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Adresse de livraison
                  if (order.deliveryAddress.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.deliveryAddress,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Notes de commande
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.notes!,
                              style: TextStyle(
                                color: Colors.amber[900],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Liste des articles
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${item.quantite}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${(item.prix * item.quantite).toStringAsFixed(0)} F',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section changement de statut
                  _buildStatusChangeSection(context, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChangeSection(BuildContext context, WidgetRef ref) {
    // Statuts terminaux - pas de changement possible
    if (order.status == OrderStatus.livrer ||
        order.status == OrderStatus.annuler) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              order.status == OrderStatus.livrer
                  ? Icons.check_circle
                  : Icons.cancel,
              color: order.status == OrderStatus.livrer
                  ? Colors.green
                  : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              order.status == OrderStatus.livrer
                  ? 'Commande livrée avec succès'
                  : 'Commande annulée',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Changer le statut :',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _getAvailableStatuses(order.status).map((status) {
            final info = _getStatusInfo(status);
            return _StatusButton(
              label: info.label,
              icon: info.icon,
              color: info.color,
              onPressed: () => _updateStatus(context, ref, status),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    OrderStatus status,
  ) async {
    // Confirmation pour annulation
    if (status == OrderStatus.annuler) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Annuler la commande ?'),
          content: const Text(
            'Cette action est irréversible. Le client sera notifié.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Oui, annuler'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      await ref
          .read(restaurantOrdersProvider(null, '').notifier)
          .updateOrderStatus(order.id, status);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Statut mis à jour: ${_getStatusInfo(status).label}'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Rafraîchir la liste
        ref.invalidate(restaurantOrdersProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  List<OrderStatus> _getAvailableStatuses(OrderStatus current) {
    switch (current) {
      case OrderStatus.enattente:
        return [
          OrderStatus.enpreparation,
          OrderStatus.payer,
          OrderStatus.annuler,
        ];
      case OrderStatus.payer:
        return [OrderStatus.enpreparation, OrderStatus.annuler];
      case OrderStatus.enpreparation:
        return [OrderStatus.pret, OrderStatus.annuler];
      case OrderStatus.pret:
        return [OrderStatus.livrer, OrderStatus.annuler];
      default:
        return [];
    }
  }

  _StatusInfo _getStatusInfo(OrderStatus status) {
    switch (status) {
      case OrderStatus.enattente:
        return _StatusInfo(
          label: 'En attente',
          color: Colors.orange,
          icon: Icons.hourglass_empty,
        );
      case OrderStatus.payer:
        return _StatusInfo(
          label: 'Payée',
          color: Colors.blue,
          icon: Icons.payment,
        );
      case OrderStatus.enpreparation:
        return _StatusInfo(
          label: 'En préparation',
          color: Colors.indigo,
          icon: Icons.restaurant,
        );
      case OrderStatus.pret:
        return _StatusInfo(
          label: 'Prête',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      case OrderStatus.livrer:
        return _StatusInfo(
          label: 'Livrée',
          color: Colors.teal,
          icon: Icons.local_shipping,
        );
      case OrderStatus.annuler:
        return _StatusInfo(
          label: 'Annuler',
          color: Colors.red,
          icon: Icons.cancel,
        );
      default:
        return _StatusInfo(
          label: 'Inconnu',
          color: Colors.grey,
          icon: Icons.help_outline,
        );
    }
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  _StatusInfo({required this.label, required this.color, required this.icon});
}
