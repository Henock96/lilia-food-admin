import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lilia_admin/features/clients/data/user_repository.dart';
import 'package:lilia_admin/features/auth/user_sync_provider.dart';
import 'package:lilia_admin/models/role.dart';
import 'package:lilia_admin/models/order.dart';
import 'package:lilia_admin/core/network/api_client.dart';

part 'user_orders_provider.g.dart';

// Provider pour l'instance du UserRepository
@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository(ref.watch(apiClientProvider));
}

// Provider pour récupérer la liste des commandes d'un utilisateur
@riverpod
Future<List<Order>> userOrders(Ref ref, String userId) async {
  final userRepository = ref.watch(userRepositoryProvider);
  final currentUser = ref.watch(currentUserProfileProvider);

  // Un admin n'est rattaché à aucun restaurant : il voit toutes les
  // commandes du client, tous restaurants confondus.
  if (currentUser?.role == Role.admin) {
    return userRepository.fetchAllUserOrders(userId);
  }

  final restaurantId = currentUser?.restaurantId;
  if (restaurantId == null) {
    throw Exception('Restaurant non trouvé pour l\'utilisateur connecté');
  }

  return userRepository.fetchUserOrders(restaurantId, userId);
}
