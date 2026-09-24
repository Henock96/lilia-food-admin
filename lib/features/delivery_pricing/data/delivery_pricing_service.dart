import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

/// Tarification de livraison plateforme (F3-02), vue vendeur.
///
/// Le vendeur ne fixe plus le prix de la course : il **lit** la grille Lilia
/// et peut seulement en offrir une part à ses clients, retenue sur son
/// reversement. Aucun prix n'est calculé ici.
class DeliveryTariffBand {
  final double maxKm;
  final int feeXaf;

  const DeliveryTariffBand({required this.maxKm, required this.feeXaf});

  factory DeliveryTariffBand.fromJson(Map<String, dynamic> json) =>
      DeliveryTariffBand(
        maxKm: (json['maxKm'] as num).toDouble(),
        feeXaf: (json['feeXaf'] as num).toInt(),
      );
}

/// `GET /delivery-tariffs/current`.
class CurrentDeliveryTariff {
  /// `VENDOR_LEGACY` ou `PLATFORM`.
  final String mode;
  final int? version;
  final List<DeliveryTariffBand> bands;

  const CurrentDeliveryTariff({
    required this.mode,
    this.version,
    this.bands = const [],
  });

  bool get isPlatform => mode == 'PLATFORM';

  factory CurrentDeliveryTariff.fromJson(Map<String, dynamic> json) {
    final tariff = json['tariff'] as Map<String, dynamic>?;
    final bands =
        ((tariff?['bands'] as List?) ?? const [])
            .map((b) => DeliveryTariffBand.fromJson(b as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.maxKm.compareTo(b.maxKm));
    return CurrentDeliveryTariff(
      mode: json['mode'] as String? ?? 'VENDOR_LEGACY',
      version: (tariff?['version'] as num?)?.toInt(),
      bands: bands,
    );
  }
}

/// `GET /vendors/:id/delivery-subsidy/simulate`.
class DeliverySubsidySimulation {
  final int orders;
  final int costXaf;
  final int subsidizedOrders;

  const DeliverySubsidySimulation({
    required this.orders,
    required this.costXaf,
    required this.subsidizedOrders,
  });

  factory DeliverySubsidySimulation.fromJson(Map<String, dynamic> json) =>
      DeliverySubsidySimulation(
        orders: (json['orders'] as num).toInt(),
        costXaf: (json['costXaf'] as num).toInt(),
        subsidizedOrders: (json['subsidizedOrders'] as num).toInt(),
      );
}

/// Réglage de subvention : le mode et la seule valeur qu'il utilise.
class DeliverySubsidySetting {
  final String mode;
  final int? amountXaf;
  final int? thresholdXaf;

  const DeliverySubsidySetting({
    required this.mode,
    this.amountXaf,
    this.thresholdXaf,
  });

  Map<String, dynamic> toJson() => {
    'mode': mode,
    if (mode == 'FIXED') 'amountXaf': amountXaf,
    if (mode == 'FREE_ABOVE') 'thresholdXaf': thresholdXaf,
  };

  Map<String, String> toQuery() =>
      toJson().map((k, v) => MapEntry(k, v.toString()));
}

class DeliveryPricingService {
  final ApiClient _api;

  DeliveryPricingService(this._api);

  Future<CurrentDeliveryTariff> getCurrent() async {
    final res = await _api.getJson('/delivery-tariffs/current');
    return CurrentDeliveryTariff.fromJson(ApiResponse.mapOf(res.data));
  }

  Future<void> updateSubsidy(
    String vendorId,
    DeliverySubsidySetting setting,
  ) async {
    await _api.patchJson(
      '/vendors/$vendorId/delivery-subsidy',
      body: setting.toJson(),
    );
  }

  Future<DeliverySubsidySimulation> simulateSubsidy(
    String vendorId,
    DeliverySubsidySetting setting,
  ) async {
    final res = await _api.getJson(
      '/vendors/$vendorId/delivery-subsidy/simulate',
      query: setting.toQuery(),
    );
    return DeliverySubsidySimulation.fromJson(ApiResponse.mapOf(res.data));
  }
}

final deliveryPricingServiceProvider = Provider(
  (ref) => DeliveryPricingService(ref.watch(apiClientProvider)),
);

final currentDeliveryTariffProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(deliveryPricingServiceProvider).getCurrent(),
);
