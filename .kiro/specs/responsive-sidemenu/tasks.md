# Implementation Plan: Responsive Side Menu

## Overview

Add a persistent responsive sidebar navigation to the plant IoT dashboard using go_router's ShellRoute. The sidebar wraps all authenticated routes, stays fixed on desktop (≥768px), becomes a drawer on mobile (<768px), and highlights the active route. The existing DashboardPage is refactored to become body-only content while the shell provides the Scaffold/AppBar.

## Tasks

- [x] 1. Update AppRoutes and create NavItem model
  - [x] 1.1 Add new route constants to AppRoutes
    - Add `devices`, `sensors`, `readings`, and `alerts` constants to `lib/presentation/router/app_routes.dart`
    - Values: `/dispositivos`, `/sensores`, `/lecturas`, `/alertas`
    - Keep existing constants (`splash`, `login`, `register`, `dashboard`) unchanged
    - _Requirements: 8.1_

  - [x] 1.2 Create NavItem model and kNavItems list
    - Create `lib/presentation/widgets/navigation/nav_item.dart`
    - Define `NavItem` class with `label`, `icon`, and `route` fields
    - Define `kNavItems` const list with 5 items in order: Dashboard, Dispositivos, Sensores, Lecturas, Alertas
    - Each item uses an outlined Material icon and references an `AppRoutes` constant
    - _Requirements: 2.1, 2.2_

- [x] 2. Create AppSidebar widget
  - [x] 2.1 Implement AppSidebar with nav items and active highlighting
    - Create `lib/presentation/widgets/navigation/app_sidebar.dart`
    - Accepts `currentRoute` (String) and `onItemTap` (callback) parameters
    - Fixed width of 240px, background `AppColors.surface`
    - Renders a brand header at the top (icon + app name)
    - Renders `kNavItems` as a scrollable list of tiles
    - Active detection: `currentRoute.startsWith(item.route)`
    - Active tile styling: `AppColors.primary` background with opacity, white/textPrimary text
    - Inactive tile styling: transparent background, `AppColors.textSecondary` text
    - No logout action in the sidebar — only nav items and brand
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.3, 7.1_

- [x] 3. Create NavigationShell widget
  - [x] 3.1 Implement responsive NavigationShell with desktop and mobile layouts
    - Create `lib/presentation/widgets/navigation/navigation_shell.dart`
    - `ConsumerWidget` that receives `child` from ShellRoute
    - Gets current location from `GoRouterState.of(context).uri.path`
    - Desktop layout (width ≥ 768px): `Row` with `AppSidebar` + `VerticalDivider` + `Expanded(Scaffold(appBar, body: child))`
    - Mobile layout (width < 768px): `Scaffold` with `drawer: AppSidebar(...)`, hamburger icon in AppBar leading, body: child
    - On mobile, closing drawer before navigating: `Navigator.of(context).pop()` then `context.go(route)`
    - AppBar includes: eco icon + "Monitoreo de Plantas" title + logout IconButton
    - Logout calls `ref.read(logoutProvider)()`
    - _Requirements: 1.1, 1.2, 3.2, 4.1, 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 6.4, 7.2, 7.3_

- [x] 4. Checkpoint - Verify sidebar widgets compile
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Rewrite app_router.dart with ShellRoute
  - [x] 5.1 Update app_router.dart to use ShellRoute wrapping authenticated routes
    - Keep `splash`, `login`, `register` as top-level GoRoute entries outside the shell
    - Add a `ShellRoute` with `builder` that returns `NavigationShell(child: child)`
    - Shell children: `/dashboard`, `/dispositivos`, `/sensores`, `/lecturas`, `/alertas`
    - Preserve existing auth guard redirect logic (using `authSessionProvider`, `refreshListenable: sessionNotifier`)
    - Preserve `restoreSessionProvider` activation and listener in the router provider
    - Update redirect to allow all ShellRoute paths for authenticated users (not just `/dashboard`)
    - Import `NavigationShell` and all page widgets
    - _Requirements: 1.1, 1.3, 1.4, 4.1, 4.2, 4.3, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [x] 6. Refactor DashboardPage and create placeholder pages
  - [x] 6.1 Refactor DashboardPage to remove Scaffold and AppBar
    - Remove the `Scaffold` wrapper and its `appBar` from `DashboardPage.build()`
    - Remove the logout `IconButton` from dashboard (it now lives in NavigationShell)
    - The widget should directly return the `readingAsync.when(...)` content (loading/error/data)
    - Keep all existing body content (`_DashboardBody`, `_HistorySection`, `_ErrorBanner`, etc.) unchanged
    - _Requirements: 1.2_

  - [x] 6.2 Create placeholder pages for Dispositivos, Sensores, Lecturas, Alertas
    - Create `lib/presentation/pages/devices/devices_page.dart` with `DevicesPage` StatelessWidget
    - Create `lib/presentation/pages/sensors/sensors_page.dart` with `SensorsPage` StatelessWidget
    - Create `lib/presentation/pages/readings/readings_page.dart` with `ReadingsPage` StatelessWidget
    - Create `lib/presentation/pages/alerts/alerts_page.dart` with `AlertsPage` StatelessWidget
    - Each shows a centered text: "[Section name] — próximamente"
    - _Requirements: 8.1, 8.3, 8.4, 8.5, 8.6_

- [x] 7. Final checkpoint - Ensure all components are wired together
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP (none in this plan — no property tests since the design has no Correctness Properties section)
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- The design is entirely UI/routing — no domain or infrastructure layer changes needed
- The existing `logoutProvider` from `auth_providers.dart` is reused as-is
- Active item detection uses `startsWith` to handle future nested routes (e.g. `/dispositivos/device-1`)

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "6.2"] },
    { "id": 2, "tasks": ["2.1"] },
    { "id": 3, "tasks": ["3.1"] },
    { "id": 4, "tasks": ["5.1", "6.1"] }
  ]
}
```
