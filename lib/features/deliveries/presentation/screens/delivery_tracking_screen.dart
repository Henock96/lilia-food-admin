import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lilia_admin/core/utils/geo.dart';
import 'package:lilia_admin/features/admin/presentation/providers/deliverer_detail_provider.dart';
import 'package:lilia_admin/models/delivery.dart';
import 'package:lilia_admin/models/delivery_status.dart';
import 'package:lilia_admin/models/tracking/driver_position_event.dart';
import 'package:lilia_admin/models/tracking/order_status_event.dart';
import 'package:lilia_admin/services/tracking_socket_provider.dart';

// ────────────────────────────────────────────────────────────────────────────
// Constants — toutes les strings métier et valeurs "magiques" centralisées
// en tête de fichier pour faciliter une future extraction i18n.
// ────────────────────────────────────────────────────────────────────────────

const String _kLogName = 'DeliveryTrackingScreen';

// Fallback destination : centre Brazzaville (placeholder en attendant que le
// backend renvoie la lat/lng de l'adresse client dans la payload Delivery).
const LatLng _kFallbackDestination = LatLng(-4.2634, 15.2429);

// Zoom initial avant le 1er event — recentré sur Brazzaville.
const double _kInitialZoom = 12.5;

// Padding utilisé pour le fit `LatLngBounds` (livreur + destination).
const double _kBoundsPadding = 80;

// Strings UI (FR — pas d'i18n en place sur le projet).
const String _kTitlePrefix = 'Suivi commande #';
const String _kNoMissionTitle = 'Pas encore en livraison';
const String _kNoMissionBody =
    "Cette commande n'a pas encore de livreur en route. Le tracking apparaîtra "
    "dès que le livreur démarrera la mission.";
const String _kDeliveryCompleted = 'Livraison terminée';
const String _kDelivererCardTitle = 'Livreur';
const String _kNoDelivererAssigned = 'Aucun livreur assigné';
const String _kViewDelivererFile = 'Voir fiche livreur';
const String _kEtaUnknown = '—';
const String _kEtaSuffix = 'min';
const String _kCallButton = 'Appeler';
const String _kStreamErrorMessage =
    'Connexion temps réel interrompue. Dernière position conservée.';
const String _kLoadingError = 'Impossible de charger la livraison';
const String _kRetry = 'Réessayer';
const String _kPhoneUnavailable = 'Téléphone indisponible';

class DeliveryTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const DeliveryTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<DeliveryTrackingScreen> createState() =>
      _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState
    extends ConsumerState<DeliveryTrackingScreen> {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _mapReady =
      Completer<GoogleMapController>();

  /// Trajectoire accumulée du livreur depuis l'ouverture de l'écran. Sert à
  /// dessiner la `Polyline` qui suit littéralement les déplacements reçus.
  final List<LatLng> _trail = <LatLng>[];

  /// Dernière position connue du livreur — survit aux erreurs du stream
  /// (on garde le marker affiché à la dernière coordonnée valide).
  LatLng? _lastDriverPosition;

  /// ETA reçu du backend (champ `eta` du payload) — sinon on calcule
  /// localement via Haversine.
  double? _lastBackendEta;

  /// Destination du client (extrait de [Delivery.destinationLatitude/Longitude]).
  /// Vaut `null` tant que la livraison n'est pas chargée. On retombe sur le
  /// fallback `_kFallbackDestination` si la commande n'a pas de coords géocodées.
  LatLng? _destination;

  /// Coords du restaurant (marker secondaire). `null` si absent.
  LatLng? _restaurant;

  /// Indique si on a déjà recentré la caméra une première fois (au 1er event).
  bool _hasFittedBounds = false;

  /// Statut courant venant du stream `order:status` (overlay supérieur).
  /// `null` tant qu'aucun event n'est arrivé — on retombe alors sur
  /// `delivery.status` pour l'affichage.
  String? _liveOrderStatus;

  /// Toggle local du bottom sheet (collapsed/expanded).
  bool _bottomSheetExpanded = true;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────
  // Stream handlers
  // ──────────────────────────────────────────────────────────────────────

  void _onDriverPosition(DriverPositionEvent event) {
    if (!mounted) return;
    final pos = LatLng(event.lat, event.lng);
    setState(() {
      _lastDriverPosition = pos;
      _lastBackendEta = event.etaMinutes;
      _trail.add(pos);
    });
    developer.log(
      'driver:position lat=${event.lat} lng=${event.lng} eta=${event.etaMinutes}',
      name: _kLogName,
    );
    if (!_hasFittedBounds) {
      _hasFittedBounds = true;
      _animateCameraToFit(pos, _destination ?? _kFallbackDestination);
    }
  }

  void _onPositionStreamError(Object error) {
    developer.log(
      'orderTrackingStream error: $error',
      name: _kLogName,
      error: error,
    );
    if (!mounted) return;
    // Pas de crash : on conserve la dernière position et on informe l'utilisateur.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_kStreamErrorMessage)),
    );
  }

  void _onOrderStatus(OrderStatusEvent event) {
    if (!mounted) return;
    developer.log(
      'order:status status=${event.status}',
      name: _kLogName,
    );
    setState(() => _liveOrderStatus = event.status);
  }

  Future<void> _animateCameraToFit(LatLng a, LatLng b) async {
    final controller = await _mapReady.future;
    final bounds = LatLngBounds(
      southwest: LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      ),
      northeast: LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      ),
    );
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, _kBoundsPadding),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final deliveryAsync = ref.watch(deliveryByOrderProvider(widget.orderId));

    return deliveryAsync.when(
      loading: () => Scaffold(
        appBar: _buildAppBar(context, null),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: _buildAppBar(context, null),
        body: _ErrorView(
          message: _kLoadingError,
          detail: err.toString(),
          onRetry: () => ref.invalidate(deliveryByOrderProvider(widget.orderId)),
        ),
      ),
      data: (delivery) => _buildLoaded(context, delivery),
    );
  }

  Widget _buildLoaded(BuildContext context, Delivery delivery) {
    // Pas de mission active → écran d'attente, pas de carte.
    if (_isNotInTrackingState(delivery)) {
      return Scaffold(
        appBar: _buildAppBar(context, delivery),
        body: _NoActiveMissionView(delivery: delivery),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context, delivery),
      body: Stack(
        children: [
          // ─── Carte (plein écran) ────────────────────────────────────────
          _buildMap(delivery),

          // ─── Live position stream listener (invisible) ──────────────────
          _PositionStreamListener(
            orderId: widget.orderId,
            onEvent: _onDriverPosition,
            onError: _onPositionStreamError,
          ),

          // ─── Live status stream listener (invisible) ────────────────────
          _StatusStreamListener(
            orderId: widget.orderId,
            onEvent: _onOrderStatus,
          ),

          // ─── Bandeau statut supérieur ───────────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _StatusBanner(
              status: _liveOrderStatus ?? delivery.status.wireValue,
            ),
          ),

          // ─── Bottom sheet livreur + ETA ─────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _DelivererBottomSheet(
              delivery: delivery,
              expanded: _bottomSheetExpanded,
              etaText: _computeEtaText(),
              onToggle: () => setState(
                () => _bottomSheetExpanded = !_bottomSheetExpanded,
              ),
              onViewDelivererFile: () => _openDelivererProfile(delivery),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // AppBar
  // ──────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, Delivery? delivery) {
    final shortId = widget.orderId.length >= 8
        ? widget.orderId.substring(0, 8)
        : widget.orderId;
    return AppBar(
      title: Text('$_kTitlePrefix$shortId'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Iconsax.user),
          tooltip: _kViewDelivererFile,
          onPressed: () => _openDelivererProfile(delivery),
        ),
      ],
    );
  }

  void _openDelivererProfile(Delivery? delivery) {
    final id = delivery?.delivererId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_kNoDelivererAssigned)),
      );
      return;
    }
    context.push('/deliverers/$id');
  }

  // ──────────────────────────────────────────────────────────────────────
  // Map
  // ──────────────────────────────────────────────────────────────────────

  Widget _buildMap(Delivery delivery) {
    // Résout les coords destination + resto à partir du modèle (1ère fois).
    _destination ??= delivery.hasDestinationCoords
        ? LatLng(delivery.destinationLatitude!, delivery.destinationLongitude!)
        : _kFallbackDestination;
    if (_restaurant == null &&
        delivery.restaurantLatitude != null &&
        delivery.restaurantLongitude != null) {
      _restaurant =
          LatLng(delivery.restaurantLatitude!, delivery.restaurantLongitude!);
    }

    final destination = _destination!;
    final markers = <Marker>{};

    if (_lastDriverPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _lastDriverPosition!,
        // Choix : couleur orange (cohérent avec la brand) — placeholder
        // jusqu'à un asset moto/scooter custom (out of scope LIL-86).
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: delivery.delivererNom ?? 'Livreur',
        ),
      ));
    }

    markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: destination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Adresse de livraison'),
    ));

    if (_restaurant != null) {
      markers.add(Marker(
        markerId: const MarkerId('restaurant'),
        position: _restaurant!,
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
          title: delivery.restaurantNom ?? 'Restaurant',
        ),
      ));
    }

    final polylines = <Polyline>{};
    if (_trail.length >= 2) {
      polylines.add(Polyline(
        polylineId: const PolylineId('trail'),
        points: List<LatLng>.unmodifiable(_trail),
        color: Theme.of(context).colorScheme.primary,
        width: 4,
      ));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: destination,
        zoom: _kInitialZoom,
      ),
      markers: markers,
      polylines: polylines,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      onMapCreated: (c) {
        _mapController = c;
        if (!_mapReady.isCompleted) _mapReady.complete(c);
        // Si on n'a pas encore reçu de position livreur, recentre quand même
        // sur la destination réelle (et le resto si dispo) au 1er rendu.
        if (_lastDriverPosition == null && !_hasFittedBounds) {
          _hasFittedBounds = true;
          if (_restaurant != null) {
            _animateCameraToFit(_restaurant!, destination);
          }
        }
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // ETA
  // ──────────────────────────────────────────────────────────────────────

  String _computeEtaText() {
    // Priorité 1 : ETA backend (event payload).
    if (_lastBackendEta != null && _lastBackendEta! > 0) {
      return '${_lastBackendEta!.round()} $_kEtaSuffix';
    }
    // Priorité 2 : calcul local Haversine à partir de la dernière position.
    final driver = _lastDriverPosition;
    final destination = _destination;
    if (driver != null && destination != null) {
      final km = haversineKm(
        driver.latitude,
        driver.longitude,
        destination.latitude,
        destination.longitude,
      );
      return '${etaMinutes(km)} $_kEtaSuffix';
    }
    return _kEtaUnknown;
  }

  // ──────────────────────────────────────────────────────────────────────
  // Logique métier — état tracking actif
  // ──────────────────────────────────────────────────────────────────────

  /// `true` si on doit afficher l'écran d'attente "pas en livraison" plutôt
  /// que la carte. La carte n'a de sens que pour [DeliveryStatus.assigner]
  /// (livreur accepté) et [DeliveryStatus.enTransit].
  bool _isNotInTrackingState(Delivery delivery) {
    if (delivery.delivererId == null) return true;
    switch (delivery.status) {
      case DeliveryStatus.assigner:
      case DeliveryStatus.enTransit:
        return false;
      case DeliveryStatus.enAttente:
      case DeliveryStatus.livrer:
      case DeliveryStatus.echec:
        return true;
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ════════════════════════════════════════════════════════════════════════════

/// Listener invisible qui consomme [orderTrackingStreamProvider] et délègue
/// les events au screen state. Isolé en widget pour pouvoir consommer le
/// provider via `ref.listen` sans rebuild la carte à chaque event.
class _PositionStreamListener extends ConsumerWidget {
  final String orderId;
  final void Function(DriverPositionEvent) onEvent;
  final void Function(Object) onError;

  const _PositionStreamListener({
    required this.orderId,
    required this.onEvent,
    required this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<DriverPositionEvent>>(
      orderTrackingStreamProvider(orderId),
      (prev, next) {
        next.whenOrNull(
          data: onEvent,
          error: (e, _) => onError(e),
        );
      },
    );
    return const SizedBox.shrink();
  }
}

class _StatusStreamListener extends ConsumerWidget {
  final String orderId;
  final void Function(OrderStatusEvent) onEvent;

  const _StatusStreamListener({
    required this.orderId,
    required this.onEvent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<OrderStatusEvent>>(
      orderStatusStreamProvider(orderId),
      (prev, next) {
        next.whenOrNull(data: onEvent);
      },
    );
    return const SizedBox.shrink();
  }
}

/// Card translucide en haut de la carte affichant le statut courant.
/// Quand le statut est `LIVRER`, on remplace par un banner "terminé".
class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDelivered = status == 'LIVRER';

    final (label, bg, fg) = _styleFor(status, cs);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: cs.surface.withAlpha(235),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isDelivered ? _kDeliveryCompleted : label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (isDelivered)
              Icon(Icons.check_circle, color: cs.primary, size: 22),
          ],
        ),
      ),
    );
  }

  /// Mappe un statut backend → (label FR, couleur point, couleur texte).
  /// Utilise exclusivement le `ColorScheme` courant (zéro hardcode).
  (String, Color, Color) _styleFor(String status, ColorScheme cs) {
    switch (status) {
      case 'EN_ATTENTE':
        return ('En attente', cs.tertiary, cs.onSurface);
      case 'PAYER':
        return ('Payée', cs.secondary, cs.onSurface);
      case 'EN_PREPARATION':
        return ('En préparation', cs.primary, cs.onSurface);
      case 'PRET':
        return ('Prête', cs.primary, cs.onSurface);
      case 'EN_ROUTE':
        return ('En route', cs.primary, cs.onSurface);
      case 'LIVRER':
        return ('Livrée', cs.primary, cs.onSurface);
      case 'ANNULER':
        return ('Annulée', cs.error, cs.onSurface);
      default:
        return (status, cs.outline, cs.onSurface);
    }
  }
}

