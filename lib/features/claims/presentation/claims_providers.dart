import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/claims/data/claims_repository.dart';

part 'claims_providers.g.dart';

@riverpod
ClaimsRepository claimsRepository(Ref ref) =>
    ClaimsRepository(ref.watch(apiClientProvider));

@riverpod
Future<List<ClaimRow>> claimsList(Ref ref, {required bool openOnly}) =>
    ref.watch(claimsRepositoryProvider).list(openOnly: openOnly);

/// Fil relu toutes les 30 s tant que l'écran l'observe (pas de WebSocket).
@riverpod
Future<ClaimThread> claimThread(Ref ref, String id) async {
  final thread = await ref.watch(claimsRepositoryProvider).detail(id);
  if (!thread.isClosed) {
    final timer = Timer(const Duration(seconds: 30), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return thread;
}
