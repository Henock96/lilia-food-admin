// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offers_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(offersRepository)
final offersRepositoryProvider = OffersRepositoryProvider._();

final class OffersRepositoryProvider
    extends
        $FunctionalProvider<
          OffersRepository,
          OffersRepository,
          OffersRepository
        >
    with $Provider<OffersRepository> {
  OffersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offersRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offersRepositoryHash();

  @$internal
  @override
  $ProviderElement<OffersRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OffersRepository create(Ref ref) {
    return offersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OffersRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OffersRepository>(value),
    );
  }
}

String _$offersRepositoryHash() => r'a851007c04205f2b46b57c35103585d157a369b4';

@ProviderFor(myOffers)
final myOffersProvider = MyOffersProvider._();

final class MyOffersProvider
    extends
        $FunctionalProvider<AsyncValue<MyOffers>, MyOffers, FutureOr<MyOffers>>
    with $FutureModifier<MyOffers>, $FutureProvider<MyOffers> {
  MyOffersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myOffersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myOffersHash();

  @$internal
  @override
  $FutureProviderElement<MyOffers> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MyOffers> create(Ref ref) {
    return myOffers(ref);
  }
}

String _$myOffersHash() => r'7feca0e11cafa28244eea83caff91521a8f5ad6f';
