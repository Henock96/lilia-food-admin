// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(earningsRepository)
final earningsRepositoryProvider = EarningsRepositoryProvider._();

final class EarningsRepositoryProvider
    extends
        $FunctionalProvider<
          EarningsRepository,
          EarningsRepository,
          EarningsRepository
        >
    with $Provider<EarningsRepository> {
  EarningsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'earningsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$earningsRepositoryHash();

  @$internal
  @override
  $ProviderElement<EarningsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EarningsRepository create(Ref ref) {
    return earningsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EarningsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EarningsRepository>(value),
    );
  }
}

String _$earningsRepositoryHash() =>
    r'c98c37825f3823aa5c961f062f06f0bfe6c916ed';

@ProviderFor(vendorEarnings)
final vendorEarningsProvider = VendorEarningsProvider._();

final class VendorEarningsProvider
    extends
        $FunctionalProvider<
          AsyncValue<VendorEarnings>,
          VendorEarnings,
          FutureOr<VendorEarnings>
        >
    with $FutureModifier<VendorEarnings>, $FutureProvider<VendorEarnings> {
  VendorEarningsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vendorEarningsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vendorEarningsHash();

  @$internal
  @override
  $FutureProviderElement<VendorEarnings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<VendorEarnings> create(Ref ref) {
    return vendorEarnings(ref);
  }
}

String _$vendorEarningsHash() => r'd061465ffc7dc23cd5b63bde68242f05b1952436';
