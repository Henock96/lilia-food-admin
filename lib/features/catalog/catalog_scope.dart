import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/role.dart';
import '../admin/data/admin_vendors_service.dart';
import '../admin/presentation/providers/admin_vendors_provider.dart';
import '../auth/user_sync_provider.dart';
import '../restaurant/presentation/providers/restaurant_provider.dart';

part 'catalog_scope.g.dart';

/// Sur QUEL vendeur portent les écrans de catalogue (produits, sections, menus).
///
/// Une seule règle, partagée par les trois écrans, plutôt qu'un
/// `currentRestaurantIdProvider` lu directement partout :
///
///  - **RESTAURATEUR** → son vendeur, et lui seul. Aucun sélecteur affiché : il
///    n'y a rien à choisir, et un champ qu'on ne peut pas changer est un piège.
///  - **ADMIN** → le vendeur qu'il a sélectionné. Il n'en possède aucun, donc
///    sans sélection il n'y a pas de cible : les écrans le disent au lieu
///    d'afficher une liste vide inexplicable.
///
/// C'est ce provider qui alimente le `restaurantId` envoyé au backend — lequel
/// ne l'accepte QUE d'un ADMIN. Envoyer son propre identifiant en tant que
/// RESTAURATEUR renvoyait 403 : la création de produit était cassée pour tous
/// les vendeurs depuis l'ouverture de ce champ aux administrateurs.
@riverpod
class CatalogScope extends _$CatalogScope {
  @override
  String? build() {
    // Un restaurateur n'a pas de choix à faire : son vendeur est le périmètre.
    final own = ref.watch(currentRestaurantIdProvider);
    return own.isEmpty ? null : own;
  }

  /// Réservé à l'ADMIN — un restaurateur ne peut pas changer de périmètre.
  void select(String? restaurantId) {
    if (ref.read(isCatalogAdminProvider)) {
      state = restaurantId;
    }
  }
}

/// L'appelant est-il un ADMIN agissant au nom d'un tiers ?
@riverpod
bool isCatalogAdmin(Ref ref) {
  return ref.watch(currentUserProfileProvider)?.role == Role.admin;
}

/// `restaurantId` à joindre au corps d'une écriture catalogue.
///
/// `null` pour un RESTAURATEUR : le backend déduit alors le vendeur du compte
/// authentifié, et c'est la **seule** règle correcte — un identifiant transmis
/// par un vendeur n'est jamais digne de confiance, donc le backend le refuse
/// plutôt que de le remplacer en silence.
@riverpod
String? catalogTargetRestaurantId(Ref ref) {
  return ref.watch(isCatalogAdminProvider) ? ref.watch(catalogScopeProvider) : null;
}

/// Vendeurs sélectionnables par un ADMIN — **tous**, y compris `DRAFT` et non
/// approuvés.
///
/// `GET /admin/vendors` et non `GET /restaurants` : la route publique ne rend
/// que les commerces déjà publiés, c'est-à-dire l'exact complément de ceux dont
/// l'admin doit remplir le catalogue pour pouvoir les activer.
@riverpod
Future<List<AdminVendorItem>> catalogSelectableVendors(Ref ref) async {
  if (!ref.watch(isCatalogAdminProvider)) return const [];
  return ref.watch(adminVendorsServiceProvider).listVendors(limit: 100);
}

/// Bandeau de sélection du vendeur, affiché **uniquement** à l'ADMIN.
///
/// Posé en tête des écrans produits / sections / menus pour que les trois
/// partagent la même cible : basculer de vendeur sur un écran bascule partout.
class CatalogScopeBar extends ConsumerWidget {
  const CatalogScopeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isCatalogAdminProvider)) return const SizedBox.shrink();

    final vendorsAsync = ref.watch(catalogSelectableVendorsProvider);
    final selected = ref.watch(catalogScopeProvider);

    return vendorsAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Vendeurs indisponibles : $e',
            style: const TextStyle(color: Colors.red)),
      ),
      data: (vendors) {
        if (vendors.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Aucun vendeur. Créez-en un depuis l\'espace admin.'),
          );
        }
        // Première sélection automatique : l'admin arrive sur un écran utile
        // plutôt que sur un état vide qui ressemble à une panne.
        if (selected == null || !vendors.any((v) => v.restaurant.id == selected)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(catalogScopeProvider.notifier).select(vendors.first.restaurant.id);
          });
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: DropdownButtonFormField<String>(
            initialValue:
                vendors.any((v) => v.restaurant.id == selected) ? selected : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Vendeur',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: vendors
                .map((v) => DropdownMenuItem(
                      value: v.restaurant.id,
                      child: Text(
                        v.restaurant.onboardingStatus == 'ACTIVATED'
                            ? v.restaurant.name
                            // Le statut est affiché : l'admin remplit souvent le
                            // catalogue d'un vendeur encore invisible du public,
                            // et doit savoir sur lequel il travaille.
                            : '${v.restaurant.name}  ·  ${v.restaurant.onboardingStatus}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (id) =>
                ref.read(catalogScopeProvider.notifier).select(id),
          ),
        );
      },
    );
  }
}

/// État vide explicite quand aucun vendeur n'est ciblé.
class CatalogScopeEmpty extends StatelessWidget {
  final String quoi;
  const CatalogScopeEmpty({super.key, required this.quoi});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront_outlined, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Sélectionnez un vendeur pour voir ses $quoi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
}
