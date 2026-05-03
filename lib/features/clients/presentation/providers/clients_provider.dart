import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lilia_admin/features/clients/data/client_repository.dart';
import 'package:lilia_admin/models/app_user.dart';

part 'clients_provider.g.dart';

// On instancie le repository ici pour qu'il soit accessible
@riverpod
ClientRepository clientRepository(Ref ref) {
  return ClientRepository();
}

// Provider pour récupérer la liste des clients d'un restaurant
@riverpod
Future<List<AppUser>> restaurantClients(Ref ref, String restaurantId) {
  final clientRepository = ref.watch(clientRepositoryProvider);
  return clientRepository.fetchClients(restaurantId);
}

// Provider pour récupérer tous les clients de la plateforme (ADMIN uniquement)
@riverpod
Future<List<AppUser>> allClients(Ref ref) {
  final clientRepository = ref.watch(clientRepositoryProvider);
  return clientRepository.fetchAllClients();
}
