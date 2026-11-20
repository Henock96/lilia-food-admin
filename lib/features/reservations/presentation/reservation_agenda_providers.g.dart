// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_agenda_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reservationAgendaRepository)
final reservationAgendaRepositoryProvider =
    ReservationAgendaRepositoryProvider._();

final class ReservationAgendaRepositoryProvider
    extends
        $FunctionalProvider<
          ReservationAgendaRepository,
          ReservationAgendaRepository,
          ReservationAgendaRepository
        >
    with $Provider<ReservationAgendaRepository> {
  ReservationAgendaRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reservationAgendaRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reservationAgendaRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReservationAgendaRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReservationAgendaRepository create(Ref ref) {
    return reservationAgendaRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReservationAgendaRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReservationAgendaRepository>(value),
    );
  }
}

String _$reservationAgendaRepositoryHash() =>
    r'c8aa402fab39257552c6571948e2bbf88671937a';

/// Agenda d'un jour civil (`AAAA-MM-JJ`), toutes réservations confondues.
/// Rafraîchi par les push `reservation_update` (`notification_service`).

@ProviderFor(reservationAgenda)
final reservationAgendaProvider = ReservationAgendaFamily._();

/// Agenda d'un jour civil (`AAAA-MM-JJ`), toutes réservations confondues.
/// Rafraîchi par les push `reservation_update` (`notification_service`).

final class ReservationAgendaProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReservationAgendaPage>,
          ReservationAgendaPage,
          FutureOr<ReservationAgendaPage>
        >
    with
        $FutureModifier<ReservationAgendaPage>,
        $FutureProvider<ReservationAgendaPage> {
  /// Agenda d'un jour civil (`AAAA-MM-JJ`), toutes réservations confondues.
  /// Rafraîchi par les push `reservation_update` (`notification_service`).
  ReservationAgendaProvider._({
    required ReservationAgendaFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'reservationAgendaProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reservationAgendaHash();

  @override
  String toString() {
    return r'reservationAgendaProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ReservationAgendaPage> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReservationAgendaPage> create(Ref ref) {
    final argument = this.argument as String;
    return reservationAgenda(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReservationAgendaProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reservationAgendaHash() => r'43879d3ec2129a07e3cc58826353ce70f3c31ffa';

/// Agenda d'un jour civil (`AAAA-MM-JJ`), toutes réservations confondues.
/// Rafraîchi par les push `reservation_update` (`notification_service`).

final class ReservationAgendaFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ReservationAgendaPage>, String> {
  ReservationAgendaFamily._()
    : super(
        retry: null,
        name: r'reservationAgendaProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Agenda d'un jour civil (`AAAA-MM-JJ`), toutes réservations confondues.
  /// Rafraîchi par les push `reservation_update` (`notification_service`).

  ReservationAgendaProvider call(String date) =>
      ReservationAgendaProvider._(argument: date, from: this);

  @override
  String toString() => r'reservationAgendaProvider';
}

/// Demandes à traiter, tous jours confondus (compteur de l'en-tête).

@ProviderFor(pendingReservations)
final pendingReservationsProvider = PendingReservationsProvider._();

/// Demandes à traiter, tous jours confondus (compteur de l'en-tête).

final class PendingReservationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReservationAgendaPage>,
          ReservationAgendaPage,
          FutureOr<ReservationAgendaPage>
        >
    with
        $FutureModifier<ReservationAgendaPage>,
        $FutureProvider<ReservationAgendaPage> {
  /// Demandes à traiter, tous jours confondus (compteur de l'en-tête).
  PendingReservationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingReservationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingReservationsHash();

  @$internal
  @override
  $FutureProviderElement<ReservationAgendaPage> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReservationAgendaPage> create(Ref ref) {
    return pendingReservations(ref);
  }
}

String _$pendingReservationsHash() =>
    r'b83e2a483ff76d8e584c613f68a372e5f796cf26';

@ProviderFor(vendorReservation)
final vendorReservationProvider = VendorReservationFamily._();

final class VendorReservationProvider
    extends
        $FunctionalProvider<
          AsyncValue<VendorReservation>,
          VendorReservation,
          FutureOr<VendorReservation>
        >
    with
        $FutureModifier<VendorReservation>,
        $FutureProvider<VendorReservation> {
  VendorReservationProvider._({
    required VendorReservationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'vendorReservationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vendorReservationHash();

  @override
  String toString() {
    return r'vendorReservationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<VendorReservation> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<VendorReservation> create(Ref ref) {
    final argument = this.argument as String;
    return vendorReservation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VendorReservationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vendorReservationHash() => r'6a12fc89e485dfa54c10a2df90b6e84098f497ad';

final class VendorReservationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<VendorReservation>, String> {
  VendorReservationFamily._()
    : super(
        retry: null,
        name: r'vendorReservationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VendorReservationProvider call(String id) =>
      VendorReservationProvider._(argument: id, from: this);

  @override
  String toString() => r'vendorReservationProvider';
}
