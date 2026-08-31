import 'package:flutter/material.dart';

import '../../router/app_routes.dart';

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
  NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: AppRoutes.dashboard,
  ),
  NavItem(
    label: 'Dispositivos',
    icon: Icons.devices_outlined,
    route: AppRoutes.devices,
  ),
  NavItem(
    label: 'Sensores',
    icon: Icons.sensors_outlined,
    route: AppRoutes.sensors,
  ),
  NavItem(
    label: 'Lecturas',
    icon: Icons.show_chart_outlined,
    route: AppRoutes.readings,
  ),
  NavItem(
    label: 'Alertas',
    icon: Icons.notifications_outlined,
    route: AppRoutes.alerts,
  ),
  NavItem(
    label: 'Riego',
    icon: Icons.water_drop_outlined,
    route: AppRoutes.riego,
  ),
  NavItem(
    label: 'Cámaras',
    icon: Icons.photo_camera_outlined,
    route: AppRoutes.cameras,
  ),
];
