import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/auth_controller.dart';
import '../user_sync_provider.dart';

/// Lot 4 (ADM-07) — tant que le profil manque et que sa synchronisation a
/// échoué, montre [ProfileSyncErrorScreen] au lieu de [child]. Utilisé par
/// les deux gardes du routeur.
class ProfileSyncFailureGate extends ConsumerWidget {
  const ProfileSyncFailureGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(currentUserProfileProvider) == null) {
      final sync = ref.watch(profileSyncStatusProvider);
      if (sync.failed) {
        return ProfileSyncErrorScreen(
          message: sync.message ?? kProfileSyncFailedMessage,
        );
      }
    }
    return child;
  }
}

/// Lot 4 (ADM-07) — le profil n'a pas pu être chargé.
///
/// Remplace le spinner sans fin : dire ce qui se passe, proposer de réessayer,
/// et laisser une sortie (se déconnecter) si l'échec persiste.
class ProfileSyncErrorScreen extends ConsumerWidget {
  const ProfileSyncErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading =
        ref.watch(profileSyncStatusProvider).phase == ProfileSyncPhase.loading;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: loading
                      ? null
                      : () => ref
                          .read(userDataSynchronizerProvider.notifier)
                          .resync(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                  child: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
