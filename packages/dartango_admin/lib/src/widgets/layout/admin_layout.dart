import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'sidebar_navigation.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AdminLayout({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  bool _sidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isDesktop ? _buildDrawer() : null,
      appBar: _buildAppBar(isDesktop),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: Container(
              color: AppColors.backgroundLight,
              child: widget.child,
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    return AppBar(
      title: widget.title != null ? Text(widget.title!) : null,
      leading: isDesktop
          ? IconButton(
              icon: Icon(_sidebarCollapsed ? Icons.menu : Icons.menu_open),
              onPressed: () {
                setState(() {
                  _sidebarCollapsed = !_sidebarCollapsed;
                });
              },
            )
          : null,
      actions: [
        ...?widget.actions,
        _buildUserMenu(),
      ],
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 1,
      shadowColor: AppColors.shadow.withValues(alpha: 0.1),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _sidebarCollapsed ? 72 : 280,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: SidebarNavigation(
          collapsed: _sidebarCollapsed,
          onItemSelected: (route) {
            Navigator.pushReplacementNamed(context, route);
          },
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SidebarNavigation(
        collapsed: false,
        onItemSelected: (route) {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }

  Widget _buildUserMenu() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return PopupMenuButton<String>(
          onSelected: (value) => _handleUserMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 12),
                  Text('Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help_outline),
                  SizedBox(width: 12),
                  Text('Help'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppColors.error),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    authProvider.user.username.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      authProvider.user.username,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      authProvider.user.email,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleUserMenuAction(String action) {
    switch (action) {
      case 'profile':
        Navigator.pushNamed(context, '/profile');
        break;
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'help':
        Navigator.pushNamed(context, '/help');
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
