# LIL-79 Admin Flutter — Écrans Paiements, Livreurs, Zones & Paramètres — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter les 4 écrans manquants du tableau de bord admin Flutter (`lilia-food-admin`) — Paiements, Livreurs, Zones (référentiel quartiers) et Paramètres plateforme — chacun branché sur un endpoint backend existant, accessibles depuis un menu d'administration.

**Architecture:** App Flutter + Riverpod (code generation). Les écrans sont ADMIN-only et vivent dans la feature `admin/`. Modèles dans `lib/models/`, appels HTTP dans `AdminOperationsRepository`, providers `@riverpod` dans `lib/features/admin/presentation/providers/`, écrans dans `presentation/screens/`. Les routes sont imbriquées sous la branche `/settings` (onglet « Admin »), comme `delivery-zones`. L'écran « Espace Administrateur » (placeholder vide aujourd'hui) devient le menu d'accès aux 4 écrans.

**Tech Stack:** Flutter, Riverpod + `riverpod_annotation` (code gen), package `http`, `go_router`, `intl`. Vérification : `flutter analyze` + `dart run build_runner build --delete-conflicting-outputs`.

**Périmètre :** Chantier 4 de LIL-79 (volet Flutter), parité avec le volet web (`lilia-food-web/docs/superpowers/plans/2026-05-22-lil79-admin-web-pages.md`). Les chantiers 1-3 Flutter (fidélité, parrainage, liste clients) sont déjà livrés.

**Prérequis :**
- Les endpoints backend doivent être déployés sur `https://lilia-backend.onrender.com` pour la vérification sur appareil/émulateur. Le `flutter analyze` et la revue restent valables sans déploiement.
- **Git :** la branche `dev` contient des modifications non commitées qui touchent notamment `lib/routing/app_router.dart` et `lib/features/settings/presentation/screens/settings_screen.dart` (fichiers aussi modifiés par ce plan). Exécuter ce plan sur une branche/worktree propre dédiée pour que chaque `git add` ne capture que les changements du chantier 4.

---

## Contexte du code existant

- **Endpoints backend (tous livrés, vérifiés dans `lilia-backend`) :**
  - `GET /admin/payments?page&limit&status` → `{ data: [...], total, page, limit }`. `status` par défaut `PENDING`. Chaque paiement : `{ id, amount, currency, phoneNumber, status, provider, createdAt, order: { id, total, status, user: { id, nom, phone } } }`.
  - `POST /payments/:paymentId/confirm` (ADMIN) → confirme un paiement `PENDING`.
  - `GET /admin/deliverers?page&limit` → `{ data: [...], total, page, limit }`. Chaque livreur : `{ id, email, nom, phone, imageUrl, createdAt, deliveries: [{ id, status, createdAt }], _count: { deliveries } }`.
  - `GET /admin/platform-settings` → `{ data: {...} }` ; `PATCH /admin/platform-settings` → `{ data: {...} }`. Champs : `id, serviceFeePercent (Float), loyaltyPointsPer100Xaf, loyaltyPointValueXaf, loyaltyMinRedemption, referrerBonusPoints, referredBonusPoints (Int), maintenanceMode (Bool), maintenanceMessage (String?), updatedAt`.
  - `GET /quartiers` → `{ data: [...], count }` — déjà consommé par la feature `zones/`.
- **Pattern repository** (`lib/features/clients/data/client_repository.dart`) : appels HTTP bruts via `package:http`, token Firebase via `_getAuthToken()`, `_baseUrl = "https://lilia-backend.onrender.com"`, parsing `json.decode(utf8.decode(response.bodyBytes))['data']`.
- **Pattern provider** (`lib/features/clients/presentation/providers/clients_provider.dart`) : `@riverpod` pour le repository + `@riverpod Future<...>` pour chaque lecture. Après toute modif d'un `@riverpod`, lancer `dart run build_runner build --delete-conflicting-outputs`.
- **Pattern écran** (`lib/features/clients/presentation/screens/clients_screen.dart`) : `ConsumerStatefulWidget`, `AsyncValue.when(loading/error/data)`, pagination par `setState`, widgets Material (`Card`, `Colors.grey[...]`, `Theme.of(context).colorScheme`).
- **Routing** (`lib/routing/app_router.dart`) : `StatefulShellRoute.indexedStack`, 5 branches. La branche 4 (`/settings`) contient déjà une sous-route imbriquée `zones` (`name: 'delivery-zones'`). Les nouveaux écrans s'y ajoutent en sous-routes.
- **Écran admin `/settings`** (`settings_screen.dart`, branche `if (isAdmin)`) : aujourd'hui un placeholder centré (icône + 2 textes). Il devient le menu d'administration. Le fichier déclare `_AppColors` (privé) : `primary, primaryLight, success, danger, warning, surface, cardBg, textPrimary, textSecondary, border`.
- **Quartiers existants** : `lib/features/zones/data/zones_service.dart` expose la classe `Quartier` et `getAllQuartiers()` ; `lib/features/zones/presentation/providers/zones_provider.dart` expose `allQuartiersProvider`. L'écran Zones du chantier 4 les **réutilise** — pas de nouveau modèle/repo/provider pour les quartiers.
- L'écran restaurateur existant `ZonesScreen` (`/settings/zones`, gestion CRUD des zones de livraison d'un restaurant) reste **inchangé** et distinct du nouvel écran admin `QuartiersScreen` (`/settings/quartiers`, référentiel global en lecture seule).
- Le modèle existant `AppDeliverer` (`lib/models/app_deliverer.dart`) sert au flux d'assignation (`/deliveries/deliverers`) et reste inchangé — le chantier 4 introduit un modèle dédié `AdminDeliverer`.
- Nom du package : `lilia_admin` (imports `package:lilia_admin/...`).

