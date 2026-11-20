import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/reservations/data/reservation_settings_repository.dart';
import 'package:lilia_admin/utils/api_response.dart';

/// Lot 4 (4C) — l'agenda des réservations du restaurant.
///
/// `GET /vendors/me/reservations`, `GET …/:id` et les gestes `accept`,
/// `decline`, `cancel`, `no-show`, `undo-no-show`, `reassign`. Le serveur
/// borne tout au restaurant du compte connecté et publie, sur chaque
/// réservation, les gestes qu'il acceptera (`allowedActions`) : l'app affiche
/// ce verdict, elle ne recopie jamais la machine d'états (règle 2).
class ReservationAgendaRepository {
  ReservationAgendaRepository(this._api);

  final ApiClient _api;

  static const _path = '/vendors/me/reservations';

  /// Une page de l'agenda. [date] = jour civil de Brazzaville (AAAA-MM-JJ),
  /// [status] = un statut serveur ; absents, toutes les réservations.
  Future<ReservationAgendaPage> list({
    String? date,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _api.getJson(
      _path,
      query: {
        'page': '$page',
        'limit': '$limit',
        'date': ?date,
        'status': ?status,
      },
    );
    final raw = res.data;
    final meta = raw is Map<String, dynamic> ? _m(raw['meta']) : const {};
    final items = ApiResponse.listOf(raw)
        .whereType<Map<String, dynamic>>()
        .map(VendorReservation.fromJson)
        .toList(growable: false);
    return ReservationAgendaPage(
      items: items,
      total: _i(meta['total'], items.length),
    );
  }

  Future<VendorReservation> get(String id) async {
    final res = await _api.getJson('$_path/$id');
    return VendorReservation.fromJson(ApiResponse.mapOf(res.data));
  }

  Future<VendorReservation> accept(String id) => _gesture(id, 'accept');

  Future<VendorReservation> decline(String id, String reason) =>
      _gesture(id, 'decline', {'reason': reason});

  Future<VendorReservation> cancel(String id, String reason) =>
      _gesture(id, 'cancel', {'reason': reason});

  Future<VendorReservation> markNoShow(String id) => _gesture(id, 'no-show');

  Future<VendorReservation> undoNoShow(String id) =>
      _gesture(id, 'undo-no-show');

  Future<VendorReservation> reassign(String id, String spaceId) =>
      _gesture(id, 'reassign', {'spaceId': spaceId});

  Future<VendorReservation> _gesture(
    String id,
    String gesture, [
    Map<String, dynamic>? body,
  ]) async {
    final res = await _api.postJson('$_path/$id/$gesture', body: body ?? {});
    return VendorReservation.fromJson(ApiResponse.mapOf(res.data));
  }
}

/// Gestes publiés par le serveur (`vendorAllowedActions`). Vocabulaire
/// fermé : une valeur inconnue est ignorée plutôt que devinée.
enum VendorReservationAction {
  accept('accept'),
  decline('decline'),
  cancel('cancel'),
  noShow('noShow'),
  undoNoShow('undoNoShow'),
  reassign('reassign');

  const VendorReservationAction(this.wire);
  final String wire;

