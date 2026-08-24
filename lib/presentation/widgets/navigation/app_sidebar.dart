import 'package:flutter/material.dart';

import '../../../core/config/app_theme.dart';
import 'nav_item.dart';

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

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SizedBox(
        width: 240,
        child: Column(
        children: [
          const _BrandHeader(),
          const Divider(height: 1, color: AppColors.surfaceAlt),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: kNavItems.map((item) {
                final isActive = currentRoute.startsWith(item.route);
                return _NavTile(
                  item: item,
                  isActive: isActive,
                  onTap: () => onItemTap(item.route),
                );
              }).toList(),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// Brand header shown at the top of the sidebar with icon and app name.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Icon(Icons.eco, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Plant Dashboard',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single navigation tile in the sidebar.
class _NavTile extends StatefulWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color foregroundColor;

    if (widget.isActive) {
      backgroundColor = AppColors.primary.withValues(alpha: 0.15);
      foregroundColor = AppColors.textPrimary;
    } else if (_isHovered) {
      backgroundColor = AppColors.surfaceAlt;
      foregroundColor = AppColors.textPrimary;
    } else {
      backgroundColor = Colors.transparent;
      foregroundColor = AppColors.textSecondary;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.item.icon, color: foregroundColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 14,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
