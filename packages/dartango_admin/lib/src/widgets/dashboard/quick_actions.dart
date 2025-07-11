import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onUserManagement;
  final VoidCallback onSystemHealth;
  final VoidCallback onAnalytics;
  final VoidCallback onSettings;

  const QuickActions({
    super.key,
    required this.onUserManagement,
    required this.onSystemHealth,
    required this.onAnalytics,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildActionButton(
              'Users',
              Icons.people_outline,
              AppColors.primary,
              onUserManagement,
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              'Health',
              Icons.monitor_heart_outlined,
              AppColors.success,
              onSystemHealth,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionButton(
              'Analytics',
              Icons.timeline_outlined,
              AppColors.info,
              onAnalytics,
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              'Settings',
              Icons.settings_outlined,
              AppColors.warning,
              onSettings,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
