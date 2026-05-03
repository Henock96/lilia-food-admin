// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zones_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(allQuartiers)
final allQuartiersProvider = AllQuartiersProvider._();

final class AllQuartiersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Quartier>>,
          List<Quartier>,
          FutureOr<List<Quartier>>
        >
    with $FutureModifier<List<Quartier>>, $FutureProvider<List<Quartier>> {
  AllQuartiersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allQuartiersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allQuartiersHash();

  @$internal
  @override
  $FutureProviderElement<List<Quartier>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Quartier>> create(Ref ref) {
    return allQuartiers(ref);
  }
}

String _$allQuartiersHash() => r'81e31f5d2e985abecd5262c72c4f06318b5052f8';

@ProviderFor(DeliveryZones)
final deliveryZonesProvider = DeliveryZonesProvider._();

final class DeliveryZonesProvider
    extends $AsyncNotifierProvider<DeliveryZones, DeliveryZonesData> {
  DeliveryZonesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deliveryZonesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deliveryZonesHash();

  @$internal
  @override
  DeliveryZones create() => DeliveryZones();
}

String _$deliveryZonesHash() => r'83f43211dd99ca20bfcb80507220133ac21e75f2';

abstract class _$DeliveryZones extends $AsyncNotifier<DeliveryZonesData> {
  FutureOr<DeliveryZonesData> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<DeliveryZonesData>, DeliveryZonesData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DeliveryZonesData>, DeliveryZonesData>,
              AsyncValue<DeliveryZonesData>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