---

## File Structure

| Fichier | Rôle | Action |
|---|---|---|
| `lib/models/admin_payment.dart` | `AdminPayment`, `AdminPaymentOrder`, `PaginatedPayments` | Créer |
| `lib/models/admin_deliverer.dart` | `AdminDeliverer`, `AdminDelivery`, `PaginatedDeliverers` | Créer |
| `lib/models/platform_settings.dart` | `PlatformSettings` | Créer |
| `lib/features/admin/data/admin_operations_repository.dart` | Appels HTTP paiements / livreurs / config | Créer |
| `lib/features/admin/presentation/providers/admin_operations_provider.dart` | Providers `@riverpod` | Créer |
| `lib/features/admin/presentation/screens/payments_screen.dart` | Écran Paiements | Créer |
| `lib/features/admin/presentation/screens/deliverers_screen.dart` | Écran Livreurs | Créer |
| `lib/features/admin/presentation/screens/quartiers_screen.dart` | Écran Zones (quartiers) | Créer |
| `lib/features/admin/presentation/screens/platform_settings_screen.dart` | Écran Paramètres plateforme | Créer |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Menu admin (remplace le placeholder) | Modifier |
| `lib/routing/app_router.dart` | 4 sous-routes sous `/settings` | Modifier |

---

## Task 1: Modèles

**Files:**
- Create: `lib/models/admin_payment.dart`, `lib/models/admin_deliverer.dart`, `lib/models/platform_settings.dart`

- [ ] **Step 1: Créer `admin_payment.dart`**

```dart
/// La commande associée à un paiement (sous-objet de GET /admin/payments).
class AdminPaymentOrder {
  final String id;
  final double total;
  final String status;
  final String? clientNom;
  final String? clientPhone;

  AdminPaymentOrder({
    required this.id,
    required this.total,
    required this.status,
    this.clientNom,
    this.clientPhone,
  });

  factory AdminPaymentOrder.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AdminPaymentOrder(
      id: json['id'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      clientNom: user?['nom'] as String?,
      clientPhone: user?['phone'] as String?,
    );
  }
}

/// Un paiement de la liste de supervision admin (GET /admin/payments).
class AdminPayment {
  final String id;
  final double amount;
  final String currency;
  final String phoneNumber;
  final String status; // PENDING | SUCCESS | FAILED | CANCELLED
  final String provider;
  final DateTime createdAt;
  final AdminPaymentOrder? order;

  AdminPayment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.phoneNumber,
    required this.status,
    required this.provider,
    required this.createdAt,
    this.order,
  });

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    return AdminPayment(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'XAF',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      provider: json['provider'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      order: json['order'] != null
          ? AdminPaymentOrder.fromJson(json['order'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Enveloppe paginée des paiements (GET /admin/payments).
class PaginatedPayments {
  final List<AdminPayment> payments;
  final int total;
  final int page;
  final int limit;

  PaginatedPayments({
    required this.payments,
    required this.total,
    required this.page,
    required this.limit,
  });

  int get totalPages =>
      limit > 0 ? ((total + limit - 1) ~/ limit).clamp(1, 1 << 31) : 1;
}
```

- [ ] **Step 2: Créer `admin_deliverer.dart`**

