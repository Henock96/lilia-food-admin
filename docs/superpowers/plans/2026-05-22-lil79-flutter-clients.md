# LIL-79 Admin Flutter — Fidélité, parrainage & liste clients — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rendre visibles, dans l'app admin Flutter (`lilia-food-admin`), les points de fidélité et le parrainage d'un client dans sa fiche détail, et passer la liste clients en recherche + pagination côté serveur.

**Architecture:** App Flutter + Riverpod (code generation). Les données viennent des endpoints backend LIL-79 (`GET /admin/clients`, `/admin/clients/:id/loyalty`, `/admin/clients/:id/referral`). Modèles dans `lib/models/`, appels HTTP dans `ClientRepository`, providers `@riverpod` dans `lib/features/clients/presentation/providers/`, écrans dans `presentation/screens/`.

**Tech Stack:** Flutter, Riverpod + `riverpod_annotation` (code gen), package `http`, `go_router`, `intl`. Vérification : `flutter analyze` + `dart run build_runner build --delete-conflicting-outputs`.

**Périmètre :** Chantiers 1, 2, 3 du ticket LIL-79 (volet Flutter). Le chantier 4 (écrans Paiements et Livreurs) fera l'objet d'un plan distinct.

**Prérequis :** Les endpoints backend LIL-79 doivent être déployés sur `https://lilia-backend.onrender.com` pour la vérification sur appareil/émulateur.

---

## Contexte du code existant

- `ClientRepository` (`lib/features/clients/data/client_repository.dart`) : appels HTTP bruts via `package:http`, token Firebase, `_baseUrl = "https://lilia-backend.onrender.com"`. Méthodes actuelles : `fetchClients(restaurantId)`, `fetchAllClients()`.
- **`fetchAllClients()` appelle `/admin/clients` sans paramètre** → le backend renvoie la page 1 (limite 20). L'app ne voit donc que 20 clients aujourd'hui, et la recherche de `clients_screen.dart` ne filtre que ces 20 en local.
- Providers `@riverpod` dans `clients_provider.dart` : `clientRepositoryProvider`, `restaurantClientsProvider`, `allClientsProvider`. Après toute modif d'un `@riverpod`, lancer `dart run build_runner build --delete-conflicting-outputs`.
- `AppUser` (`lib/models/app_user.dart`) : `id, email, nom?, phone?, imageUrl?, role, createdAt`, `fromJson` écrit à la main, getter `initials`. Pas de `loyaltyPoints`.
- `ClientsScreen` (`ConsumerStatefulWidget`) : recherche locale (`_filterClients`), ouvre `client-detail` via `context.goNamed`.
- `ClientDetailScreen` (`ConsumerWidget`) : reçoit un `AppUser client`, affiche header + stats commandes + historique. Watch `userOrdersProvider(clientId)`. Pas de section fidélité/parrainage.
- Réponses backend : `/admin/clients` → `{ data: [...], total, page, limit }` ; `/admin/clients/:id/loyalty` → `{ data: { balance, transactions }, total, page, limit }` ; `/admin/clients/:id/referral` → `{ data: {...} }`.

---

## File Structure

| Fichier | Rôle | Action |
|---|---|---|
| `lib/models/app_user.dart` | Ajout `loyaltyPoints` | Modifier |
| `lib/models/client_loyalty.dart` | Modèles fidélité | Créer |
| `lib/models/client_referral.dart` | Modèle parrainage | Créer |
| `lib/models/paginated_clients.dart` | Enveloppe paginée clients | Créer |
| `lib/features/clients/data/client_repository.dart` | 3 appels HTTP | Modifier |
| `lib/features/clients/presentation/providers/clients_provider.dart` | Providers | Modifier |
| `lib/features/clients/presentation/screens/client_detail_screen.dart` | Sections fidélité + parrainage | Modifier |
| `lib/features/clients/presentation/screens/clients_screen.dart` | Recherche + pagination serveur | Modifier |

