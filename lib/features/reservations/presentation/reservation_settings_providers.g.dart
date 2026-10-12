// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reservationSettingsRepository)
final reservationSettingsRepositoryProvider =
    ReservationSettingsRepositoryProvider._();

final class ReservationSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          ReservationSettingsRepository,
          ReservationSettingsRepository,
          ReservationSettingsRepository
        >
    with $Provider<ReservationSettingsRepository> {
  ReservationSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reservationSettingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reservationSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReservationSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReservationSettingsRepository create(Ref ref) {
    return reservationSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReservationSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReservationSettingsRepository>(
        value,
      ),
    );
  }
}

String _$reservationSettingsRepositoryHash() =>
    r'40744800280fad92d51d1d6cf1d42a3764378c36';

@ProviderFor(myReservationSettings)
final myReservationSettingsProvider = MyReservationSettingsProvider._();

final class MyReservationSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReservationState>,
          ReservationState,
          FutureOr<ReservationState>
        >
    with $FutureModifier<ReservationState>, $FutureProvider<ReservationState> {
  MyReservationSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myReservationSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myReservationSettingsHash();

  @$internal
  @override
  $FutureProviderElement<ReservationState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReservationState> create(Ref ref) {
    return myReservationSettings(ref);
  }
}

String _$myReservationSettingsHash() =>
    r'cfa2a275db2f509b452b4ba74a34194327553d02';