```dart
/// Une livraison récente d'un livreur (sous-objet de GET /admin/deliverers).
class AdminDelivery {
  final String id;
  final String status;
  final DateTime createdAt;

  AdminDelivery({
    required this.id,
    required this.status,
    required this.createdAt,
  });

  factory AdminDelivery.fromJson(Map<String, dynamic> json) {
    return AdminDelivery(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Un livreur de la liste de supervision admin (GET /admin/deliverers).
class AdminDeliverer {
  final String id;
  final String? email;
  final String? nom;
  final String? phone;
  final String? imageUrl;
  final DateTime createdAt;
  final List<AdminDelivery> recentDeliveries;
  final int totalDeliveries;

  AdminDeliverer({
    required this.id,
    this.email,
    this.nom,
    this.phone,
    this.imageUrl,
    required this.createdAt,
    required this.recentDeliveries,
    required this.totalDeliveries,
  });

  factory AdminDeliverer.fromJson(Map<String, dynamic> json) {
    final deliveries = json['deliveries'] as List<dynamic>? ?? [];
    final count = json['_count'] as Map<String, dynamic>?;
    return AdminDeliverer(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      nom: json['nom'] as String?,
      phone: json['phone'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      recentDeliveries: deliveries
          .map((d) => AdminDelivery.fromJson(d as Map<String, dynamic>))
          .toList(),
      totalDeliveries: (count?['deliveries'] as int?) ?? 0,
    );
  }
}

/// Enveloppe paginée des livreurs (GET /admin/deliverers).
class PaginatedDeliverers {
  final List<AdminDeliverer> deliverers;
  final int total;
  final int page;
  final int limit;

  PaginatedDeliverers({
    required this.deliverers,
    required this.total,
    required this.page,
    required this.limit,
  });

  int get totalPages =>
      limit > 0 ? ((total + limit - 1) ~/ limit).clamp(1, 1 << 31) : 1;
}
```

- [ ] **Step 3: Créer `platform_settings.dart`**

```dart
/// Configuration globale de la plateforme (GET/PATCH /admin/platform-settings).
class PlatformSettings {
  final String id;
  final double serviceFeePercent;
  final int loyaltyPointsPer100Xaf;
  final int loyaltyPointValueXaf;
  final int loyaltyMinRedemption;
  final int referrerBonusPoints;
  final int referredBonusPoints;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final DateTime updatedAt;

  PlatformSettings({
    required this.id,
    required this.serviceFeePercent,
    required this.loyaltyPointsPer100Xaf,
    required this.loyaltyPointValueXaf,
    required this.loyaltyMinRedemption,
    required this.referrerBonusPoints,
    required this.referredBonusPoints,
    required this.maintenanceMode,
    this.maintenanceMessage,
    required this.updatedAt,
  });

  /// Parse l'objet `data` de la réponse.
  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      id: json['id'] as String? ?? 'singleton',
      serviceFeePercent: (json['serviceFeePercent'] as num?)?.toDouble() ?? 8,
      loyaltyPointsPer100Xaf: json['loyaltyPointsPer100Xaf'] as int? ?? 1,
      loyaltyPointValueXaf: json['loyaltyPointValueXaf'] as int? ?? 5,
      loyaltyMinRedemption: json['loyaltyMinRedemption'] as int? ?? 100,
      referrerBonusPoints: json['referrerBonusPoints'] as int? ?? 500,
      referredBonusPoints: json['referredBonusPoints'] as int? ?? 200,
      maintenanceMode: json['maintenanceMode'] as bool? ?? false,
      maintenanceMessage: json['maintenanceMessage'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
```

- [ ] **Step 4: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/models/`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/models/admin_payment.dart lib/models/admin_deliverer.dart lib/models/platform_settings.dart
git commit -m "feat(models): add admin payment, deliverer and platform settings models"
```

---

## Task 2: `AdminOperationsRepository`

**Files:**
- Create: `lib/features/admin/data/admin_operations_repository.dart`

- [ ] **Step 1: Créer le repository**

```dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:lilia_admin/models/admin_payment.dart';
import 'package:lilia_admin/models/admin_deliverer.dart';
import 'package:lilia_admin/models/platform_settings.dart';

/// Appels HTTP des opérations d'administration transverses :
/// supervision des paiements, des livreurs et configuration plateforme.
/// Toutes les routes sont ADMIN-only côté backend.
class AdminOperationsRepository {
  final String _baseUrl = 'https://lilia-backend.onrender.com';
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non authentifié.');
    }
    return await user.getIdToken();
  }

  /// Paiements paginés, filtrés par statut (GET /admin/payments).
  Future<PaginatedPayments> fetchPayments({
    int page = 1,
    String status = 'PENDING',
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/admin/payments').replace(
      queryParameters: {'page': '$page', 'limit': '20', 'status': status},
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>? ?? [];
      return PaginatedPayments(
        payments: list
            .map((j) => AdminPayment.fromJson(j as Map<String, dynamic>))
            .toList(),
        total: body['total'] as int? ?? list.length,
        page: body['page'] as int? ?? page,
        limit: body['limit'] as int? ?? 20,
      );
    }
    throw Exception(
        'Échec du chargement des paiements: ${response.statusCode} ${response.body}');
  }

  /// Confirmation manuelle d'un paiement (POST /payments/:id/confirm).
  Future<void> confirmPayment(String paymentId) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/payments/$paymentId/confirm'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Échec de la confirmation du paiement';
      try {
        final body = json.decode(utf8.decode(response.bodyBytes));
        if (body is Map && body['message'] is String) {
          message = body['message'] as String;
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// Livreurs paginés avec leurs livraisons récentes (GET /admin/deliverers).
  Future<PaginatedDeliverers> fetchDeliverers({int page = 1}) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/admin/deliverers').replace(
      queryParameters: {'page': '$page', 'limit': '20'},
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>? ?? [];
      return PaginatedDeliverers(
        deliverers: list
            .map((j) => AdminDeliverer.fromJson(j as Map<String, dynamic>))
            .toList(),
        total: body['total'] as int? ?? list.length,
        page: body['page'] as int? ?? page,
        limit: body['limit'] as int? ?? 20,
      );
    }
    throw Exception(
        'Échec du chargement des livreurs: ${response.statusCode} ${response.body}');
  }

  /// Configuration plateforme (GET /admin/platform-settings).
  Future<PlatformSettings> fetchPlatformSettings() async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/platform-settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return PlatformSettings.fromJson(data);
    }
    throw Exception(
        'Échec du chargement de la configuration: ${response.statusCode} ${response.body}');
  }

  /// Mise à jour de la configuration plateforme
  /// (PATCH /admin/platform-settings).
  Future<PlatformSettings> updatePlatformSettings(
      Map<String, dynamic> dto) async {
    final token = await _getAuthToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/admin/platform-settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(dto),
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return PlatformSettings.fromJson(data);
    }
    String message = 'Échec de la mise à jour de la configuration';
    try {
      final body = json.decode(utf8.decode(response.bodyBytes));
      if (body is Map && body['message'] is String) {
        message = body['message'] as String;
      } else if (body is Map && body['message'] is List) {
        message = (body['message'] as List).join(', ');
      }
    } catch (_) {}
    throw Exception(message);
  }
}
```