/// Bottom sheet collapsible — infos livreur + ETA + bouton fiche livreur.
///
/// Volontairement minimaliste : on n'a que `delivererId` côté modèle Delivery
/// pour l'instant. L'enrichissement (nom/téléphone/avatar) viendra quand on
/// composera avec `delivererDetailProvider` (out of scope LIL-86 — voir
/// LIL-87 pour la fiche complète).
class _DelivererBottomSheet extends StatelessWidget {
  final Delivery delivery;
  final bool expanded;
  final String etaText;
  final VoidCallback onToggle;
  final VoidCallback onViewDelivererFile;

  const _DelivererBottomSheet({
    required this.delivery,
    required this.expanded,
    required this.etaText,
    required this.onToggle,
    required this.onViewDelivererFile,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasDeliverer = delivery.delivererId != null;
    final delivererLabel = delivery.delivererNom?.trim().isNotEmpty == true
        ? delivery.delivererNom!
        : (hasDeliverer
            ? '#${delivery.delivererId!.substring(0, delivery.delivererId!.length >= 8 ? 8 : delivery.delivererId!.length)}'
            : _kNoDelivererAssigned);
    final hasPhone = delivery.delivererPhone?.trim().isNotEmpty == true;
    final avatarUrl = delivery.delivererImageUrl;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            // En-tête (toujours visible)
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Icon(
                          Iconsax.user,
                          color: cs.onPrimaryContainer,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _kDelivererCardTitle,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        delivererLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                _EtaPill(etaText: etaText),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: hasPhone
                          ? () => _callDeliverer(context)
                          : null,
                      icon: const Icon(Iconsax.call),
                      label: const Text(_kCallButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: hasDeliverer ? onViewDelivererFile : null,
                      icon: const Icon(Iconsax.user_search),
                      label: const Text(_kViewDelivererFile),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _callDeliverer(BuildContext context) async {
    final phone = delivery.delivererPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_kPhoneUnavailable)),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e, st) {
      developer.log('launchPhone failed: $e',
          name: 'DeliveryTrackingScreen', error: e, stackTrace: st);
    }
  }
}

class _EtaPill extends StatelessWidget {
  final String etaText;
  const _EtaPill({required this.etaText});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.clock, size: 16, color: cs.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            etaText,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _NoActiveMissionView extends StatelessWidget {
  final Delivery delivery;

  const _NoActiveMissionView({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.location_slash, size: 72, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              _kNoMissionTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _kNoMissionBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Chip(
              label: Text('Statut : ${delivery.status.wireValue}'),
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.warning_2, size: 64, color: cs.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Iconsax.refresh),
              label: const Text(_kRetry),
            ),
          ],
        ),
      ),
    );
  }
}

