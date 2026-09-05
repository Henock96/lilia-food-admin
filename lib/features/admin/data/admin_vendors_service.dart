import 'package:lilia_admin/core/network/api_client.dart';

import '../../../models/restaurant.dart';
import '../../../models/vendor_type.dart';

import 'package:lilia_admin/utils/api_response.dart';

/// Service marketplace admin (LIL-128) — endpoints `/admin/vendors/*`.
/// Réutilise la classe `Restaurant` côté Flutter ; le backend renvoie un
/// payload élargi (owner + vendorProfile + _count) mais les seuls champs
/// dont l'admin a besoin pour la liste/queue/validation sont déjà couverts.
class AdminVendorsService {
  final ApiClient _api;

  AdminVendorsService(this._api);

  /// GET /admin/vendors?vendorType=&adminApproved=&isActive=
  Future<List<AdminVendorItem>> listVendors({
    VendorType? vendorType,
    bool? adminApproved,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _api.getJson('/admin/vendors', query: {
      'page': page.toString(),
      'limit': limit.toString(),
      if (vendorType != null) 'vendorType': vendorType.name,
      if (adminApproved != null) 'adminApproved': adminApproved.toString(),
      if (isActive != null) 'isActive': isActive.toString(),
    });
    // Backend renvoie { data:[...], total } → double-wrappé par l'interceptor.
    final list = ApiResponse.listOf(res.data).cast<Map<String, dynamic>>();
    return list.map(AdminVendorItem.fromJson).toList();
  }

  /// GET /admin/vendors/pending — raccourci badge "à valider".
  Future<List<AdminVendorItem>> listPending() async {
    final res = await _api.getJson('/admin/vendors/pending');
    // /admin/vendors/pending → { data:[...], ... } double-wrappé.
    final list = ApiResponse.listOf(res.data).cast<Map<String, dynamic>>();
    return list.map(AdminVendorItem.fromJson).toList();
  }

  /// PATCH /admin/vendors/:id/approve
  Future<void> approveVendor(String restaurantId) async {
    await _api.patchJson('/admin/vendors/$restaurantId/approve');
  }

  /// PATCH /admin/vendors/:id/suspend body { reason }
  Future<void> suspendVendor(String restaurantId, String reason) async {
    await _api.patchJson(
      '/admin/vendors/$restaurantId/suspend',
      body: {'reason': reason},
    );
  }

  /// PATCH /admin/vendors/:id/unsuspend — lève une suspension.
  ///
  /// Manquait côté Flutter : un vendeur suspendu depuis cette app ne pouvait
  /// être réactivé que depuis l'admin web. À ne pas confondre avec
  /// `POST /admin/vendors/:id/activate`, qui publie une boutique dont
  /// l'onboarding est terminé — annuler une sanction et mettre en ligne sont
  /// deux gestes différents.
  Future<void> unsuspendVendor(String restaurantId) async {
    await _api.patchJson('/admin/vendors/$restaurantId/unsuspend');
  }

  /// `PATCH /admin/vendors/:id/display-order` — range le vendeur dans les
  /// listes publiques (1 = premier, 1000 = « pas encore classé »).
  ///
  /// Ne publie rien et ne masque rien : la visibilité reste portée par
  /// `onboardingStatus + adminApproved + isActive`. Le serveur trie déjà par
  /// `[isOpen desc, displayOrder asc, createdAt desc]` — un commerce fermé ne
  /// remonte donc jamais devant un commerce ouvert, quel que soit son rang.
  Future<void> setDisplayOrder(String restaurantId, int displayOrder) async {
    await _api.patchJson(
      '/admin/vendors/$restaurantId/display-order',
      body: {'displayOrder': displayOrder},
    );
  }

  /// `PATCH /admin/vendors/:id/feature` — met le vendeur en avant sur la page
  /// d'accueil du site, ou l'en retire. Indépendant de `displayOrder`.
  Future<void> setFeatured(String restaurantId, bool isFeatured) async {
    await _api.patchJson(
      '/admin/vendors/$restaurantId/feature',
      body: {'isFeatured': isFeatured},
    );
  }
}

/// Représentation enrichie pour la liste admin — `Restaurant` + owner + counts.
/// On évite d'étendre `Restaurant` pour ne pas polluer le modèle utilisé
/// partout ailleurs.
class AdminVendorItem {
  final Restaurant restaurant;
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerPhone;
  final int productCount;
  final int orderCount;

  const AdminVendorItem({
    required this.restaurant,
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
    this.productCount = 0,
    this.orderCount = 0,
  });

  factory AdminVendorItem.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    final count = json['_count'] as Map<String, dynamic>?;
    return AdminVendorItem(
      restaurant: Restaurant.fromJson(json),
      ownerName: owner?['nom'] as String?,
      ownerEmail: owner?['email'] as String?,
      ownerPhone: owner?['phone'] as String?,
      productCount: (count?['products'] as num?)?.toInt() ?? 0,
      orderCount: (count?['orders'] as num?)?.toInt() ?? 0,
    );
  }
}