- [ ] **Step 2: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/admin/data/`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/admin/data/admin_operations_repository.dart
git commit -m "feat(admin): add AdminOperationsRepository for payments, deliverers, platform settings"
```

---

## Task 3: Providers Riverpod

**Files:**
- Create: `lib/features/admin/presentation/providers/admin_operations_provider.dart`

- [ ] **Step 1: Créer `admin_operations_provider.dart`**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lilia_admin/features/admin/data/admin_operations_repository.dart';
import 'package:lilia_admin/models/admin_payment.dart';
import 'package:lilia_admin/models/admin_deliverer.dart';
import 'package:lilia_admin/models/platform_settings.dart';

part 'admin_operations_provider.g.dart';

@riverpod
AdminOperationsRepository adminOperationsRepository(Ref ref) {
  return AdminOperationsRepository();
}

/// Paiements paginés, filtrés par statut (ADMIN).
@riverpod
Future<PaginatedPayments> adminPayments(
  Ref ref, {
  required int page,
  required String status,
}) {
  return ref
      .watch(adminOperationsRepositoryProvider)
      .fetchPayments(page: page, status: status);
}

/// Livreurs paginés (ADMIN).
@riverpod
Future<PaginatedDeliverers> adminDeliverers(Ref ref, {required int page}) {
  return ref
      .watch(adminOperationsRepositoryProvider)
      .fetchDeliverers(page: page);
}

/// Configuration plateforme (ADMIN).
@riverpod
Future<PlatformSettings> platformSettings(Ref ref) {
  return ref.watch(adminOperationsRepositoryProvider).fetchPlatformSettings();
}
```

- [ ] **Step 2: Régénérer le code Riverpod**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && dart run build_runner build --delete-conflicting-outputs`
Expected: build réussi ; `admin_operations_provider.g.dart` créé avec `adminOperationsRepositoryProvider`, `adminPaymentsProvider` (paramètres `page` + `status`), `adminDeliverersProvider` (paramètre `page`), `platformSettingsProvider`.

- [ ] **Step 3: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/admin/presentation/providers/`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/admin/presentation/providers/admin_operations_provider.dart lib/features/admin/presentation/providers/admin_operations_provider.g.dart
git commit -m "feat(admin): add providers for payments, deliverers and platform settings"
```

---

## Task 4: Écran Paiements

L'écran liste les paiements filtrés par statut, paginés, et permet de confirmer manuellement un paiement `PENDING`.

**Files:**
- Create: `lib/features/admin/presentation/screens/payments_screen.dart`

