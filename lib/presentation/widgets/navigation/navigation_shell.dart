import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_theme.dart';
import '../../providers/auth/auth_providers.dart';
import 'app_sidebar.dart';

/// The shell widget used by ShellRoute. Provides the responsive layout:
/// - Desktop (≥768px): fixed sidebar + content area side by side
/// - Mobile (<768px): Scaffold with drawer + hamburger menu
///
/// Receives [child] from go_router (the active page widget).
class NavigationShell extends ConsumerWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    if (isDesktop) {
      return Row(
        children: [
          AppSidebar(
            currentRoute: location,
            onItemTap: (route) => context.go(route),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Scaffold(
              appBar: _buildAppBar(ref, showHamburger: false),
              body: child,
            ),
          ),
        ],
      );
    }

    // Mobile layout
    return Scaffold(
      appBar: _buildAppBar(ref, showHamburger: true),
      drawer: AppSidebar(
        currentRoute: location,
        onItemTap: (route) {
          Navigator.of(context).pop(); // close drawer
          context.go(route);
        },
      ),
      body: child,
    );
  }

  AppBar _buildAppBar(WidgetRef ref, {required bool showHamburger}) {
    return AppBar(
      leading: showHamburger
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,
      automaticallyImplyLeading: false,
      title: const Row(
        children: [
          Icon(Icons.eco, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Monitoreo de Plantas'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: () => ref.read(logoutProvider)(),
        ),
      ],
    );
  }
}
