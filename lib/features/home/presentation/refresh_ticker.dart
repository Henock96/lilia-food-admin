import 'dart:async';

import 'package:flutter/widgets.dart';

/// Lot 2 (ADM-04, décision D-4 du 13/10/2026) — relecture périodique des
/// commandes.
///
/// L'ADMIN ne voyait pas arriver les nouvelles commandes : le push « nouvelle
/// commande » ne part qu'au vendeur, le socket ne suit que les commandes déjà
/// affichées, et rien ne relisait la liste — ni à intervalle, ni au retour au
/// premier plan. D-4 : commencer par un polling raisonnable, mesurer avant
/// d'envisager une room Socket.IO.
///
/// - un tick toutes les [interval] (30 s) tant que l'app est au premier plan ;
/// - arrêt en arrière-plan (batterie, données mobiles) ;
/// - au retour : relecture **immédiate**, puis reprise du rythme.
///
/// Sans dépendance à Riverpod ni à un écran : l'appelant décide de ce qu'un
/// tick relit, et de s'il est visible.
class RefreshTicker {
  RefreshTicker({
    required this.onTick,
    this.interval = const Duration(seconds: 30),
  });

  final VoidCallback onTick;
  final Duration interval;
  Timer? _timer;

  bool get isRunning => _timer != null;

  /// Sans effet si le rythme tourne déjà : deux démarrages ne le doublent pas.
  void start() {
    _timer ??= Timer.periodic(interval, (_) => onTick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onTick();
        start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        stop();
    }
  }
}
