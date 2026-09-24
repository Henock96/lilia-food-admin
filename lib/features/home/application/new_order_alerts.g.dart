// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_order_alerts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Branché par `DeliveryNotificationService` sur le plugin de notifications
/// locales ; neutre par défaut (tests, plateformes sans notifications).

@ProviderFor(alertSilencer)
final alertSilencerProvider = AlertSilencerProvider._();

/// Branché par `DeliveryNotificationService` sur le plugin de notifications
/// locales ; neutre par défaut (tests, plateformes sans notifications).

final class AlertSilencerProvider
    extends $FunctionalProvider<AlertSilencer, AlertSilencer, AlertSilencer>
    with $Provider<AlertSilencer> {
  /// Branché par `DeliveryNotificationService` sur le plugin de notifications
  /// locales ; neutre par défaut (tests, plateformes sans notifications).
  AlertSilencerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertSilencerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertSilencerHash();

  @$internal
  @override
  $ProviderElement<AlertSilencer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlertSilencer create(Ref ref) {
    return alertSilencer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertSilencer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertSilencer>(value),
    );
  }
}

String _$alertSilencerHash() => r'2842e53503fbe1cfcfdbce5d7ec4e5a4f914d8fa';

/// File des commandes payées à signaler en plein écran (sonnerie vendeur,
/// Phase 3 F3-01).
///
/// - dédoublonnée : le push immédiat et la relance outbox portent la même
///   commande, elle ne doit sonner qu'une fois ;
/// - ordonnée : trois commandes d'affilée = trois alertes successives ;
/// - mémoire des commandes traitées : une relance arrivant après que le
///   vendeur a fermé l'alerte ne la rouvre pas.

@ProviderFor(NewOrderAlerts)
final newOrderAlertsProvider = NewOrderAlertsProvider._();

/// File des commandes payées à signaler en plein écran (sonnerie vendeur,
/// Phase 3 F3-01).
///
/// - dédoublonnée : le push immédiat et la relance outbox portent la même
///   commande, elle ne doit sonner qu'une fois ;
/// - ordonnée : trois commandes d'affilée = trois alertes successives ;
/// - mémoire des commandes traitées : une relance arrivant après que le
///   vendeur a fermé l'alerte ne la rouvre pas.
final class NewOrderAlertsProvider
    extends $NotifierProvider<NewOrderAlerts, List<String>> {
  /// File des commandes payées à signaler en plein écran (sonnerie vendeur,
  /// Phase 3 F3-01).
  ///
  /// - dédoublonnée : le push immédiat et la relance outbox portent la même
  ///   commande, elle ne doit sonner qu'une fois ;
  /// - ordonnée : trois commandes d'affilée = trois alertes successives ;
  /// - mémoire des commandes traitées : une relance arrivant après que le
  ///   vendeur a fermé l'alerte ne la rouvre pas.
  NewOrderAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newOrderAlertsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newOrderAlertsHash();

  @$internal
  @override
  NewOrderAlerts create() => NewOrderAlerts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$newOrderAlertsHash() => r'c9ea184315d44065abfff0da824fcbbcad88f4fe';

/// File des commandes payées à signaler en plein écran (sonnerie vendeur,
/// Phase 3 F3-01).
///
/// - dédoublonnée : le push immédiat et la relance outbox portent la même
///   commande, elle ne doit sonner qu'une fois ;
/// - ordonnée : trois commandes d'affilée = trois alertes successives ;
/// - mémoire des commandes traitées : une relance arrivant après que le
///   vendeur a fermé l'alerte ne la rouvre pas.

abstract class _$NewOrderAlerts extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
