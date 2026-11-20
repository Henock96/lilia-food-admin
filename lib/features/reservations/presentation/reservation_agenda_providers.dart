import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/reservations/data/reservation_agenda_repository.dart';

part 'reservation_agenda_providers.g.dart';

@riverpod
ReservationAgendaRepository reservationAgendaRepository(Ref ref) =>
    ReservationAgendaRepository(ref.watch(apiClientProvider));

/// Agenda d'un jour civil (`AAAA-MM-JJ`), toutes réservations confondues.
/// Rafraîchi par les push `reservation_update` (`notification_service`).
@riverpod
Future<ReservationAgendaPage> reservationAgenda(Ref ref, String date) =>
    ref.watch(reservationAgendaRepositoryProvider).list(date: date);

/// Demandes à traiter, tous jours confondus (compteur de l'en-tête).
@riverpod
Future<ReservationAgendaPage> pendingReservations(Ref ref) => ref
    .watch(reservationAgendaRepositoryProvider)
    .list(status: 'PENDING', limit: 100);

@riverpod
Future<VendorReservation> vendorReservation(Ref ref, String id) =>
    ref.watch(reservationAgendaRepositoryProvider).get(id);