- [ ] **Step 1: Créer `payments_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/models/admin_payment.dart';

/// Statuts de paiement (ordre des filtres) et leurs libellés français.
const _paymentStatuses = ['PENDING', 'SUCCESS', 'FAILED', 'CANCELLED'];
const _paymentStatusLabels = <String, String>{
  'PENDING': 'En attente',
  'SUCCESS': 'Confirmé',
  'FAILED': 'Échoué',
  'CANCELLED': 'Annulé',
};

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String _status = 'PENDING';
  int _page = 1;
  String? _confirmingId;

  Future<void> _confirmPayment(AdminPayment payment) async {
    setState(() => _confirmingId = payment.id);
    try {
      await ref
          .read(adminOperationsRepositoryProvider)
          .confirmPayment(payment.id);
      if (!mounted) return;
      ref.invalidate(adminPaymentsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement confirmé'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _confirmingId = null);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'SUCCESS':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync =
        ref.watch(adminPaymentsProvider(page: _page, status: _status));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(adminPaymentsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: paymentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _errorView(error),
              data: (result) {
                if (result.payments.isEmpty) {
                  return _emptyView(
                    'Aucun paiement « ${_paymentStatusLabels[_status]} »',
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: result.payments.length,
                        itemBuilder: (context, index) =>
                            _paymentCard(result.payments[index]),
                      ),
                    ),
                    _buildPagination(result.total, result.totalPages),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: _paymentStatuses.map((s) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_paymentStatusLabels[s] ?? s),
              selected: s == _status,
              onSelected: (_) {
                setState(() {
                  _status = s;
                  _page = 1;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _paymentCard(AdminPayment payment) {
    final order = payment.order;
    final orderId = order?.id ?? '';
    final orderRef = orderId.length >= 6
        ? '#${orderId.substring(orderId.length - 6).toUpperCase()}'
        : (orderId.isEmpty ? '—' : '#${orderId.toUpperCase()}');
    final color = _statusColor(payment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(orderRef,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _paymentStatusLabels[payment.status] ?? payment.status,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Text(
                  '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order?.clientNom ?? '—',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(payment.phoneNumber,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(width: 10),
                Text(payment.provider,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (payment.status == 'PENDING') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirmingId == null
                      ? () => _confirmPayment(payment)
                      : null,
                  icon: _confirmingId == payment.id
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Confirmer le paiement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(int total, int totalPages) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$total paiement${total > 1 ? 's' : ''} · page $_page/$totalPages',
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
                onPressed:
                    _page < totalPages ? () => setState(() => _page++) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _errorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur de chargement',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminPaymentsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/admin/presentation/screens/payments_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/admin/presentation/screens/payments_screen.dart
git commit -m "feat(admin): add Paiements screen with status filter and confirm action"
```

---

## Task 5: Écran Livreurs

**Files:**
- Create: `lib/features/admin/presentation/screens/deliverers_screen.dart`

- [ ] **Step 1: Créer `deliverers_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/models/admin_deliverer.dart';

class DeliverersScreen extends ConsumerStatefulWidget {
  const DeliverersScreen({super.key});

  @override
  ConsumerState<DeliverersScreen> createState() => _DeliverersScreenState();
}

class _DeliverersScreenState extends ConsumerState<DeliverersScreen> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final deliverersAsync = ref.watch(adminDeliverersProvider(page: _page));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Livreurs'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(adminDeliverersProvider),
          ),
        ],
      ),
      body: deliverersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _errorView(error),
        data: (result) {
          if (result.deliverers.isEmpty) {
            return _emptyView();
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: result.deliverers.length,
                  itemBuilder: (context, index) =>
                      _delivererCard(result.deliverers[index]),
                ),
              ),
              _buildPagination(result.total, result.totalPages),
            ],
          );
        },
      ),
    );
  }

  Widget _delivererCard(AdminDeliverer deliverer) {
    final theme = Theme.of(context);
    final name = deliverer.nom ?? deliverer.email ?? 'Livreur';
    final lastDelivery = deliverer.recentDeliveries.isNotEmpty
        ? deliverer.recentDeliveries.first
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: deliverer.imageUrl != null
                  ? NetworkImage(deliverer.imageUrl!)
                  : null,
              child: deliverer.imageUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
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
                  Text(deliverer.nom ?? '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  if (deliverer.email != null)
                    Row(
                      children: [
                        Icon(Icons.email_outlined,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(deliverer.email!,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  if (deliverer.phone != null)
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(deliverer.phone!,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${deliverer.totalDeliveries}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lastDelivery != null
                      ? 'Dernière : ${DateFormat('dd/MM/yyyy').format(lastDelivery.createdAt)}'
                      : 'Aucune livraison',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(int total, int totalPages) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$total livreur${total > 1 ? 's' : ''} · page $_page/$totalPages',
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
                onPressed:
                    _page < totalPages ? () => setState(() => _page++) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delivery_dining_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('Aucun livreur', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _errorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur de chargement',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminDeliverersProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/admin/presentation/screens/deliverers_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/admin/presentation/screens/deliverers_screen.dart
git commit -m "feat(admin): add Livreurs screen"
```

---

## Task 6: Écran Zones (référentiel quartiers)

Écran en lecture seule réutilisant `allQuartiersProvider` et la classe `Quartier` de la feature `zones/`. Aucun nouveau modèle/repository/provider.

**Files:**
- Create: `lib/features/admin/presentation/screens/quartiers_screen.dart`