---

## Task 1: Modèles

**Files:**
- Modify: `lib/models/app_user.dart`
- Create: `lib/models/client_loyalty.dart`, `lib/models/client_referral.dart`, `lib/models/paginated_clients.dart`

- [ ] **Step 1: Ajouter `loyaltyPoints` à `AppUser`**

Dans `lib/models/app_user.dart` : ajouter le champ, le paramètre du constructeur, et le parsing.

- Champ : après `final DateTime createdAt;` ajouter `final int loyaltyPoints;`
- Constructeur : après `required this.createdAt,` ajouter `this.loyaltyPoints = 0,`
- `fromJson` : dans l'objet retourné, après `createdAt: ...,` ajouter `loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,`

- [ ] **Step 2: Créer `client_loyalty.dart`**

```dart
/// Une transaction de fidélité d'un client.
class ClientLoyaltyTransaction {
  final String id;
  final int points;
  final String reason;
  final String? orderId;
  final DateTime createdAt;

  ClientLoyaltyTransaction({
    required this.id,
    required this.points,
    required this.reason,
    this.orderId,
    required this.createdAt,
  });

  factory ClientLoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return ClientLoyaltyTransaction(
      id: json['id'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      orderId: json['orderId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Solde + historique de fidélité d'un client (GET /admin/clients/:id/loyalty).
class ClientLoyalty {
  final int balance;
  final List<ClientLoyaltyTransaction> transactions;

  ClientLoyalty({required this.balance, required this.transactions});

  /// Parse l'objet `data` de la réponse : `{ balance, transactions }`.
  factory ClientLoyalty.fromJson(Map<String, dynamic> json) {
    final txns = json['transactions'] as List<dynamic>? ?? [];
    return ClientLoyalty(
      balance: json['balance'] as int? ?? 0,
      transactions: txns
          .map((t) => ClientLoyaltyTransaction.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

- [ ] **Step 3: Créer `client_referral.dart`**

```dart
/// Statistiques de parrainage d'un client (GET /admin/clients/:id/referral).
class ClientReferral {
  final String? referralCode;
  final String? referredByCode;
  final int totalReferrals;
  final int convertedReferrals;
  final int referralBonusEarned;

  ClientReferral({
    this.referralCode,
    this.referredByCode,
    required this.totalReferrals,
    required this.convertedReferrals,
    required this.referralBonusEarned,
  });

