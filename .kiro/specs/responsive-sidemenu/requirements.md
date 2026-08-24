# Requirements Document

## Introduction

This feature adds a persistent responsive sidebar (side menu) to the plant IoT dashboard app. The sidebar provides fixed navigation for all authenticated routes, adapts its presentation based on screen width (fixed panel on desktop, drawer on mobile), highlights the active route, and includes a logout action. The implementation uses go_router's ShellRoute to wrap authenticated pages in a navigation shell, keeping login/register/splash outside the shell.

## Glossary

- **Sidebar**: A vertical navigation panel rendered on the left side of the viewport that contains navigation items and a logout action.
- **Navigation_Shell**: The ShellRoute widget that wraps all authenticated routes, providing the Sidebar and a content area for child pages.
- **Navigation_Item**: A clickable element within the Sidebar representing a route destination (e.g., Dashboard, Dispositivos).
- **Active_Item**: The Navigation_Item whose associated route matches the current URL location, visually distinguished from inactive items.
- **Desktop_Layout**: The responsive layout applied when the viewport width is greater than or equal to 768 logical pixels, where the Sidebar is permanently visible as a fixed panel.
- **Mobile_Layout**: The responsive layout applied when the viewport width is less than 768 logical pixels, where the Sidebar is hidden behind a hamburger menu and presented as a drawer overlay.
- **App_Router**: The go_router instance configured with ShellRoute and authentication redirect logic.
- **Auth_Guard**: The existing redirect logic in App_Router that prevents unauthenticated users from accessing protected routes.

## Requirements

### Requirement 1: Navigation Shell Structure

**User Story:** As a developer, I want authenticated routes wrapped in a ShellRoute, so that the sidebar persists across page navigation without rebuilding.

#### Acceptance Criteria

1. THE App_Router SHALL use a ShellRoute to wrap all authenticated route destinations (Dashboard, Dispositivos, Sensores, Lecturas, Alertas).
2. WHEN a user navigates between authenticated routes, THE Navigation_Shell SHALL preserve the Sidebar without rebuilding it.
3. THE App_Router SHALL keep login, register, and splash routes outside the ShellRoute as top-level GoRoute entries.
4. THE Auth_Guard SHALL continue to redirect unauthenticated users to the login page for all routes within the ShellRoute.

### Requirement 2: Sidebar Layout and Content

**User Story:** As a user, I want a sidebar with clearly labeled navigation items, so that I can navigate to any section of the dashboard.

#### Acceptance Criteria

1. THE Sidebar SHALL display the following Navigation_Items in order: Dashboard, Dispositivos, Sensores, Lecturas, Alertas.
2. THE Sidebar SHALL display each Navigation_Item with an icon and a text label.
3. THE Sidebar SHALL display a brand or app identifier (logo or app name) at the top of the panel.
4. THE Sidebar SHALL use the existing dark theme colors defined in AppColors (background: surface or surfaceAlt, text: textPrimary and textSecondary, accent: primary).

### Requirement 3: Active Item Highlighting

**User Story:** As a user, I want the sidebar to highlight the page I'm currently on, so that I always know where I am in the app.

#### Acceptance Criteria

1. THE Sidebar SHALL visually distinguish the Active_Item from inactive Navigation_Items using a different background color or accent indicator.
2. WHEN the current URL location changes, THE Sidebar SHALL update the Active_Item to match the new location.
3. THE Sidebar SHALL determine the Active_Item by comparing each Navigation_Item's associated route path against the current GoRouterState location.
4. WHEN a user navigates using browser back/forward buttons, THE Sidebar SHALL update the Active_Item to reflect the resulting URL.

### Requirement 4: Route-Menu Synchronization

**User Story:** As a user, I want the URL in the browser and the highlighted menu item to always match, so that bookmarks and shared links land on the correct page with the correct sidebar state.

#### Acceptance Criteria

1. WHEN a user clicks a Navigation_Item, THE App_Router SHALL update the browser URL to the corresponding route path.
2. WHEN a user enters a URL directly in the browser address bar for an authenticated route, THE Sidebar SHALL highlight the matching Navigation_Item.
3. THE Sidebar active state and the browser URL SHALL remain synchronized at all times during authenticated navigation.

### Requirement 5: Responsive Behavior — Desktop

**User Story:** As a desktop user, I want the sidebar always visible on wide screens, so that I can navigate without extra clicks.

#### Acceptance Criteria

1. WHILE the viewport width is greater than or equal to 768 logical pixels, THE Navigation_Shell SHALL display the Sidebar as a fixed panel on the left side of the viewport.
2. WHILE in Desktop_Layout, THE Navigation_Shell SHALL render the child page content in the remaining horizontal space to the right of the Sidebar.
3. WHILE in Desktop_Layout, THE Sidebar SHALL have a fixed width that does not change with viewport resizing.

### Requirement 6: Responsive Behavior — Mobile

**User Story:** As a mobile user, I want the sidebar hidden behind a menu button on narrow screens, so that the content area uses the full viewport width.

#### Acceptance Criteria

1. WHILE the viewport width is less than 768 logical pixels, THE Navigation_Shell SHALL hide the Sidebar and display a hamburger menu icon (button) in the app bar.
2. WHEN the user taps the hamburger menu icon, THE Navigation_Shell SHALL open the Sidebar as a drawer overlay from the left edge.
3. WHEN the user selects a Navigation_Item in the drawer, THE Navigation_Shell SHALL close the drawer and navigate to the selected route.
4. WHILE in Mobile_Layout, THE child page content SHALL occupy the full viewport width.

### Requirement 7: Logout Remains in App Bar

**User Story:** As a user, I want the logout action to stay in the top app bar where it currently lives, so that the sidebar is exclusively for navigation.

#### Acceptance Criteria

1. THE Sidebar SHALL NOT include a logout action; it SHALL contain only Navigation_Items and the brand/app identifier.
2. THE Navigation_Shell SHALL preserve the existing logout button in the top app bar (or toolbar area) for both Desktop_Layout and Mobile_Layout.
3. WHEN the user activates the logout action in the app bar, THE App_Router SHALL redirect the user to the login page via the existing Auth_Guard mechanism.

### Requirement 8: Navigation Item Routing

**User Story:** As a developer, I want each sidebar item mapped to a specific route, so that adding new pages only requires adding a route and a menu entry.

#### Acceptance Criteria

1. THE App_Router SHALL define the following routes as children of the ShellRoute: /dashboard, /dispositivos, /sensores, /lecturas, /alertas.
2. WHEN a user clicks the "Dashboard" Navigation_Item, THE App_Router SHALL navigate to /dashboard.
3. WHEN a user clicks the "Dispositivos" Navigation_Item, THE App_Router SHALL navigate to /dispositivos.
4. WHEN a user clicks the "Sensores" Navigation_Item, THE App_Router SHALL navigate to /sensores.
5. WHEN a user clicks the "Lecturas" Navigation_Item, THE App_Router SHALL navigate to /lecturas.
6. WHEN a user clicks the "Alertas" Navigation_Item, THE App_Router SHALL navigate to /alertas.
