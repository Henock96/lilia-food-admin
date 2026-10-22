import 'package:flutter/material.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/auth/repository/firebase_auth_repository.dart';
import 'package:lilia_admin/features/auth/app_user_model.dart';
import 'package:lilia_admin/models/restaurant.dart';
import 'package:lilia_admin/services/notification_service.dart';
import 'package:lilia_admin/utils/api_response.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'user_sync_provider.g.dart';

/// Provider qui stocke le profil utilisateur complet (incluant le restaurant)
@Riverpod(keepAlive: true)
class CurrentUserProfile extends _$CurrentUserProfile {
  @override
  AppUser? build() {
    return null;
  }

  void setUser(AppUser? user) {
    state = user;
  }

  void clear() {
    state = null;
  }
}

/// Lot 4 (ADM-07) — où en est la synchronisation du profil.
///
/// Avant, un échec de `/users/sync` finissait dans un `debugPrint` : le profil
/// restait `null` à vie, les routes ADMIN tournaient sans fin et rien ne
/// proposait de réessayer. Les gardes du routeur lisent désormais cet état.
enum ProfileSyncPhase { idle, loading, ready, failed }

class ProfileSyncState {
  const ProfileSyncState(this.phase, [this.message]);

  final ProfileSyncPhase phase;

  /// Message affichable, seulement en échec.
  final String? message;

  bool get failed => phase == ProfileSyncPhase.failed;
}

@Riverpod(keepAlive: true)
class ProfileSyncStatus extends _$ProfileSyncStatus {
  @override
  ProfileSyncState build() => const ProfileSyncState(ProfileSyncPhase.idle);

  void set(ProfileSyncState value) => state = value;
}

const kProfileSyncFailedMessage =
    'Impossible de charger votre profil. Vérifiez votre connexion et réessayez.';

/// `POST /users/sync` puis `GET /restaurants/mine`. Surchargeable en test.
///
/// 404 sur `/restaurants/mine` = pas de boutique (ADMIN) : profil sans
/// restaurant. Toute autre erreur fait échouer la synchronisation — un
/// vendeur ne travaille pas sans sa boutique, et l'ancien `catch` qui avalait
/// tout le laissait devant une app vide sans le lui dire.
@Riverpod(keepAlive: true)
Future<AppUser?> Function() profileLoader(Ref ref) => () async {
  final api = ref.read(apiClientProvider);
  final syncRes = await api.postJson('/users/sync');
  // /users/sync renvoie `{ user, isNewUser }` → enveloppé
  // `{ data: { user, isNewUser } }` par l'interceptor backend.
  final userData =
      ApiResponse.mapOf(syncRes.data)['user'] as Map<String, dynamic>?;
  if (userData == null) return null;

  var user = AppUser.fromJson(userData);
  try {
    final restRes = await api.getJson('/restaurants/mine');
    final restJson =
        (restRes.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (restJson != null) {
      user = user.copyWith(restaurant: Restaurant.fromJson(restJson));
    }
  } on ApiException catch (e) {
    if (e.statusCode != 404) rethrow;
  }
  return user;
};

/// Effets d'un profil chargé : contexte Sentry, enregistrement du jeton FCM.
/// Surchargeable en test (FCM touche le plugin natif).
@Riverpod(keepAlive: true)
Future<void> Function(AppUser user) onProfileSynced(Ref ref) => (user) async {
  // Contexte Sentry : rattacher les erreurs à l'utilisateur connecté et à son
  // rôle (ADMIN / RESTAURATEUR).
  await Sentry.configureScope(
    (scope) => scope.setUser(
      SentryUser(
        id: user.id ?? user.uid,
        email: user.email,
        data: {'role': user.role?.name ?? 'unknown'},
      ),
    ),
  );
  await ref.read(notificationServiceProvider).registerTokenOnServer();
};

/// Effets d'une déconnexion côté profil. Surchargeable en test.
@Riverpod(keepAlive: true)
Future<void> Function() onProfileCleared(Ref ref) =>
    () async => Sentry.configureScope((scope) => scope.setUser(null));

@riverpod
class UserDataSynchronizer extends _$UserDataSynchronizer {
  /// Compte dont le profil est chargé (ou en cours de chargement).
  String? _syncedUid;

  @override
  Future<void> build() async {
    // Lot 4 (ADM-26) — sur l'état de connexion, plus sur le jeton. Branché
    // sur `idTokenChanges`, la synchronisation (`/users/sync`,
    // `/restaurants/mine`, enregistrement FCM) repartait à chaque
    // rafraîchissement horaire du jeton. Elle n'a lieu qu'à la connexion, au
    // changement de compte, et à la demande ([resync]).
    ref.listen(authStateChangeProvider, (previous, next) {
      if (next.isLoading && !next.hasValue) return;
      final uid = next.value?.uid;
      // Différé hors de la phase de build : Riverpod interdit qu'un provider
      // en modifie un autre pendant son initialisation.
      Future.microtask(() => _onSession(uid));
    }, fireImmediately: true);
  }

  Future<void> _onSession(String? uid) async {
    if (uid == null) {
      _syncedUid = null;
      // NB : le détachement du device (DELETE /notifications/token) se fait
      // dans `AuthController.signOut()`, pendant que le token Firebase est
      // encore valide — ici il est déjà révoqué.
      ref.read(currentUserProfileProvider.notifier).clear();
      ref
          .read(profileSyncStatusProvider.notifier)
          .set(const ProfileSyncState(ProfileSyncPhase.idle));
      await ref.read(onProfileClearedProvider)();
      return;
    }
    if (uid == _syncedUid) return;
    _syncedUid = uid;
    await _sync(uid);
  }

  /// Relance la synchronisation du compte courant (bouton « Réessayer »,
  /// vendeur approuvé par push).
  Future<void> resync() async {
    final uid = _syncedUid;
    if (uid == null) return;
    await _sync(uid);
  }

  Future<void> _sync(String uid) async {
    final status = ref.read(profileSyncStatusProvider.notifier);
    status.set(const ProfileSyncState(ProfileSyncPhase.loading));
    try {
      final user = await ref.read(profileLoaderProvider)();
      // Un autre compte s'est connecté entre-temps : ce résultat est périmé.
      if (_syncedUid != uid) return;
      if (user == null) {
        status.set(
          const ProfileSyncState(
            ProfileSyncPhase.failed,
            kProfileSyncFailedMessage,
          ),
        );
        return;
      }
      ref.read(currentUserProfileProvider.notifier).setUser(user);
      status.set(const ProfileSyncState(ProfileSyncPhase.ready));
    } catch (e) {
      if (_syncedUid != uid) return;
      debugPrint('Erreur lors de la synchronisation: $e');
      status.set(
        ProfileSyncState(
          ProfileSyncPhase.failed,
          e is ApiException ? e.message : kProfileSyncFailedMessage,
        ),
      );
      return;
    }
    // Hors du `try` : un échec d'enregistrement FCM ne rend pas le profil
    // inutilisable.
    try {
      final user = ref.read(currentUserProfileProvider);
      if (user != null) await ref.read(onProfileSyncedProvider)(user);
    } catch (e) {
      debugPrint('Effets post-synchronisation en échec: $e');
    }
  }
}
