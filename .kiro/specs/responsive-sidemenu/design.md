# Technical Design: Responsive Side Menu

## Overview

This design adds a persistent responsive sidebar navigation to the plant IoT dashboard using go_router's `ShellRoute`. The sidebar wraps all authenticated routes, stays fixed on desktop (≥768px), becomes a drawer on mobile (<768px), and highlights the active route based on the current URL.

The existing DashboardPage Scaffold gets refactored: the AppBar (with logout) moves up to the shell widget, and child pages become body-only content without their own Scaffold/AppBar.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         GoRouter                                 │
│                                                                   │
│  Top-level routes (no shell):                                    │
│    /         → SplashPage                                        │
│    /login    → LoginPage                                         │
│    /register → RegisterPage                                      │
│                                                                   │
│  ShellRoute → NavigationShell                                    │
│    /dashboard      → DashboardPage                               │
│    /dispositivos   → DevicesPage (placeholder)                   │
│    /sensores       → SensorsPage (placeholder)                   │
│    /lecturas       → ReadingsPage (placeholder)                  │
│    /alertas        → AlertsPage (placeholder)                    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  NavigationShell (desktop, ≥768px)                               │
│                                                                   │
│  ┌────────────┐ ┌────────────────────────────────────────────┐  │
│  │  AppSidebar │ │  Scaffold                                  │  │
│  │             │ │    AppBar (title + logout)                 │  │
│  │  🌱 Panel   │ │    body: child (page content)             │  │
│  │             │ │                                            │  │
│  │  ● Dashboard│ │                                            │  │
│  │  ○ Devices  │ │                                            │  │
│  │  ○ Sensors  │ │                                            │  │
│  │  ○ Lecturas │ │                                            │  │
│  │  ○ Alertas  │ │                                            │  │
│  │             │ │                                            │  │
│  └────────────┘ └────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  NavigationShell (mobile, <768px)                                │
│                                                                   │
│  Scaffold                                                        │
│    AppBar (hamburger + title + logout)                           │
│    drawer: AppSidebar                                            │
│    body: child (page content)                                    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Component Design

### 1. New Routes (AppRoutes)

```dart
// lib/presentation/router/app_routes.dart
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  // Shell children (authenticated)
  static const dashboard = '/dashboard';
  static const devices = '/dispositivos';
  static const sensors = '/sensores';
  static const readings = '/lecturas';
  static const alerts = '/alertas';
}
```

### 2. Navigation Item Model

```dart
// lib/presentation/widgets/navigation/nav_item.dart

/// Represents a single sidebar navigation entry.
/// Used by AppSidebar to render menu items and determine the active one.
class NavItem {
  final String label;
  final IconData icon;
  final String route;

  const NavItem({required this.label, required this.icon, required this.route});
}

/// The ordered list of navigation items displayed in the sidebar.
const kNavItems = [
  NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: AppRoutes.dashboard),
  NavItem(label: 'Dispositivos', icon: Icons.devices_outlined, route: AppRoutes.devices),
  NavItem(label: 'Sensores', icon: Icons.sensors_outlined, route: AppRoutes.sensors),
  NavItem(label: 'Lecturas', icon: Icons.show_chart_outlined, route: AppRoutes.readings),
  NavItem(label: 'Alertas', icon: Icons.notifications_outlined, route: AppRoutes.alerts),
];
```

### 3. AppSidebar Widget

```dart
// lib/presentation/widgets/navigation/app_sidebar.dart

/// A vertical navigation panel that renders NavItems and highlights the active one.
///
/// Used in two contexts:
/// - Desktop: rendered directly in a Row alongside the page content.
/// - Mobile: rendered inside a Drawer.
///
/// Receives [currentRoute] to determine which item is active.
/// Calls [onItemTap] when a nav item is selected.
class AppSidebar extends StatelessWidget {
  final String currentRoute;
  final void Function(String route) onItemTap;

  const AppSidebar({required this.currentRoute, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.surface,
      child: Column(
        children: [
          // Brand header
          _BrandHeader(),
          const Divider(height: 1),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: kNavItems.map((item) {
                final isActive = currentRoute.startsWith(item.route);
                return _NavTile(item: item, isActive: isActive, onTap: () => onItemTap(item.route));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Active detection logic:** `currentRoute.startsWith(item.route)` — this handles nested routes (e.g. `/dispositivos/abc-123` still highlights "Dispositivos").

**Styling:**
- Active item: `AppColors.primary` background with opacity, white text
- Inactive item: transparent background, `AppColors.textSecondary` text
- Hover: `AppColors.surfaceAlt` background

### 4. NavigationShell Widget

```dart
// lib/presentation/widgets/navigation/navigation_shell.dart

