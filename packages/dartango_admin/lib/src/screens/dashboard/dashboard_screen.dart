import 'package:flutter/material.dart';
import '../../models/dashboard_stats.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layout/admin_layout.dart';
import '../../widgets/dashboard/stats_card.dart';
import '../../widgets/dashboard/chart_widget.dart';
import '../../widgets/dashboard/recent_activity.dart' as activity_widget;
import '../../widgets/dashboard/system_metrics.dart';
import '../../widgets/dashboard/quick_actions.dart';
import '../../services/websocket_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardStats _stats;
  bool _isLoading = true;
  late WebSocketService _webSocketService;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }

  void _initializeWebSocket() {
    _webSocketService = WebSocketService();

    _webSocketService.subscribe(WebSocketEvent.systemMetrics, (data) {
      if (mounted) {
        setState(() {
          _stats = _stats.copyWith(
            systemHealth:
                data['system_health']?.toDouble() ?? _stats.systemHealth,
            memoryUsage: data['memory_usage']?.toDouble() ?? _stats.memoryUsage,
            cpuUsage: data['cpu_usage']?.toDouble() ?? _stats.cpuUsage,
            diskUsage: data['disk_usage']?.toDouble() ?? _stats.diskUsage,
            networkTraffic:
                data['network_traffic']?.toDouble() ?? _stats.networkTraffic,
          );
        });
      }
    });

    _webSocketService.subscribe(WebSocketEvent.userCreated, (data) {
      if (mounted) {
        setState(() {
          _stats = _stats.copyWith(
            totalUsers: _stats.totalUsers + 1,
            activeUsers: _stats.activeUsers + 1,
          );
        });
        _showRealTimeNotification('New user created: ${data['username']}');
      }
    });

    _webSocketService.subscribe(WebSocketEvent.activityLog, (data) {
      // Handle new activity updates
      if (mounted) {
        _showRealTimeNotification('New activity: ${data['action']}');
      }
    });

    _connectWebSocket();
  }

  void _connectWebSocket() async {
    try {
      await _webSocketService.connect();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WebSocket connection failed: $e')),
        );
      }
    }
  }

  void _showRealTimeNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _stats = DashboardStats(
        totalUsers: 1245,
        activeUsers: 892,
        totalGroups: 23,
        totalSessions: 156,
        totalModels: 45,
        totalLogs: 8934,
        systemHealth: 98.5,
        memoryUsage: 68.2,
        cpuUsage: 42.1,
        diskUsage: 73.8,
        networkTraffic: 1.2,
        lastUpdated: DateTime.now(),
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDashboardData,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
          tooltip: 'Settings',
        ),
        _buildWebSocketIndicator(),
      ],
      child: _isLoading ? _buildLoadingState() : _buildDashboard(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildChartsSection(),
            const SizedBox(height: 24),
            _buildActivitySection(),
            const SizedBox(height: 24),
            _buildSystemSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Dartango Admin',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your application with ease using our comprehensive admin dashboard.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Last updated: ${_formatDateTime(_stats.lastUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          QuickActions(
            onUserManagement: () => Navigator.pushNamed(context, '/users'),
            onSystemHealth: () => Navigator.pushNamed(context, '/health'),
            onAnalytics: () => Navigator.pushNamed(context, '/analytics'),
            onSettings: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          children: [
            StatsCard(
              title: 'Total Users',
              value: _stats.totalUsers.toString(),
              icon: Icons.people,
              color: AppColors.primary,
              subtitle: '${_stats.activeUsers} active',
              trend: '+12.5%',
              trendUp: true,
            ),
            StatsCard(
              title: 'Groups',
              value: _stats.totalGroups.toString(),
              icon: Icons.group,
              color: AppColors.success,
              subtitle: 'Active groups',
              trend: '+2.1%',
              trendUp: true,
            ),
            StatsCard(
              title: 'Sessions',
              value: _stats.totalSessions.toString(),
              icon: Icons.devices,
              color: AppColors.warning,
              subtitle: 'Active sessions',
              trend: '-5.2%',
              trendUp: false,
            ),
            StatsCard(
              title: 'Models',
              value: _stats.totalModels.toString(),
              icon: Icons.storage,
              color: AppColors.info,
              subtitle: 'Database models',
              trend: '+8.9%',
              trendUp: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ChartWidget(
            title: 'User Activity',
            type: ChartType.line,
            data: _generateChartData(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ChartWidget(
            title: 'System Status',
            type: ChartType.donut,
            data: _generateSystemData(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: activity_widget.RecentActivity(
            activities: _generateRecentActivities(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SystemMetrics(
            systemHealth: _stats.systemHealth,
            memoryUsage: _stats.memoryUsage,
            cpuUsage: _stats.cpuUsage,
            diskUsage: _stats.diskUsage,
            networkTraffic: _stats.networkTraffic,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemSection() {
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
          Text(
            'System Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSystemInfo('Framework Version', 'Dartango v1.0.0'),
              ),
              Expanded(
                child: _buildSystemInfo('Dart Version', '3.0.0'),
              ),
              Expanded(
                child: _buildSystemInfo('Platform', 'Flutter Web'),
              ),
              Expanded(
                child: _buildSystemInfo('Uptime', '2 days, 14:32:18'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<ChartData> _generateChartData() {
    return [
      const ChartData(label: 'Jan', value: 120),
      const ChartData(label: 'Feb', value: 150),
      const ChartData(label: 'Mar', value: 180),
      const ChartData(label: 'Apr', value: 160),
      const ChartData(label: 'May', value: 200),
      const ChartData(label: 'Jun', value: 220),
      const ChartData(label: 'Jul', value: 190),
    ];
  }

  List<ChartData> _generateSystemData() {
    return [
      ChartData(label: 'Memory', value: _stats.memoryUsage),
      ChartData(label: 'CPU', value: _stats.cpuUsage),
      ChartData(label: 'Disk', value: _stats.diskUsage),
      ChartData(label: 'Network', value: _stats.networkTraffic),
    ];
  }

  List<ActivityItem> _generateRecentActivities() {
    return [
      ActivityItem(
        user: 'admin',
        action: 'Created user "john_doe"',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: ActivityType.create,
      ),
      ActivityItem(
        user: 'manager',
        action: 'Updated group permissions',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        type: ActivityType.update,
      ),
      ActivityItem(
        user: 'editor',
        action: 'Deleted model "OldModel"',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        type: ActivityType.delete,
      ),
      ActivityItem(
        user: 'viewer',
        action: 'Logged in',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: ActivityType.login,
      ),
    ];
  }

  Widget _buildWebSocketIndicator() {
    return ListenableBuilder(
      listenable: _webSocketService,
      builder: (context, child) {
        final isConnected = _webSocketService.isConnected;
        final connectionState = _webSocketService.connectionState;

        Color indicatorColor;
        IconData indicatorIcon;
        String tooltip;

        switch (connectionState) {
          case WebSocketConnectionState.connected:
            indicatorColor = AppColors.success;
            indicatorIcon = Icons.wifi;
            tooltip = 'Real-time updates active';
            break;
          case WebSocketConnectionState.connecting:
            indicatorColor = AppColors.warning;
            indicatorIcon = Icons.wifi_off;
            tooltip = 'Connecting...';
            break;
          case WebSocketConnectionState.error:
            indicatorColor = AppColors.error;
            indicatorIcon = Icons.wifi_off;
            tooltip = 'Connection error';
            break;
          default:
            indicatorColor = AppColors.textSecondary;
            indicatorIcon = Icons.wifi_off;
            tooltip = 'Disconnected';
        }

        return IconButton(
          icon: Icon(indicatorIcon, color: indicatorColor),
          onPressed: () {
            if (!isConnected) {
              _connectWebSocket();
            }
          },
          tooltip: tooltip,
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class ActivityItem {
  final String user;
  final String action;
  final DateTime timestamp;
  final ActivityType type;

  ActivityItem({
    required this.user,
    required this.action,
    required this.timestamp,
    required this.type,
  });
}

enum ActivityType { create, update, delete, login, logout }
