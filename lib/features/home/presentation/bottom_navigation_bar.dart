import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/user_sync_provider.dart';
import '../../../models/role.dart';


class BottomNavigationPage extends ConsumerStatefulWidget {
  const BottomNavigationPage({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends ConsumerState<BottomNavigationPage> {
  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final isAdmin = userProfile?.role == Role.admin;

    // Retour Android : sur un autre onglet que « Stats », revenir à « Stats »
    // au lieu de quitter l'app. Un écran empilé dans l'onglet est dépilé
    // avant (go_router dépile d'abord le navigateur de la branche).
    final onFirstTab = widget.navigationShell.currentIndex == 0;
    return PopScope(
      canPop: onFirstTab,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.navigationShell.goBranch(0);
      },
      child: _buildScaffold(isAdmin),
    );
  }

  Widget _buildScaffold(bool isAdmin) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 70,
        elevation: 0,
        selectedIndex: widget.navigationShell.currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            label: 'Stats',
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
          ),
          const NavigationDestination(
            label: 'Commandes',
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
          ),
          const NavigationDestination(
            label: 'Clients',
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
          ),
          NavigationDestination(
            label: isAdmin ? 'Admin' : 'Paramètres',
            icon: Icon(isAdmin ? Icons.admin_panel_settings_outlined : Icons.settings_outlined),
            selectedIcon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.settings),
          ),
          const NavigationDestination(
            label: 'Profil',
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
          ),
        ],
        onDestinationSelected: _goBranch,
      ),
    );
  }
}