- [ ] **Step 1: Créer `quartiers_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/features/zones/data/zones_service.dart';
import 'package:lilia_admin/features/zones/presentation/providers/zones_provider.dart';

/// Référentiel en lecture seule des quartiers couverts par la plateforme.
/// La configuration des zones de livraison et de leurs tarifs se fait au
/// niveau de chaque restaurant (écran « Zones de livraison » restaurateur).
class QuartiersScreen extends ConsumerWidget {
  const QuartiersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quartiersAsync = ref.watch(allQuartiersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zones'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(allQuartiersProvider),
          ),
        ],
      ),
      body: quartiersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Impossible de charger les quartiers',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(allQuartiersProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (quartiers) {
          if (quartiers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('Aucun quartier',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                child: Text(
                  'Référentiel des quartiers couverts. La configuration des '
                  'zones de livraison et de leurs tarifs se fait au niveau de '
                  'chaque restaurant.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
              Text(
                'Quartiers (${quartiers.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 3.4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: quartiers.length,
                itemBuilder: (context, index) {
                  final Quartier q = quartiers[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(q.nom,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/admin/presentation/screens/quartiers_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/admin/presentation/screens/quartiers_screen.dart
git commit -m "feat(admin): add Zones screen (quartiers reference, read-only)"
```

---

## Task 7: Écran Paramètres plateforme

Formulaire de configuration plateforme. L'écran (`ConsumerWidget`) charge via `platformSettingsProvider` ; le formulaire (`_PlatformSettingsForm`) reçoit les données chargées et gère ses `TextEditingController` dans `initState`. L'enregistrement appelle `updatePlatformSettings` puis invalide le provider.

**Files:**
- Create: `lib/features/admin/presentation/screens/platform_settings_screen.dart`

- [ ] **Step 1: Créer `platform_settings_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/models/platform_settings.dart';

class PlatformSettingsScreen extends ConsumerWidget {
  const PlatformSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(platformSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres plateforme'),
        centerTitle: true,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Impossible de charger la configuration',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(platformSettingsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (settings) => _PlatformSettingsForm(settings: settings),
      ),
    );
  }
}

class _PlatformSettingsForm extends ConsumerStatefulWidget {
  const _PlatformSettingsForm({required this.settings});

  final PlatformSettings settings;

  @override
  ConsumerState<_PlatformSettingsForm> createState() =>
      _PlatformSettingsFormState();
}

class _PlatformSettingsFormState extends ConsumerState<_PlatformSettingsForm> {
  late final TextEditingController _serviceFee;
  late final TextEditingController _loyaltyPer100;
  late final TextEditingController _loyaltyValue;
  late final TextEditingController _loyaltyMin;
  late final TextEditingController _referrerBonus;
  late final TextEditingController _referredBonus;
  late final TextEditingController _maintenanceMessage;
  late bool _maintenanceMode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _serviceFee = TextEditingController(text: s.serviceFeePercent.toString());
    _loyaltyPer100 =
        TextEditingController(text: s.loyaltyPointsPer100Xaf.toString());
    _loyaltyValue =
        TextEditingController(text: s.loyaltyPointValueXaf.toString());
    _loyaltyMin =
        TextEditingController(text: s.loyaltyMinRedemption.toString());
    _referrerBonus =
        TextEditingController(text: s.referrerBonusPoints.toString());
    _referredBonus =
        TextEditingController(text: s.referredBonusPoints.toString());
    _maintenanceMessage =
        TextEditingController(text: s.maintenanceMessage ?? '');
    _maintenanceMode = s.maintenanceMode;
  }

  @override
  void dispose() {
    _serviceFee.dispose();
    _loyaltyPer100.dispose();
    _loyaltyValue.dispose();
    _loyaltyMin.dispose();
    _referrerBonus.dispose();
    _referredBonus.dispose();
    _maintenanceMessage.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = widget.settings;
    final dto = <String, dynamic>{
      'serviceFeePercent':
          double.tryParse(_serviceFee.text.trim()) ?? s.serviceFeePercent,
      'loyaltyPointsPer100Xaf':
          int.tryParse(_loyaltyPer100.text.trim()) ?? s.loyaltyPointsPer100Xaf,
      'loyaltyPointValueXaf':
          int.tryParse(_loyaltyValue.text.trim()) ?? s.loyaltyPointValueXaf,
      'loyaltyMinRedemption':
          int.tryParse(_loyaltyMin.text.trim()) ?? s.loyaltyMinRedemption,
      'referrerBonusPoints':
          int.tryParse(_referrerBonus.text.trim()) ?? s.referrerBonusPoints,
      'referredBonusPoints':
          int.tryParse(_referredBonus.text.trim()) ?? s.referredBonusPoints,
      'maintenanceMode': _maintenanceMode,
      'maintenanceMessage': _maintenanceMessage.text.trim(),
    };

    setState(() => _saving = true);
    try {
      await ref
          .read(adminOperationsRepositoryProvider)
          .updatePlatformSettings(dto);
      if (!mounted) return;
      ref.invalidate(platformSettingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration enregistrée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Frais de service', [
          _numberField(_serviceFee, 'Frais de service', '%'),
        ]),
        _section('Fidélité', [
          _numberField(_loyaltyPer100, 'Points gagnés / 100 XAF', 'pts'),
          _numberField(_loyaltyValue, "Valeur d'un point", 'XAF'),
          _numberField(_loyaltyMin, "Seuil minimum d'utilisation", 'pts'),
        ]),
        _section('Parrainage', [
          _numberField(_referrerBonus, 'Bonus parrain', 'pts'),
          _numberField(_referredBonus, 'Bonus filleul', 'pts'),
        ]),
        _section('Maintenance', [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mode maintenance',
                style: TextStyle(fontSize: 14)),
            subtitle: const Text('Bloque les nouvelles commandes',
                style: TextStyle(fontSize: 12)),
            value: _maintenanceMode,
            onChanged: (v) => setState(() => _maintenanceMode = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _maintenanceMessage,
            decoration: const InputDecoration(
              labelText: 'Message affiché au client',
              hintText: 'La plateforme est en maintenance…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _numberField(
      TextEditingController controller, String label, String suffix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          SizedBox(
            width: 110,
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                suffixText: suffix,
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/admin/presentation/screens/platform_settings_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/admin/presentation/screens/platform_settings_screen.dart
git commit -m "feat(admin): add Paramètres plateforme screen (platform settings form)"
```

