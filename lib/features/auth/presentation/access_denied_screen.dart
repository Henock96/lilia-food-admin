import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/auth_controller.dart';

/// Écran affiché à un compte authentifié qui n'a pas sa place ici.
///
/// L'app admin est réservée aux rôles `RESTAURATEUR` et `ADMIN`. Avant ce
/// garde, un compte `CLIENT` qui s'y connectait accédait à toute l'interface :
/// dashboard, commandes, livreurs, clients. Le backend refusait chaque appel
/// (403), donc aucune donnée ne fuitait — mais l'utilisateur se retrouvait
/// devant une application entièrement vide, sans comprendre pourquoi.
///
/// Mieux vaut lui dire, et lui proposer la seule action utile : se déconnecter
/// pour reprendre avec le bon compte.
class AccessDeniedScreen extends ConsumerWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: cs.error),
              const SizedBox(height: 24),
              Text(
                'Application réservée aux vendeurs',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ce compte est un compte client. Pour commander, utilisez '
                'l\'application Lilia Food. Si vous êtes vendeur, '
                'connectez-vous avec le compte fourni par Lilia.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
