import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_order_alerts.g.dart';

/// Coupe la sonnerie d'une commande (annule sa notification locale insistante).
typedef AlertSilencer = Future<void> Function(String orderId);

/// Branché par `DeliveryNotificationService` sur le plugin de notifications
/// locales ; neutre par défaut (tests, plateformes sans notifications).
@Riverpod(keepAlive: true)
AlertSilencer alertSilencer(Ref ref) => (_) async {};

/// File des commandes payées à signaler en plein écran (sonnerie vendeur,
/// Phase 3 F3-01).
///
/// - dédoublonnée : le push immédiat et la relance outbox portent la même
///   commande, elle ne doit sonner qu'une fois ;
/// - ordonnée : trois commandes d'affilée = trois alertes successives ;
/// - mémoire des commandes traitées : une relance arrivant après que le
///   vendeur a fermé l'alerte ne la rouvre pas.
@Riverpod(keepAlive: true)
class NewOrderAlerts extends _$NewOrderAlerts {
  final Set<String> _handled = {};

  @override
  List<String> build() => const [];

  void raise(String orderId) {
    if (_handled.contains(orderId) || state.contains(orderId)) return;
    state = [...state, orderId];
  }

  Future<void> dismiss(String orderId) async {
    _handled.add(orderId);
    state = state.where((id) => id != orderId).toList();
    await ref.read(alertSilencerProvider)(orderId);
  }
}
