import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/role.dart';
import '../auth/controller/auth_controller.dart';
import 'application/profile_controller.dart';


class UserPage extends ConsumerWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mon Profil',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: userState.when(
        data: (user) {
          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(userProfileProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(profileControllerProvider.notifier)
                              .updateProfilePicture();
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: user.imageUrl != null
                                  ? NetworkImage(user.imageUrl!)
                                  : null,
                              child: user.imageUrl == null
                                  ? const Icon(Iconsax.user, size: 50)
                                  : null,
                            ),
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.black87,
                              child: Icon(
                                Icons.add_a_photo,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        user.nom ?? 'Nom',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        user.email,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 5),
                      const Divider(height: 2),
                      // Restaurateur-specific items
                      if (user.role == Role.restaurateur || user.role == Role.admin) ...[
                        ListTile(
                          leading: const Icon(Icons.restaurant_menu_outlined),
                          title: const Text('Mes Menus'),
                          onTap: () => context.goNamed('menus'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.fastfood_outlined),
                          title: const Text('Mes Produits'),
                          onTap: () => context.goNamed('produits'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.category_outlined),
                          title: const Text('Mes Categories'),
                          onTap: () => context.goNamed('categories'),
                        ),
                      ],
                      // Admin-only items
                      if (user.role == Role.admin) ...[
                        const Divider(height: 5),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                          child: Text(
                            'Administration',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.image_outlined),
                          title: const Text('Bannières'),
                          onTap: () => context.goNamed('banners'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.add_business_outlined),
                          title: const Text('Créer un restaurant'),
                          onTap: () => context.goNamed('create-restaurant'),
                        ),
                      ],
                            
                     
                      ListTile(title: const Text("A propos de Lilia Food")),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text('Se déconnecter'),
                          onPressed: () async {
                            await ref
                                .read(authControllerProvider.notifier)
                                .signOut();
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
      ),
    );
  }
}
