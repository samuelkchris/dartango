class DashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int totalGroups;
  final int totalSessions;
  final int totalModels;
  final int totalLogs;
  final double systemHealth;
  final double memoryUsage;
  final double cpuUsage;
  final double diskUsage;
  final double networkTraffic;
  final DateTime lastUpdated;

  const DashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalGroups,
    required this.totalSessions,
    required this.totalModels,
    required this.totalLogs,
    required this.systemHealth,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.diskUsage,
    required this.networkTraffic,
    required this.lastUpdated,
  });

  DashboardStats copyWith({
    int? totalUsers,
    int? activeUsers,
    int? totalGroups,
    int? totalSessions,
    int? totalModels,
    int? totalLogs,
    double? systemHealth,
    double? memoryUsage,
    double? cpuUsage,
    double? diskUsage,
    double? networkTraffic,
    DateTime? lastUpdated,
  }) {
    return DashboardStats(
      totalUsers: totalUsers ?? this.totalUsers,
      activeUsers: activeUsers ?? this.activeUsers,
      totalGroups: totalGroups ?? this.totalGroups,
      totalSessions: totalSessions ?? this.totalSessions,
      totalModels: totalModels ?? this.totalModels,
      totalLogs: totalLogs ?? this.totalLogs,
      systemHealth: systemHealth ?? this.systemHealth,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      diskUsage: diskUsage ?? this.diskUsage,
      networkTraffic: networkTraffic ?? this.networkTraffic,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'active_users': activeUsers,
      'total_groups': totalGroups,
      'total_sessions': totalSessions,
      'total_models': totalModels,
      'total_logs': totalLogs,
      'system_health': systemHealth,
      'memory_usage': memoryUsage,
      'cpu_usage': cpuUsage,
      'disk_usage': diskUsage,
      'network_traffic': networkTraffic,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['total_users'] as int,
      activeUsers: json['active_users'] as int,
      totalGroups: json['total_groups'] as int,
      totalSessions: json['total_sessions'] as int,
      totalModels: json['total_models'] as int,
      totalLogs: json['total_logs'] as int,
      systemHealth: (json['system_health'] as num).toDouble(),
      memoryUsage: (json['memory_usage'] as num).toDouble(),
      cpuUsage: (json['cpu_usage'] as num).toDouble(),
      diskUsage: (json['disk_usage'] as num).toDouble(),
      networkTraffic: (json['network_traffic'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }
}

class ChartData {
  final String label;
  final double value;
  final DateTime? timestamp;

  const ChartData({
    required this.label,
    required this.value,
    this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      label: json['label'] as String,
      value: (json['value'] as num).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }
}

class SystemMetric {
  final String name;
  final double value;
  final double maxValue;
  final String unit;
  final MetricStatus status;

  const SystemMetric({
    required this.name,
    required this.value,
    required this.maxValue,
    required this.unit,
    required this.status,
  });

  double get percentage => (value / maxValue) * 100;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'max_value': maxValue,
      'unit': unit,
      'status': status.name,
    };
  }

  factory SystemMetric.fromJson(Map<String, dynamic> json) {
    return SystemMetric(
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
      maxValue: (json['max_value'] as num).toDouble(),
      unit: json['unit'] as String,
      status: MetricStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MetricStatus.normal,
      ),
    );
  }
}

class RecentActivity {
  final String id;
  final String userId;
  final String username;
  final String action;
  final String description;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;

  const RecentActivity({
    required this.id,
    required this.userId,
    required this.username,
    required this.action,
    required this.description,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'action': action,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
    };
  }

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      action: json['action'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
    );
  }
}

enum MetricStatus {
  normal,
  warning,
  critical,
}

class StatCard {
  final String title;
  final String value;
  final String? subtitle;
  final String? icon;
  final double? percentage;
  final bool isIncrease;

  const StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.percentage,
    required this.isIncrease,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'value': value,
      'subtitle': subtitle,
      'icon': icon,
      'percentage': percentage,
      'is_increase': isIncrease,
    };
  }

  factory StatCard.fromJson(Map<String, dynamic> json) {
    return StatCard(
      title: json['title'] as String,
      value: json['value'] as String,
      subtitle: json['subtitle'] as String?,
      icon: json['icon'] as String?,
      percentage: (json['percentage'] as num?)?.toDouble(),
      isIncrease: json['is_increase'] as bool? ?? true,
    );
  }
}
