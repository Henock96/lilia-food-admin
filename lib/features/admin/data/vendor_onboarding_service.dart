import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

import '../../../models/onboarding_report.dart';
import '../../../models/restaurant.dart';
import '../../../models/vendor_type.dart';

/// Onboarding vendeur (août 2026) — `POST /admin/vendors` et
/// `PATCH /vendors/:id/*`.
///
/// Remplace `AdminService.createRestaurantWithOwner`, qui publiait une boutique
/// vide dès la validation du formulaire et obligeait l'administrateur à choisir
/// le mot de passe du vendeur pour le lui transmettre à la main.
class VendorOnboardingService {
  final ApiClient _api;

  VendorOnboardingService(this._api);

  /// Étape 1 — crée la boutique et le compte de son propriétaire, en `DRAFT`.
  ///
  /// Aucun mot de passe n'est transmis : le backend crée un secret jetable et
  /// envoie une invitation d'activation au propriétaire.
  ///
  /// [idempotencyKey] protège du double-tap et du retry réseau : deux requêtes
  /// portant la même clé ne créent qu'un vendeur.
  Future<CreateVendorResult> createVendor({
    required VendorType vendorType,
    required String ownerNom,
    required String ownerEmail,
    required String ownerPhone,
    required String nom,
    required String adresse,
    required String phone,
    String? description,
    required String idempotencyKey,
  }) async {
    final res = await _api.postJson(
      '/admin/vendors',
      body: {
        'vendorType': vendorType.name,
        'ownerNom': ownerNom,
        'ownerEmail': ownerEmail,
        'ownerPhone': ownerPhone,
        'nom': nom,
        'adresse': adresse,
        'phone': phone,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
      headers: {'Idempotency-Key': idempotencyKey},
    );
    return CreateVendorResult.fromJson(ApiResponse.mapOf(res.data));
  }

  /// Checklist « prêt à vendre ». Source de vérité de la progression affichée.
  Future<OnboardingReport> getOnboarding(String restaurantId) async {
    final res = await _api.getJson('/vendors/$restaurantId/onboarding');
    return OnboardingReport.fromJson(ApiResponse.mapOf(res.data));
  }

  /// Aperçu de la boutique telle que le client la verra.
  Future<Restaurant> getPreview(String restaurantId) async {
    final res = await _api.getJson('/vendors/$restaurantId/preview');
    final map = ApiResponse.mapOf(res.data);
    return Restaurant.fromJson(map['vendor'] as Map<String, dynamic>);
  }

  Future<OnboardingReport?> updateIdentity(
    String restaurantId, {
    String? nom,
    String? description,
    String? phone,
    String? email,
    String? imageUrl,
    String? imagePublicId,
    List<String>? specialties,
  }) =>
      _patchSection('$restaurantId/identity', {
        if (nom != null) 'nom': nom,
        if (description != null) 'description': description,
        if (phone != null) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (imageUrl != null) 'imageUrl': imageUrl,
        // Le publicId accompagne toujours l'URL : sans lui, remplacer le logo
        // laisserait l'ancien fichier orphelin dans Cloudinary.
        if (imagePublicId != null) 'imagePublicId': imagePublicId,
        if (specialties != null) 'specialties': specialties,
      });

  Future<OnboardingReport?> updateLocation(
    String restaurantId, {
    String? adresse,
    String? quartierId,
    double? latitude,
    double? longitude,
    String? deliveryInstructions,
  }) =>
      _patchSection('$restaurantId/location', {
        if (adresse != null) 'adresse': adresse,
        if (quartierId != null) 'quartierId': quartierId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (deliveryInstructions != null)
          'deliveryInstructions': deliveryInstructions,
      });

  Future<OnboardingReport?> updateHours(
    String restaurantId,
    List<Map<String, dynamic>> hours,
  ) =>
      _patchSection('$restaurantId/hours', {'hours': hours});

  Future<OnboardingReport?> updateDelivery(
    String restaurantId, {
    bool? supportsDelivery,
    bool? supportsPickup,
    String? deliveryPriceMode,
    int? fixedDeliveryFee,
    int? estimatedDeliveryTimeMin,
    int? estimatedDeliveryTimeMax,
  }) =>
      _patchSection('$restaurantId/delivery', {
        if (supportsDelivery != null) 'supportsDelivery': supportsDelivery,
        if (supportsPickup != null) 'supportsPickup': supportsPickup,
        if (deliveryPriceMode != null) 'deliveryPriceMode': deliveryPriceMode,
        if (fixedDeliveryFee != null) 'fixedDeliveryFee': fixedDeliveryFee,
        if (estimatedDeliveryTimeMin != null)
          'estimatedDeliveryTimeMin': estimatedDeliveryTimeMin,
        if (estimatedDeliveryTimeMax != null)
          'estimatedDeliveryTimeMax': estimatedDeliveryTimeMax,
      });

  /// Étape 7 — commission et minimum de commande. **ADMIN uniquement** : la
  /// route vit sous `/admin/vendors`, un restaurateur ne peut pas l'appeler.
  Future<void> updateCommerce(
    String restaurantId, {
    double? commissionPercent,
    bool clearCommission = false,
    int? minimumOrderAmount,
  }) async {
    await _api.patchJson('/admin/vendors/$restaurantId/commerce', body: {
      // `null` explicite = revenir au taux plateforme. Sans ce drapeau, on ne
      // pourrait pas distinguer « ne pas modifier » de « remettre à zéro ».
      if (clearCommission) 'commissionPercent': null
      else if (commissionPercent != null)
        'commissionPercent': commissionPercent,
      if (minimumOrderAmount != null) 'minimumOrderAmount': minimumOrderAmount,
    });
  }

  /// `PATCH /admin/vendors/:id/payout-account` — compte Mobile Money sur
  /// lequel le vendeur sera reversé.
  ///
  /// Volontairement **hors** de `updateCommerce` : la commission est un taux
  /// négociable, le numéro de reversement est la destination de l'argent.
  /// Le backend les sépare pour la même raison — la route est réservée à
  /// l'ADMIN et absente de `UpdateRestaurantDto`, ouvert au RESTAURATEUR : un
  /// compte vendeur compromis détournerait sinon tous les reversements.
  ///
  /// [payoutProvider] : `MTN_MOMO` ou `AIRTEL_MONEY`.
  Future<void> updatePayoutAccount(
    String restaurantId, {
    required String payoutPhoneNumber,
    required String payoutProvider,
    String? payoutAccountName,
  }) async {
    await _api.patchJson('/admin/vendors/$restaurantId/payout-account', body: {
      'payoutPhoneNumber': payoutPhoneNumber,
      'payoutProvider': payoutProvider,
      if (payoutAccountName != null && payoutAccountName.isNotEmpty)
        'payoutAccountName': payoutAccountName,
    });
  }

  /// Étape 10 — active la boutique. Le backend refuse (409) si la checklist
  /// bloquante est incomplète.
  ///
  /// [skipRecommendations] passe outre les éléments seulement recommandés
  /// (description, photo de couverture) — jamais les bloquants.
  Future<void> activate(
    String restaurantId, {
    bool skipRecommendations = false,
  }) async {
    await _api.postJson(
      '/admin/vendors/$restaurantId/activate',
      body: {'skipRecommendations': skipRecommendations},
    );
  }

  /// Renvoie l'invitation d'activation au propriétaire.
  Future<VendorInvitationResult> resendInvitation(String restaurantId) async {
    final res =
        await _api.postJson('/admin/vendors/$restaurantId/resend-invitation');
    return VendorInvitationResult.fromJson(ApiResponse.mapOf(res.data));
  }

  Future<OnboardingReport?> _patchSection(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _api.patchJson('/vendors/$path', body: body);
    final map = ApiResponse.mapOf(res.data);
    final readiness = map['readiness'];
    return readiness is Map<String, dynamic>
        ? OnboardingReport.fromJson(readiness)
        : null;
  }
}

/// Réponse de la création : la boutique, sa checklist et l'état de l'invitation.
class CreateVendorResult {
  final Restaurant vendor;
  final OnboardingReport? readiness;
  final VendorInvitationResult? invitation;

  const CreateVendorResult({
    required this.vendor,
    this.readiness,
    this.invitation,
  });

  factory CreateVendorResult.fromJson(Map<String, dynamic> json) {
    final readiness = json['readiness'];
    final invitation = json['invitation'];
    return CreateVendorResult(
      vendor: Restaurant.fromJson(json['vendor'] as Map<String, dynamic>),
      readiness: readiness is Map<String, dynamic>
          ? OnboardingReport.fromJson(readiness)
          : null,
      invitation: invitation is Map<String, dynamic>
          ? VendorInvitationResult.fromJson(invitation)
          : null,
    );
  }
}