  /// Parse l'objet `data` de la réponse.
  factory ClientReferral.fromJson(Map<String, dynamic> json) {
    return ClientReferral(
      referralCode: json['referralCode'] as String?,
      referredByCode: json['referredByCode'] as String?,
      totalReferrals: json['totalReferrals'] as int? ?? 0,
      convertedReferrals: json['convertedReferrals'] as int? ?? 0,
      referralBonusEarned: json['referralBonusEarned'] as int? ?? 0,
    );
  }
}
```

- [ ] **Step 4: Créer `paginated_clients.dart`**

```dart
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
```

- [ ] **Step 5: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/models/`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/models/app_user.dart lib/models/client_loyalty.dart lib/models/client_referral.dart lib/models/paginated_clients.dart
git commit -m "feat(models): add loyalty, referral and paginated clients models"
```

---

## Task 2: `ClientRepository` — appels fidélité, parrainage, liste paginée

**Files:**
- Modify: `lib/features/clients/data/client_repository.dart`

- [ ] **Step 1: Mettre à jour les imports**

En tête de `client_repository.dart`, après l'import de `app_user.dart`, ajouter :

```dart
import 'package:lilia_admin/models/client_loyalty.dart';
import 'package:lilia_admin/models/client_referral.dart';
import 'package:lilia_admin/models/paginated_clients.dart';
```

- [ ] **Step 2: Remplacer `fetchAllClients` par une version paginée + recherche**

Remplacer intégralement la méthode `fetchAllClients()` par :

```dart
  /// Récupère les clients de la plateforme, paginés et filtrables (ADMIN).
  Future<PaginatedClients> fetchAllClients({int page = 1, String search = ''}) async {
    final token = await _getAuthToken();
    final query = {
      'page': '$page',
      'limit': '20',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    final url = Uri.parse('$_baseUrl/admin/clients').replace(queryParameters: query);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final List<dynamic> clientsData = body['data'] as List<dynamic>? ?? [];
      return PaginatedClients(
        clients: clientsData
            .map((j) => AppUser.fromJson(j as Map<String, dynamic>))
            .toList(),
        total: body['total'] as int? ?? clientsData.length,
        page: body['page'] as int? ?? page,
        limit: body['limit'] as int? ?? 20,
      );
    } else {
      throw Exception('Échec du chargement des clients: ${response.statusCode} ${response.body}');
    }
  }

  /// Solde + historique de fidélité d'un client (ADMIN).
  Future<ClientLoyalty> fetchClientLoyalty(String clientId) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/admin/clients/$clientId/loyalty');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ClientLoyalty.fromJson(data);
    } else {
      throw Exception('Échec du chargement de la fidélité: ${response.statusCode} ${response.body}');
    }
  }

  /// Statistiques de parrainage d'un client (ADMIN).
  Future<ClientReferral> fetchClientReferral(String clientId) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/admin/clients/$clientId/referral');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ClientReferral.fromJson(data);
    } else {
      throw Exception('Échec du chargement du parrainage: ${response.statusCode} ${response.body}');
    }
  }
```

`fetchClients(restaurantId)` (clients d'un restaurant) reste inchangée.

- [ ] **Step 3: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/clients/data/`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/clients/data/client_repository.dart
git commit -m "feat(clients): add loyalty, referral repository calls and paginated fetchAllClients"
```

---

## Task 3: Providers Riverpod

**Files:**
- Modify: `lib/features/clients/presentation/providers/clients_provider.dart`

- [ ] **Step 1: Réécrire `clients_provider.dart`**

Remplacer le contenu par :

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lilia_admin/features/clients/data/client_repository.dart';
import 'package:lilia_admin/models/app_user.dart';
import 'package:lilia_admin/models/client_loyalty.dart';
import 'package:lilia_admin/models/client_referral.dart';
import 'package:lilia_admin/models/paginated_clients.dart';

part 'clients_provider.g.dart';

@riverpod
ClientRepository clientRepository(Ref ref) {
  return ClientRepository();
}

/// Clients d'un restaurant (vue restaurateur).
@riverpod
Future<List<AppUser>> restaurantClients(Ref ref, String restaurantId) {
  return ref.watch(clientRepositoryProvider).fetchClients(restaurantId);
}

/// Tous les clients de la plateforme — paginés et filtrables (ADMIN).
@riverpod
Future<PaginatedClients> allClients(
  Ref ref, {
  required int page,
  required String search,
}) {
  return ref.watch(clientRepositoryProvider).fetchAllClients(page: page, search: search);
}

/// Fidélité d'un client (ADMIN).
@riverpod
Future<ClientLoyalty> clientLoyalty(Ref ref, String clientId) {
  return ref.watch(clientRepositoryProvider).fetchClientLoyalty(clientId);
}

/// Parrainage d'un client (ADMIN).
@riverpod
Future<ClientReferral> clientReferral(Ref ref, String clientId) {
  return ref.watch(clientRepositoryProvider).fetchClientReferral(clientId);
}
```

- [ ] **Step 2: Régénérer le code Riverpod**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && dart run build_runner build --delete-conflicting-outputs`
Expected: build réussi ; `clients_provider.g.dart` régénéré avec `allClientsProvider` (paramètres `page` + `search`), `clientLoyaltyProvider`, `clientReferralProvider`.

- [ ] **Step 3: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/clients/presentation/providers/`
Expected: `No issues found!` — l'ancien `allClientsProvider` (sans paramètre) n'existe plus, `clients_screen.dart` sera mis à jour à la Task 6.

