import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lilia_admin/features/auth/repository/firebase_auth_repository.dart';
import 'package:lilia_admin/features/auth/app_user_model.dart';
import 'package:lilia_admin/models/restaurant.dart';
import 'package:lilia_admin/services/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:lilia_admin/constants/app_constants.dart';
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
    ref.listen(firebaseIdTokenProvider, (previous, next) async {
      final token = next.value;

      if (token != null) {
        debugPrint('Jeton détecté: OK. Synchronisation du profil utilisateur.');
        try {
          // 1. Sync user via POST /users/sync
          final syncResponse = await http.post(
            Uri.parse('${AppConstants.baseUrl}/users/sync'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (syncResponse.statusCode == 200) {
            final syncData = json.decode(utf8.decode(syncResponse.bodyBytes));
            final userData = syncData['user'] as Map<String, dynamic>?;

            if (userData != null) {
              var user = AppUser.fromJson(userData);

              // 2. Récupérer le restaurant via GET /restaurants/mine
              try {
                final restaurantResponse = await http.get(
                  Uri.parse('${AppConstants.baseUrl}/restaurants/mine'),
                  headers: {'Authorization': 'Bearer $token'},
                );

                if (restaurantResponse.statusCode == 200) {
                  final restaurantData = json.decode(
                    utf8.decode(restaurantResponse.bodyBytes),
                  );
                  final restJson =
                      restaurantData['data'] as Map<String, dynamic>?;
                  if (restJson != null) {
                    final restaurant = Restaurant.fromJson(restJson);
                    user = user.copyWith(restaurant: restaurant);
                  }
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
          } else {
            debugPrint('Erreur sync: status ${syncResponse.statusCode}');
          }
        } catch (e) {
          debugPrint('Erreur lors de la synchronisation: $e');
        }
      } else {
        ref.read(currentUserProfileProvider.notifier).clear();
        // Purger le contexte Sentry au logout.
        await Sentry.configureScope((scope) => scope.setUser(null));
        debugPrint("L'utilisateur est déconnecté, aucun jeton disponible.");
      }
    }, fireImmediately: true);
  }
}
