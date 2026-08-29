import 'package:flutter/material.dart';
import 'package:lilia_admin/core/network/api_client.dart';
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

@riverpod
class UserDataSynchronizer extends _$UserDataSynchronizer {
  @override
  Future<void> build() async {
    ref.listen(firebaseIdTokenProvider, (previous, next) {
      // Différé hors de la phase de build : Riverpod interdit qu'un provider
      // en modifie un autre pendant son initialisation. Or `fireImmediately`
      // déclenche ce callback dès le build, et la branche déconnectée écrit
      // synchroniquement dans currentUserProfileProvider.
      Future.microtask(() async {
        final token = next.value;

      if (token != null) {
        debugPrint('Jeton détecté: OK. Synchronisation du profil utilisateur.');
        try {
          final api = ref.read(apiClientProvider);
          // 1. Sync user via POST /users/sync
          final syncRes = await api.postJson('/users/sync');
          // /users/sync renvoie `{ user, isNewUser }` → enveloppé
          // `{ data: { user, isNewUser } }` par l'interceptor backend.
          final userData =
              ApiResponse.mapOf(syncRes.data)['user'] as Map<String, dynamic>?;

          if (userData != null) {
            var user = AppUser.fromJson(userData);

            // 2. Récupérer le restaurant via GET /restaurants/mine
            try {
              final restRes = await api.getJson('/restaurants/mine');
              final restJson = (restRes.data as Map<String, dynamic>)['data']
                  as Map<String, dynamic>?;
              if (restJson != null) {
                user = user.copyWith(restaurant: Restaurant.fromJson(restJson));
              }
            } catch (e) {
              debugPrint('Pas de restaurant associé ou erreur: $e');
            }

            ref.read(currentUserProfileProvider.notifier).setUser(user);
            debugPrint('Synchronisation réussie.');

            // Contexte Sentry : rattacher les erreurs à l'utilisateur
            // connecté et à son rôle (ADMIN / RESTAURATEUR).
            await Sentry.configureScope(
              (scope) => scope.setUser(
                SentryUser(
                  id: user.id ?? user.uid,
                  email: user.email,
                  data: {'role': user.role?.name ?? 'unknown'},
                ),
              ),
            );

            // Enregistrer le token FCM
            await ref
                .read(notificationServiceProvider)
                .registerTokenOnServer();
          } else {
            debugPrint('user est null dans la réponse sync');
          }
        } catch (e) {
          debugPrint('Erreur lors de la synchronisation: $e');
        }
      } else {
        // NB : le détachement du device (DELETE /notifications/token) se fait
        // dans `AuthController.signOut()`, pendant que le token Firebase est
        // encore valide — ici il est déjà révoqué.
        ref.read(currentUserProfileProvider.notifier).clear();
        // Purger le contexte Sentry au logout.
        await Sentry.configureScope((scope) => scope.setUser(null));
        debugPrint("L'utilisateur est déconnecté, aucun jeton disponible.");
      }
      });
    }, fireImmediately: true);
  }
}