---

## Task 8: Routing + menu d'administration

Ajoute les 4 sous-routes sous `/settings` et transforme le placeholder « Espace Administrateur » en menu d'accès.

**Files:**
- Modify: `lib/routing/app_router.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Ajouter les imports d'écrans dans `app_router.dart`**

Dans `lib/routing/app_router.dart`, juste après la ligne :

```dart
import 'package:lilia_admin/features/zones/presentation/screens/zones_screen.dart';
```

ajouter :

```dart
import 'package:lilia_admin/features/admin/presentation/screens/payments_screen.dart';
import 'package:lilia_admin/features/admin/presentation/screens/deliverers_screen.dart';
import 'package:lilia_admin/features/admin/presentation/screens/quartiers_screen.dart';
import 'package:lilia_admin/features/admin/presentation/screens/platform_settings_screen.dart';
```

- [ ] **Step 2: Ajouter les 4 sous-routes sous `/settings`**

Dans `app_router.dart`, remplacer le bloc `routes:` de la route `/settings` :

```dart
                routes: [
                  GoRoute(
                    path: 'zones',
                    name: 'delivery-zones',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: ZonesScreen()),
                  ),
                ],
```

par :

```dart
                routes: [
                  GoRoute(
                    path: 'zones',
                    name: 'delivery-zones',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: ZonesScreen()),
                  ),
                  GoRoute(
                    path: 'paiements',
                    name: 'admin-payments',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: PaymentsScreen()),
                  ),
                  GoRoute(
                    path: 'livreurs',
                    name: 'admin-deliverers',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: DeliverersScreen()),
                  ),
                  GoRoute(
                    path: 'quartiers',
                    name: 'admin-quartiers',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: QuartiersScreen()),
                  ),
                  GoRoute(
                    path: 'parametres-plateforme',
                    name: 'platform-settings',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: PlatformSettingsScreen()),
                  ),
                ],
```

- [ ] **Step 3: Remplacer le placeholder admin dans `settings_screen.dart`**

Dans `lib/features/settings/presentation/screens/settings_screen.dart`, dans la branche `if (isAdmin)`, remplacer le bloc `body:` :

```dart
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: _AppColors.primary,
                ),
                SizedBox(height: 24),
                Text(
                  'Espace Administrateur',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Les parametres de restaurant sont accessibles depuis le profil de chaque restaurateur. Utilisez le tableau de bord pour voir les statistiques globales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
```

par :

```dart
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Icon(Icons.admin_panel_settings,
                      size: 36, color: _AppColors.primary),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Espace Administrateur',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _AppColors.textPrimary,
                            )),
                        SizedBox(height: 4),
                        Text(
                          'Gestion transverse de la plateforme.',
                          style: TextStyle(
                            fontSize: 13,
                            color: _AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _AdminMenuTile(
              icon: Icons.payments_outlined,
              iconColor: _AppColors.success,
              title: 'Paiements',
              subtitle: 'Superviser et confirmer les paiements',
              onTap: () => context.goNamed('admin-payments'),
            ),
            _AdminMenuTile(
              icon: Icons.delivery_dining_outlined,
              iconColor: _AppColors.primary,
              title: 'Livreurs',
              subtitle: 'Liste des livreurs et de leurs livraisons',
              onTap: () => context.goNamed('admin-deliverers'),
            ),
            _AdminMenuTile(
              icon: Icons.map_outlined,
              iconColor: _AppColors.warning,
              title: 'Zones',
              subtitle: 'Référentiel des quartiers couverts',
              onTap: () => context.goNamed('admin-quartiers'),
            ),
            _AdminMenuTile(
              icon: Icons.tune,
              iconColor: _AppColors.textSecondary,
              title: 'Paramètres plateforme',
              subtitle: 'Frais de service, fidélité, maintenance',
              onTap: () => context.goNamed('platform-settings'),
            ),
          ],
        ),