/// The shell widget used by ShellRoute. Provides the responsive layout:
/// - Desktop (≥768px): fixed sidebar + content area side by side
/// - Mobile (<768px): Scaffold with drawer + hamburger menu
///
/// Receives [child] from go_router (the active page widget).
class NavigationShell extends ConsumerWidget {
  final Widget child;

  const NavigationShell({required this.child});

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
          const VerticalDivider(width: 1),
          Expanded(
            child: Scaffold(
              appBar: _buildAppBar(context, ref, showHamburger: false),
              body: child,
            ),
          ),
        ],
      );
    }

    // Mobile layout
    return Scaffold(
      appBar: _buildAppBar(context, ref, showHamburger: true),
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

  AppBar _buildAppBar(BuildContext context, WidgetRef ref, {required bool showHamburger}) {
    return AppBar(
      leading: showHamburger
          ? IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())
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
```

### 5. Updated Router Configuration

```dart
// lib/presentation/router/app_router.dart (key changes)

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authControllerProvider.notifier);

  ref.listen(authControllerProvider, (prev, next) {
    authNotifier.notifyAuthChanged();
  });

  return GoRouter(
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.splash;

      if (authState.isLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isLoggedIn = authState.value != null;

      if (isLoggedIn) {
        if (isAuthRoute) return AppRoutes.dashboard;
        return null;
      }

      if (!isAuthRoute) return AppRoutes.login;
      return null;
    },
    routes: [
      // ── Outside shell (no sidebar) ──────────────────────────────
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterPage()),

      // ── Shell (with sidebar) ────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const DashboardContent()),
          GoRoute(path: AppRoutes.devices, builder: (_, __) => const DevicesPlaceholder()),
          GoRoute(path: AppRoutes.sensors, builder: (_, __) => const SensorsPlaceholder()),
          GoRoute(path: AppRoutes.readings, builder: (_, __) => const ReadingsPlaceholder()),
          GoRoute(path: AppRoutes.alerts, builder: (_, __) => const AlertsPlaceholder()),
        ],
      ),
    ],
  );
});
```

### 6. DashboardPage Refactor

The current `DashboardPage` has its own `Scaffold` with AppBar. Since the shell now provides the Scaffold and AppBar, the dashboard becomes a body-only widget:

- Rename/extract the body content into `DashboardContent` (or keep `DashboardPage` but remove its Scaffold)
- Remove the AppBar and logout button from `DashboardPage` (the shell handles those)
- The page just returns the `readingAsync.when(...)` content directly

### 7. Placeholder Pages

For routes that don't have real pages yet (devices, sensors, readings, alerts), create simple placeholder widgets:

```dart
// lib/presentation/pages/devices/devices_page.dart
class DevicesPlaceholder extends StatelessWidget {
  const DevicesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Dispositivos — próximamente'));
  }
}
```

Same pattern for sensors, readings, alerts.

---

## File Changes Summary

| File | Action | Requirement |
|------|--------|-------------|
| `lib/presentation/router/app_routes.dart` | Update — add new route constants | R8 |
| `lib/presentation/router/app_router.dart` | Rewrite — ShellRoute + updated redirect | R1, R4, R8 |
| `lib/presentation/widgets/navigation/nav_item.dart` | **New** — NavItem model + kNavItems list | R2 |
| `lib/presentation/widgets/navigation/app_sidebar.dart` | **New** — Sidebar widget | R2, R3, R5, R6 |
| `lib/presentation/widgets/navigation/navigation_shell.dart` | **New** — Shell layout (responsive) | R1, R3, R5, R6, R7 |
| `lib/presentation/pages/dashboard/dashboard_page.dart` | Refactor — remove Scaffold/AppBar, become body-only | R1 |
| `lib/presentation/pages/devices/devices_page.dart` | **New** — placeholder | R8 |
| `lib/presentation/pages/sensors/sensors_page.dart` | **New** — placeholder | R8 |
| `lib/presentation/pages/readings/readings_page.dart` | **New** — placeholder | R8 |
| `lib/presentation/pages/alerts/alerts_page.dart` | **New** — placeholder | R8 |

## Key Design Decisions

1. **ShellRoute for persistence** — The sidebar doesn't rebuild on navigation. go_router handles this natively.
2. **`MediaQuery.sizeOf(context).width`** for responsive detection — simple, no external package needed. Breakpoint at 768px.
3. **`currentRoute.startsWith(item.route)`** for active detection — handles nested routes naturally.
4. **AppBar lives in the shell**, not in individual pages — avoids duplicating the title and logout in every page.
5. **Sidebar as a plain widget** (not `NavigationDrawer`/`NavigationRail`) — more control over styling to match the dark theme and the reference image.
6. **Placeholder pages** for routes that don't have real implementation yet — doesn't block the sidebar feature while other specs are pending.
7. **No Riverpod state for sidebar open/close** — the drawer state is managed by Scaffold natively. The active item is derived from the router state (no separate provider needed).
