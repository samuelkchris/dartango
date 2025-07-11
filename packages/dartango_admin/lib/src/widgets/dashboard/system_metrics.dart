import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SystemMetrics extends StatelessWidget {
  final double systemHealth;
  final double memoryUsage;
  final double cpuUsage;
  final double diskUsage;
  final double networkTraffic;

  const SystemMetrics({
    super.key,
    required this.systemHealth,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.diskUsage,
    required this.networkTraffic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'System Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getHealthColor(systemHealth).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getHealthStatus(systemHealth),
                  style: TextStyle(
                    color: _getHealthColor(systemHealth),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildMetricItem('Memory Usage', memoryUsage, Icons.memory),
          const SizedBox(height: 16),
          _buildMetricItem('CPU Usage', cpuUsage, Icons.speed),
          const SizedBox(height: 16),
          _buildMetricItem('Disk Usage', diskUsage, Icons.storage),
          const SizedBox(height: 16),
          _buildMetricItem(
              'Network Traffic', networkTraffic, Icons.network_check,
              isGB: true),
          const SizedBox(height: 24),
          _buildOverallHealth(),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, double value, IconData icon,
      {bool isGB = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              isGB
                  ? '${value.toStringAsFixed(1)} GB/s'
                  : '${value.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: isGB ? value / 10 : value / 100,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(_getMetricColor(value)),
        ),
      ],
    );
  }

  Widget _buildOverallHealth() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getHealthColor(systemHealth).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite,
            color: _getHealthColor(systemHealth),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Health',
                  style: TextStyle(
                    fontSize: 14,
                    color: _getHealthColor(systemHealth),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${systemHealth.toStringAsFixed(1)}% - ${_getHealthStatus(systemHealth)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getHealthColor(systemHealth),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMetricColor(double value) {
    if (value < 50) return AppColors.success;
    if (value < 80) return AppColors.warning;
    return AppColors.error;
  }

  Color _getHealthColor(double health) {
    if (health > 95) return AppColors.success;
    if (health > 85) return AppColors.warning;
    return AppColors.error;
  }

  String _getHealthStatus(double health) {
    if (health > 95) return 'Excellent';
    if (health > 85) return 'Good';
    if (health > 70) return 'Fair';
    return 'Poor';
  }
}
