// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incidents_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(incidentsRepository)
final incidentsRepositoryProvider = IncidentsRepositoryProvider._();

final class IncidentsRepositoryProvider
    extends
        $FunctionalProvider<
          IncidentsRepository,
          IncidentsRepository,
          IncidentsRepository
        >
    with $Provider<IncidentsRepository> {
  IncidentsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incidentsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incidentsRepositoryHash();

  @$internal
  @override
  $ProviderElement<IncidentsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IncidentsRepository create(Ref ref) {
    return incidentsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IncidentsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IncidentsRepository>(value),
    );
  }
}

String _$incidentsRepositoryHash() =>
    r'ae1a4d20571808f6d7ebae99dcfc4d3f1d8dacf0';

/// Liste paginée + filtrable des incidents (ADMIN).
///
/// Le `family` de Riverpod prend les filtres comme paramètres pour bénéficier
/// du cache automatique : revenir sur un filtre déjà vu est instantané.

@ProviderFor(incidentsList)
final incidentsListProvider = IncidentsListFamily._();

/// Liste paginée + filtrable des incidents (ADMIN).
///
/// Le `family` de Riverpod prend les filtres comme paramètres pour bénéficier
/// du cache automatique : revenir sur un filtre déjà vu est instantané.

final class IncidentsListProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaginatedIncidents>,
          PaginatedIncidents,
          FutureOr<PaginatedIncidents>
        >
    with
        $FutureModifier<PaginatedIncidents>,
        $FutureProvider<PaginatedIncidents> {
  /// Liste paginée + filtrable des incidents (ADMIN).
  ///
  /// Le `family` de Riverpod prend les filtres comme paramètres pour bénéficier
  /// du cache automatique : revenir sur un filtre déjà vu est instantané.
  IncidentsListProvider._({
    required IncidentsListFamily super.from,
    required ({
      IncidentStatus? status,
      IncidentSeverity? severity,
      IncidentType? type,
      int limit,
      int offset,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'incidentsListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$incidentsListHash();

  @override
  String toString() {
    return r'incidentsListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<PaginatedIncidents> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaginatedIncidents> create(Ref ref) {
    final argument =
        this.argument
            as ({
              IncidentStatus? status,
              IncidentSeverity? severity,
              IncidentType? type,
              int limit,
              int offset,
            });
    return incidentsList(
      ref,
      status: argument.status,
      severity: argument.severity,
      type: argument.type,
      limit: argument.limit,
      offset: argument.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IncidentsListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$incidentsListHash() => r'6e48b9d7ebed4cc326d1e59e2c211aed8d2c1255';

/// Liste paginée + filtrable des incidents (ADMIN).
///
/// Le `family` de Riverpod prend les filtres comme paramètres pour bénéficier
/// du cache automatique : revenir sur un filtre déjà vu est instantané.

final class IncidentsListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<PaginatedIncidents>,
          ({
            IncidentStatus? status,
            IncidentSeverity? severity,
            IncidentType? type,
            int limit,
            int offset,
          })
        > {
  IncidentsListFamily._()
    : super(
        retry: null,
        name: r'incidentsListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Liste paginée + filtrable des incidents (ADMIN).
  ///
  /// Le `family` de Riverpod prend les filtres comme paramètres pour bénéficier
  /// du cache automatique : revenir sur un filtre déjà vu est instantané.

  IncidentsListProvider call({
    IncidentStatus? status,
    IncidentSeverity? severity,
    IncidentType? type,
    required int limit,
    required int offset,
  }) => IncidentsListProvider._(
    argument: (
      status: status,
      severity: severity,
      type: type,
      limit: limit,
      offset: offset,
    ),
    from: this,
  );

  @override
  String toString() => r'incidentsListProvider';
}

/// Détail d'un incident par ID (ADMIN).

@ProviderFor(incidentDetail)
final incidentDetailProvider = IncidentDetailFamily._();

/// Détail d'un incident par ID (ADMIN).

final class IncidentDetailProvider
    extends
        $FunctionalProvider<AsyncValue<Incident>, Incident, FutureOr<Incident>>
    with $FutureModifier<Incident>, $FutureProvider<Incident> {
  /// Détail d'un incident par ID (ADMIN).
  IncidentDetailProvider._({
    required IncidentDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'incidentDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$incidentDetailHash();

  @override
  String toString() {
    return r'incidentDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Incident> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Incident> create(Ref ref) {
    final argument = this.argument as String;
    return incidentDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IncidentDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$incidentDetailHash() => r'57cb9075658805a69a6fd9e01fac1338b02da33d';

/// Détail d'un incident par ID (ADMIN).

final class IncidentDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Incident>, String> {
  IncidentDetailFamily._()
    : super(
        retry: null,
        name: r'incidentDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Détail d'un incident par ID (ADMIN).

  IncidentDetailProvider call(String id) =>
      IncidentDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'incidentDetailProvider';
}