- [ ] **Step 4: Commit**

```bash
git add lib/features/clients/presentation/providers/clients_provider.dart lib/features/clients/presentation/providers/clients_provider.g.dart
git commit -m "feat(clients): add loyalty/referral providers, paginate allClients provider"
```

---

## Task 4: Section Fidélité dans la fiche client

**Files:**
- Modify: `lib/features/clients/presentation/screens/client_detail_screen.dart`

- [ ] **Step 1: Mettre à jour les imports**

En tête du fichier, ajouter :

```dart
import 'package:lilia_admin/features/clients/presentation/providers/clients_provider.dart';
import 'package:lilia_admin/models/client_loyalty.dart';
```

- [ ] **Step 2: Insérer la section Fidélité dans le `build`**

Dans la méthode `build`, dans la `Column` du `body`, juste après le bloc `_buildOrderStats` et son `Divider`, et avant le `Padding` du titre « Historique des commandes », insérer :

```dart
          _buildLoyaltySection(context, ref, clientId),
          const Divider(height: 1),
```

- [ ] **Step 3: Ajouter la méthode `_buildLoyaltySection`**

Ajouter cette méthode dans la classe `ClientDetailScreen`, après `_buildOrderStats` :

```dart
  Widget _buildLoyaltySection(BuildContext context, WidgetRef ref, String clientId) {
    final loyaltyAsync = ref.watch(clientLoyaltyProvider(clientId));
    return loyaltyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Fidélité indisponible', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ),
      data: (loyalty) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  '${loyalty.balance} point${loyalty.balance > 1 ? 's' : ''} de fidélité',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.amber[800]),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 2),
              child: Text(
                '≈ ${loyalty.balance * 5} FCFA de réduction disponible',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            if (loyalty.transactions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...loyalty.transactions.take(5).map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.reason, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              Text(
                                DateFormat('dd/MM/yyyy').format(t.createdAt),
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${t.points >= 0 ? '+' : ''}${t.points}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: t.points >= 0 ? Colors.green[600] : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 4: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/clients/presentation/screens/client_detail_screen.dart`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/clients/presentation/screens/client_detail_screen.dart
git commit -m "feat(clients): show loyalty balance and history in client detail"
```

---

## Task 5: Section Parrainage dans la fiche client

**Files:**
- Modify: `lib/features/clients/presentation/screens/client_detail_screen.dart`

- [ ] **Step 1: Ajouter l'import**

En tête du fichier, ajouter :

```dart
import 'package:lilia_admin/models/client_referral.dart';
```

- [ ] **Step 2: Insérer la section Parrainage dans le `build`**

Juste après la ligne `_buildLoyaltySection(context, ref, clientId),` et son `Divider` (ajoutés à la Task 4), insérer :

```dart
          _buildReferralSection(context, ref, clientId),
          const Divider(height: 1),
