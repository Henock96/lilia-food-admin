import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/user_sync_provider.dart';

part 'restaurant_provider.g.dart';

/// Provider qui retourne l'ID du restaurant de l'utilisateur connecté.
/// Si l'utilisateur n'a pas de restaurant associé, retourne une chaîne vide.
@riverpod
String currentRestaurantId(Ref ref) {
  final userProfile = ref.watch(currentUserProfileProvider);

  if (userProfile != null && userProfile.restaurantId != null) {
    return userProfile.restaurantId!;
  }

  // Fallback: si pas encore chargé ou pas de restaurant
  return '';
}
