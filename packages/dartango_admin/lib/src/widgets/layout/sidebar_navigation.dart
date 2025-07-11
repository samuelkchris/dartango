import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class SidebarNavigation extends StatefulWidget {
  final bool collapsed;
  final Function(String) onItemSelected;

  const SidebarNavigation({
    super.key,
    required this.collapsed,
    required this.onItemSelected,
  });

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation> {
  String _currentRoute = '/dashboard';

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Users',
      route: '/users',
    ),
    NavigationItem(
      icon: Icons.group_outlined,
      activeIcon: Icons.group,
      label: 'Groups',
      route: '/groups',
    ),
    NavigationItem(
      icon: Icons.admin_panel_settings_outlined,
      activeIcon: Icons.admin_panel_settings,
      label: 'Permissions',
      route: '/permissions',
    ),
    NavigationItem(
      icon: Icons.storage_outlined,
      activeIcon: Icons.storage,
      label: 'Models',
      route: '/models',
    ),
    NavigationItem(
      icon: Icons.timeline_outlined,
      activeIcon: Icons.timeline,
      label: 'Analytics',
      route: '/analytics',
    ),
    NavigationItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'Logs',
      route: '/logs',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ..._navigationItems.map((item) => _buildNavigationItem(item)),
              const SizedBox(height: 16),
              _buildSection('System'),
              _buildNavigationItem(NavigationItem(
                icon: Icons.backup_outlined,
                activeIcon: Icons.backup,
                label: 'Backup',
                route: '/backup',
              )),
              _buildNavigationItem(NavigationItem(
                icon: Icons.monitor_heart_outlined,
                activeIcon: Icons.monitor_heart,
                label: 'Health',
                route: '/health',
              )),
            ],
          ),
        ),
        const Divider(height: 1),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          if (!widget.collapsed) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Constants.appName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'v${Constants.appVersion}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item) {
    final isActive = _currentRoute == item.route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _currentRoute = item.route;
            });
            widget.onItemSelected(item.route);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    key: ValueKey(isActive),
                    size: 20,
                    color:
                        isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    if (widget.collapsed) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 1,
        color: AppColors.border,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.support_agent,
            size: 20,
            color: AppColors.textSecondary,
          ),
          if (!widget.collapsed) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Get help',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final int? badge;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.badge,
  });
}
