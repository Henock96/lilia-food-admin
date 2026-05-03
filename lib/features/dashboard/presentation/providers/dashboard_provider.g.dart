// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dashboardOverview)
final dashboardOverviewProvider = DashboardOverviewProvider._();

final class DashboardOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<DashboardOverview>,
          DashboardOverview,
          FutureOr<DashboardOverview>
        >
    with
        $FutureModifier<DashboardOverview>,
        $FutureProvider<DashboardOverview> {
  DashboardOverviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardOverviewHash();

  @$internal
  @override
  $FutureProviderElement<DashboardOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DashboardOverview> create(Ref ref) {
    return dashboardOverview(ref);
  }
}

String _$dashboardOverviewHash() => r'7de9e97139a6bb9dacde74f34e5f88e5fc1c45b9';

@ProviderFor(orderStats)
final orderStatsProvider = OrderStatsFamily._();

final class OrderStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrderStats>,
          OrderStats,
          FutureOr<OrderStats>
        >
    with $FutureModifier<OrderStats>, $FutureProvider<OrderStats> {
  OrderStatsProvider._({
    required OrderStatsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'orderStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderStatsHash();

  @override
  String toString() {
    return r'orderStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OrderStats> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<OrderStats> create(Ref ref) {
    final argument = this.argument as String?;
    return orderStats(ref, period: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderStatsHash() => r'cf37f2e1e49672698a415a19a15217047f73a46c';

final class OrderStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<OrderStats>, String?> {
  OrderStatsFamily._()
    : super(
        retry: null,
        name: r'orderStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderStatsProvider call({String? period}) =>
      OrderStatsProvider._(argument: period, from: this);

  @override
  String toString() => r'orderStatsProvider';
}

@ProviderFor(topProducts)
final topProductsProvider = TopProductsFamily._();

final class TopProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TopProduct>>,
          List<TopProduct>,
          FutureOr<List<TopProduct>>
        >
    with $FutureModifier<List<TopProduct>>, $FutureProvider<List<TopProduct>> {
  TopProductsProvider._({
    required TopProductsFamily super.from,
    required ({int limit, String? period}) super.argument,
  }) : super(
         retry: null,
         name: r'topProductsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$topProductsHash();

  @override
  String toString() {
    return r'topProductsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<TopProduct>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TopProduct>> create(Ref ref) {
    final argument = this.argument as ({int limit, String? period});
    return topProducts(ref, limit: argument.limit, period: argument.period);
  }

  @override
  bool operator ==(Object other) {
    return other is TopProductsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$topProductsHash() => r'b63ee2b49815eeac22ea02e35b595e83c9d27188';

final class TopProductsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<TopProduct>>,
          ({int limit, String? period})
        > {
  TopProductsFamily._()
    : super(
        retry: null,
        name: r'topProductsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TopProductsProvider call({int limit = 10, String? period}) =>
      TopProductsProvider._(
        argument: (limit: limit, period: period),
        from: this,
      );

  @override
  String toString() => r'topProductsProvider';
}

@ProviderFor(revenueChart)
final revenueChartProvider = RevenueChartFamily._();

final class RevenueChartProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RevenueData>>,
          List<RevenueData>,
          FutureOr<List<RevenueData>>
        >
    with
        $FutureModifier<List<RevenueData>>,
        $FutureProvider<List<RevenueData>> {
  RevenueChartProvider._({
    required RevenueChartFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'revenueChartProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$revenueChartHash();

  @override
  String toString() {
    return r'revenueChartProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<RevenueData>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RevenueData>> create(Ref ref) {
    final argument = this.argument as int;
    return revenueChart(ref, days: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RevenueChartProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$revenueChartHash() => r'175e0db08627cd723b70e4f19b1220e06f55f194';

final class RevenueChartFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<RevenueData>>, int> {
  RevenueChartFamily._()
    : super(
        retry: null,
        name: r'revenueChartProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RevenueChartProvider call({int days = 30}) =>
      RevenueChartProvider._(argument: days, from: this);

  @override
  String toString() => r'revenueChartProvider';
}

@ProviderFor(clientStats)
final clientStatsProvider = ClientStatsProvider._();

final class ClientStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClientStats>,
          ClientStats,
          FutureOr<ClientStats>
        >
    with $FutureModifier<ClientStats>, $FutureProvider<ClientStats> {
  ClientStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientStatsHash();

  @$internal
  @override
  $FutureProviderElement<ClientStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClientStats> create(Ref ref) {
    return clientStats(ref);
  }
}

String _$clientStatsHash() => r'10cf42cb56f75c71011809f2873c9e0f9bd4ad5b';

@ProviderFor(peakHours)
final peakHoursProvider = PeakHoursFamily._();

final class PeakHoursProvider
    extends
        $FunctionalProvider<
          AsyncValue<PeakHoursData>,
          PeakHoursData,
          FutureOr<PeakHoursData>
        >
    with $FutureModifier<PeakHoursData>, $FutureProvider<PeakHoursData> {
  PeakHoursProvider._({
    required PeakHoursFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'peakHoursProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$peakHoursHash();

  @override
  String toString() {
    return r'peakHoursProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PeakHoursData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PeakHoursData> create(Ref ref) {
    final argument = this.argument as String?;
    return peakHours(ref, period: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PeakHoursProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$peakHoursHash() => r'fc8f9fbcfc85b06ece0ccb45e7127a807ce519a4';

final class PeakHoursFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PeakHoursData>, String?> {
  PeakHoursFamily._()
    : super(
        retry: null,
        name: r'peakHoursProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PeakHoursProvider call({String? period}) =>
      PeakHoursProvider._(argument: period, from: this);

  @override
  String toString() => r'peakHoursProvider';
}

@ProviderFor(restaurantRanking)
final restaurantRankingProvider = RestaurantRankingFamily._();

final class RestaurantRankingProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RestaurantRanking>>,
          List<RestaurantRanking>,
          FutureOr<List<RestaurantRanking>>
        >
    with
        $FutureModifier<List<RestaurantRanking>>,
        $FutureProvider<List<RestaurantRanking>> {
  RestaurantRankingProvider._({
    required RestaurantRankingFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'restaurantRankingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$restaurantRankingHash();

  @override
  String toString() {
    return r'restaurantRankingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<RestaurantRanking>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RestaurantRanking>> create(Ref ref) {
    final argument = this.argument as String?;
    return restaurantRanking(ref, period: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RestaurantRankingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$restaurantRankingHash() => r'aa3c3e1575e7fc892d416315234cf224b5e267aa';

final class RestaurantRankingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<RestaurantRanking>>, String?> {
  RestaurantRankingFamily._()
    : super(
        retry: null,
        name: r'restaurantRankingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RestaurantRankingProvider call({String? period}) =>
      RestaurantRankingProvider._(argument: period, from: this);

  @override
  String toString() => r'restaurantRankingProvider';
}
