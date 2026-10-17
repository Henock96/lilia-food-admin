import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/reservations/data/reservation_settings_repository.dart';

part 'reservation_settings_providers.g.dart';

@riverpod
ReservationSettingsRepository reservationSettingsRepository(Ref ref) =>
    ReservationSettingsRepository(ref.watch(apiClientProvider));

@riverpod
Future<ReservationState> myReservationSettings(Ref ref) =>
    ref.watch(reservationSettingsRepositoryProvider).mine();