  static List<VendorReservationAction> listFromWire(Object? raw) => raw is List
      ? [
          for (final v in raw)
            for (final a in values)
              if (a.wire == v) a,
        ]
      : const [];
}

String reservationStatusLabel(String status) => switch (status) {
  'PENDING' => 'Demande à traiter',
  'AWAITING_PAYMENT' => 'Acceptée — attente du paiement',
  'CONFIRMED' => 'Confirmée (payée)',
  'DECLINED' => 'Refusée',
  'EXPIRED' => 'Expirée',
  'CANCELLED_BY_CLIENT' => 'Annulée par le client',
  'CANCELLED_BY_VENDOR' => 'Annulée par le restaurant',
  'HONORED' => 'Honorée',
  'NO_SHOW' => 'Client absent',
  _ => status,
};

/// Motifs de refus d'une demande — liste fermée du serveur
/// (`RESERVATION_DECLINE_REASONS`), dans l'ordre d'affichage.
const reservationDeclineReasons = <String, String>{
  'FULLY_BOOKED': 'Complet à cette heure',
  'CLOSED': 'Fermé ce jour-là',
  'ITEMS_UNAVAILABLE': 'Plats précommandés indisponibles',
  'PARTY_TOO_LARGE': 'Groupe trop nombreux',
  'OTHER': 'Autre raison',
};

/// Motifs d'annulation par le restaurant (`RESERVATION_VENDOR_CANCEL_REASONS`).
const reservationVendorCancelReasons = <String, String>{
  'CLOSED_UNEXPECTEDLY': 'Fermeture imprévue',
  'ITEMS_UNAVAILABLE': 'Plats précommandés indisponibles',
  'OVERBOOKED': 'Trop de réservations',
  'CLIENT_REQUEST': 'À la demande du client',
  'OTHER': 'Autre raison',
};

/// Libellé d'un motif enregistré, refus ou annulation (le client peut aussi
/// annuler : son motif n'est pas dans ces listes).
String reservationReasonLabel(String reason) =>
    reservationDeclineReasons[reason] ??
    reservationVendorCancelReasons[reason] ??
    reason;

int _i(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
int? _iOrNull(Object? v) => v is num ? v.toInt() : null;
String _s(Object? v) => v is String ? v : '';
String? _sOrNull(Object? v) => v is String && v.isNotEmpty ? v : null;
/// Instant UTC du serveur ; l'affichage passe par `toBrazzaville`.
DateTime? _d(Object? v) => v is String ? DateTime.tryParse(v) : null;
Map<String, dynamic> _m(Object? v) =>
    v is Map<String, dynamic> ? v : const <String, dynamic>{};
List<Map<String, dynamic>> _l(Object? v) => v is List
    ? v.whereType<Map<String, dynamic>>().toList(growable: false)
    : const [];

class ReservationAgendaPage {
  const ReservationAgendaPage({required this.items, required this.total});

  final List<VendorReservation> items;

  /// Total serveur (toutes pages) : un compteur ne lit jamais `items.length`.
  final int total;
}

/// Client de la réservation. Nom et numéro sont masqués par le serveur
/// (R-TEL) pour une demande refusée ou expirée, et 30 jours après l'issue.
class ReservationCustomer {
  const ReservationCustomer({this.id, this.nom, this.phone});

  factory ReservationCustomer.fromJson(Map<String, dynamic> j) =>
      ReservationCustomer(
        id: _sOrNull(j['id']),
        nom: _sOrNull(j['nom']),
        phone: _sOrNull(j['phone']),
      );

  final String? id;
  final String? nom;
  final String? phone;

  bool get hidden => nom == null && phone == null;
}

class ReservationItemOption {
  const ReservationItemOption({required this.name, required this.quantity});

  factory ReservationItemOption.fromJson(Map<String, dynamic> j) =>
      ReservationItemOption(
        name: _s(j['optionName']),
        quantity: _i(j['quantity'], 1),
      );

  final String name;
  final int quantity;
}

/// Ligne précommandée, figée à la demande.
class ReservationItem {
  const ReservationItem({
    required this.name,
    required this.quantity,
    this.variantLabel,
    this.indicativeLineTotal,
    this.options = const [],
  });

  factory ReservationItem.fromJson(Map<String, dynamic> j) => ReservationItem(
    name: _sOrNull(j['menuName']) ?? _s(j['productName']),
    quantity: _i(j['quantite'], 1),
    variantLabel: _sOrNull(j['variantLabel']),
    indicativeLineTotal: _iOrNull(j['indicativeLineTotal']),
    options: _l(j['options']).map(ReservationItemOption.fromJson).toList(),
  );

  final String name;
  final int quantity;
  final String? variantLabel;

  /// Part indicative de la ligne (XAF), jamais facturée.
  final int? indicativeLineTotal;
  final List<ReservationItemOption> options;
}

/// Commande liée, créée à l'acceptation. Montants réels en XAF entiers.
class ReservationPayment {
  const ReservationPayment({
    required this.orderId,
    required this.orderStatus,
    required this.subTotal,
    required this.serviceFee,
    required this.total,
    required this.priceChanged,
    this.indicativeSubTotal,
  });

  factory ReservationPayment.fromJson(Map<String, dynamic> j) =>
      ReservationPayment(
        orderId: _s(j['orderId']),
        orderStatus: _s(j['orderStatus']),
        subTotal: _i(j['subTotal']),
        serviceFee: _i(j['serviceFee']),
        total: _i(j['total']),
        indicativeSubTotal: _iOrNull(j['indicativeSubTotal']),
        priceChanged: j['priceChanged'] == true,
      );

  final String orderId;
  final String orderStatus;
  final int subTotal;
  final int serviceFee;
  final int total;
  final int? indicativeSubTotal;

  /// Le montant réel diffère de l'indicatif de la demande (jamais en silence).
  final bool priceChanged;
}

class ReservationSpaceRef {
  const ReservationSpaceRef({
    required this.id,
    required this.kind,
    required this.label,
  });

  factory ReservationSpaceRef.fromJson(Map<String, dynamic> j) =>
      ReservationSpaceRef(
        id: _s(j['id']),
        kind: ReservationSpaceKind.parse(j['kind']),
        label: _s(j['label']),
      );

  final String id;
  final ReservationSpaceKind kind;
  final String label;
}

/// Une réservation telle que le restaurant la voit (`toVendorView`).
class VendorReservation {
  const VendorReservation({
    required this.id,
    required this.status,
    required this.customer,
    required this.partySize,
    required this.arrivalAt,
    required this.space,
    required this.items,
    required this.allowedActions,
    this.endsAt,
    this.note,
    this.declineReason,
    this.cancelReason,
    this.payment,
    this.createdAt,
    this.responseDeadlineAt,
    this.paymentDeadlineAt,
    this.noShowAt,
  });

  factory VendorReservation.fromJson(Map<String, dynamic> j) {
    final payment = j['payment'];
    return VendorReservation(
      id: _s(j['id']),
      status: _s(j['status']),
      customer: ReservationCustomer.fromJson(_m(j['customer'])),
      partySize: _i(j['partySize'], 1),
      arrivalAt: _d(j['arrivalAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      endsAt: _d(j['endsAt']),
      space: ReservationSpaceRef.fromJson(_m(j['space'])),
      note: _sOrNull(j['note']),
      declineReason: _sOrNull(j['declineReason']),
      cancelReason: _sOrNull(j['cancelReason']),
      items: _l(j['items']).map(ReservationItem.fromJson).toList(),
      payment: payment is Map<String, dynamic>
          ? ReservationPayment.fromJson(payment)
          : null,
      createdAt: _d(j['createdAt']),
      responseDeadlineAt: _d(j['responseDeadlineAt']),
      paymentDeadlineAt: _d(j['paymentDeadlineAt']),
      noShowAt: _d(j['noShowAt']),
      allowedActions: VendorReservationAction.listFromWire(
        j['allowedActions'],
      ),
    );
  }

  final String id;
  final String status;
  final ReservationCustomer customer;
  final int partySize;
  final DateTime arrivalAt;
  final DateTime? endsAt;
  final ReservationSpaceRef space;
  final String? note;
  final String? declineReason;
  final String? cancelReason;
  final List<ReservationItem> items;

  /// `null` tant que le restaurant n'a pas accepté (pas encore de commande).
  final ReservationPayment? payment;
  final DateTime? createdAt;

  /// Demande : sans réponse à cette heure, elle expire.
  final DateTime? responseDeadlineAt;

  /// Acceptée : le client doit payer avant cette heure.
  final DateTime? paymentDeadlineAt;
  final DateTime? noShowAt;
  final List<VendorReservationAction> allowedActions;

  bool can(VendorReservationAction a) => allowedActions.contains(a);
}