```

- [ ] **Step 3: Ajouter la méthode `_buildReferralSection`**

Ajouter cette méthode dans la classe `ClientDetailScreen`, après `_buildLoyaltySection` :

```dart
  Widget _buildReferralSection(BuildContext context, WidgetRef ref, String clientId) {
    final referralAsync = ref.watch(clientReferralProvider(clientId));
    return referralAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Parrainage indisponible', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ),
      data: (referral) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  referral.referralCode != null
                      ? 'Code parrainage : ${referral.referralCode}'
                      : 'Aucun code de parrainage',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            if (referral.referredByCode != null)
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 2),
                child: Text(
                  'Parrainé via ${referral.referredByCode}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                _referralStat(context, '${referral.totalReferrals}', 'Filleuls', Colors.blue),
                _referralStat(context, '${referral.convertedReferrals}', 'Convertis', Colors.green),
                _referralStat(context, '${referral.referralBonusEarned}', 'Pts gagnés', Colors.amber[700]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _referralStat(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
```

- [ ] **Step 4: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/clients/presentation/screens/client_detail_screen.dart`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/clients/presentation/screens/client_detail_screen.dart
git commit -m "feat(clients): show referral stats in client detail"
```

---

## Task 6: Liste clients — recherche + pagination côté serveur

L'écran admin passe d'un filtrage local (sur 20 clients) à une recherche + pagination serveur. Le chemin restaurateur (`restaurantClientsProvider`, recherche locale) reste inchangé.

**Files:**
- Modify: `lib/features/clients/presentation/screens/clients_screen.dart`

- [ ] **Step 1: Réécrire `clients_screen.dart`**

Remplacer intégralement le contenu du fichier par :

```dart
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
                itemBuilder: (context, index) => _ClientCard(client: result.clients[index]),
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
```

- [ ] **Step 2: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/clients/`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/clients/presentation/screens/clients_screen.dart
git commit -m "feat(clients): server-side search and pagination on admin client list"
```

---

## Task 7: Vérification finale

- [ ] **Step 1: Analyse statique complète**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze`
Expected: aucune nouvelle erreur dans `lib/models/` ou `lib/features/clients/`. (Des avertissements préexistants ailleurs dans le projet sont hors périmètre.)

- [ ] **Step 2: Code generation à jour**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && dart run build_runner build --delete-conflicting-outputs`
Expected: build réussi, aucun changement non commité dans `clients_provider.g.dart` (déjà généré à la Task 3).

- [ ] **Step 3: Vérification manuelle (si le backend est déployé)**

Lancer l'app sur un émulateur, se connecter en ADMIN, ouvrir l'écran Clients :
- La liste se charge page par page ; la recherche interroge le serveur (debounce 350 ms) ; les boutons de pagination fonctionnent.
- Chaque carte affiche le solde de points du client.
- Ouvrir une fiche client → les sections « fidélité » (solde + historique) et « parrainage » (code, filleuls, convertis, points gagnés) s'affichent.
- États chargement / erreur / vide corrects.

Si le backend LIL-79 n'est pas déployé, noter cette étape comme à refaire après déploiement.

---

## Self-Review

**Couverture du périmètre (chantiers 1-3, volet Flutter) :**
- Chantier 1 (Fidélité) : modèles + `fetchClientLoyalty` + `clientLoyaltyProvider` + `_buildLoyaltySection` (Tasks 1-4) ✅
- Chantier 2 (Parrainage) : modèle + `fetchClientReferral` + `clientReferralProvider` + `_buildReferralSection` (Tasks 1-3, 5) ✅
- Chantier 3 (Liste clients) : `fetchAllClients(page, search)` + `allClientsProvider` paginé + `clients_screen.dart` recherche/pagination serveur + `loyaltyPoints` sur la carte (Tasks 1-3, 6) ✅

**Cohérence des types :** `fetchAllClients` → `PaginatedClients` ; `fetchClientLoyalty` → `ClientLoyalty` ; `fetchClientReferral` → `ClientReferral`. `allClientsProvider(page:, search:)` — paramètres nommés cohérents entre la définition (Task 3) et l'appel (`clients_screen.dart`, Task 6). Les `.fromJson` parsent l'objet `data` déballé par le repository.

**Code generation :** toute modif d'un `@riverpod` (Task 3) impose `dart run build_runner build --delete-conflicting-outputs` — fait en Task 3 Step 2, revérifié en Task 7.

**Hors périmètre :** chantier 4 Flutter (écrans Paiements + Livreurs) → plan distinct. Le modèle `Client` (`lib/models/client.dart`) n'est pas utilisé par la feature `clients` (qui s'appuie sur `AppUser`) — laissé tel quel.