```

- [ ] **Step 4: Ajouter le widget `_AdminMenuTile`**

À la fin de `lib/features/settings/presentation/screens/settings_screen.dart`, ajouter :

```dart

/// Tuile de navigation du menu d'administration.
class _AdminMenuTile extends StatelessWidget {
  const _AdminMenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _AppColors.textPrimary,
                          )),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _AppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: _AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/routing/app_router.dart lib/features/settings/presentation/screens/settings_screen.dart`
Expected: `No issues found!` (le fichier `settings_screen.dart` importe déjà `go_router` — `context.goNamed` est disponible).

- [ ] **Step 6: Commit**

```bash
git add lib/routing/app_router.dart lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat(admin): wire chantier 4 screens into routing and admin menu"
```

---

## Task 9: Vérification finale

- [ ] **Step 1: Analyse statique complète**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze`
Expected: aucune nouvelle erreur dans `lib/models/`, `lib/features/admin/`, `lib/routing/` ou `lib/features/settings/`. (Des avertissements préexistants ailleurs dans le projet sont hors périmètre.)

- [ ] **Step 2: Code generation à jour**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && dart run build_runner build --delete-conflicting-outputs`
Expected: build réussi, aucun changement non commité dans `admin_operations_provider.g.dart` (déjà généré et commité à la Task 3).

- [ ] **Step 3: Vérification manuelle (si le backend est déployé)**

Lancer l'app sur un émulateur, se connecter en **ADMIN**, ouvrir l'onglet « Admin » (4ᵉ onglet) :
- Le menu affiche 4 tuiles : Paiements, Livreurs, Zones, Paramètres plateforme.
- **Paiements** : filtres de statut (En attente / Confirmé / Échoué / Annulé), liste paginée ; sur un paiement « En attente », « Confirmer le paiement » → SnackBar de succès, le paiement quitte le filtre PENDING.
- **Livreurs** : liste paginée, chaque livreur affiche son nombre total de livraisons et la date de la dernière.
- **Zones** : grille des quartiers couverts (lecture seule).
- **Paramètres plateforme** : le formulaire affiche les valeurs courantes ; modifier puis « Enregistrer » → SnackBar de succès ; un retour + réouverture conserve les valeurs.
- États chargement / erreur / vide corrects sur chaque écran.

Si le backend n'est pas déployé, noter cette étape comme à refaire après déploiement.

---

## Self-Review

**Couverture du périmètre (chantier 4, volet Flutter — parité web) :**
- Écran Paiements + confirmation → Tasks 1-4 ✅ (équivalent de la page web `paiements/page.tsx`)
- Écran Livreurs → Tasks 1-3, 5 ✅ (équivalent de `livreurs/page.tsx`)
- Écran Zones (référentiel quartiers, lecture seule) → Task 6 ✅ (équivalent de `zones/page.tsx`)
- Écran Paramètres plateforme → Tasks 1-3, 7 ✅ (équivalent de `parametres/page.tsx`)
- Entrées de navigation (menu admin + routes) → Task 8 ✅ (équivalent sidebar/header web)

**Cohérence des types :** `fetchPayments` → `PaginatedPayments` ; `fetchDeliverers` → `PaginatedDeliverers` ; `fetchPlatformSettings`/`updatePlatformSettings` → `PlatformSettings`. Providers : `adminPaymentsProvider(page:, status:)`, `adminDeliverersProvider(page:)`, `platformSettingsProvider` — paramètres nommés cohérents entre définition (Task 3) et appels (Tasks 4, 5, 7). Les écrans Zones réutilisent `allQuartiersProvider` et `Quartier` (Task 6) sans nouveau type. Routes : noms `admin-payments`, `admin-deliverers`, `admin-quartiers`, `platform-settings` identiques entre `app_router.dart` (Task 8 Step 2) et les `context.goNamed(...)` du menu (Task 8 Step 3).

**Code generation :** seul `admin_operations_provider.dart` (Task 3) contient des `@riverpod` nouveaux → `dart run build_runner build --delete-conflicting-outputs` exécuté en Task 3 Step 2, revérifié en Task 9. `app_router.dart` est modifié sans toucher son annotation `@riverpod router` → pas de régénération nécessaire pour lui.

**Hors périmètre :** l'écran restaurateur `ZonesScreen` (`/settings/zones`, CRUD zones de livraison par restaurant) et la feature `settings/` restaurateur restent inchangés. Le modèle `AppDeliverer` (flux d'assignation) reste inchangé. Aucun test unitaire (le projet `lilia-food-admin` n'a pas de framework de test — vérification par `flutter analyze` + build_runner + revue, cohérent avec le plan `lil79-flutter-clients.md`).

**Dépendance :** la vérification manuelle (Task 9 Step 3) suppose le backend déployé sur `https://lilia-backend.onrender.com`.
