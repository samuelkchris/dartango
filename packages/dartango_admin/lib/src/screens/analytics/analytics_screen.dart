import 'package:flutter/material.dart';
import '../../models/dashboard_stats.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layout/admin_layout.dart';
import '../../widgets/dashboard/chart_widget.dart';
import '../../widgets/dashboard/stats_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = '7d';
  bool _isLoading = true;
  late AnalyticsData _analyticsData;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _analyticsData = _generateAnalyticsData();
      _isLoading = false;
    });
  }

  AnalyticsData _generateAnalyticsData() {
    return AnalyticsData(
      userGrowth: [
        const ChartData(label: 'Jan', value: 120),
        const ChartData(label: 'Feb', value: 150),
        const ChartData(label: 'Mar', value: 180),
        const ChartData(label: 'Apr', value: 160),
        const ChartData(label: 'May', value: 200),
        const ChartData(label: 'Jun', value: 220),
        const ChartData(label: 'Jul', value: 245),
      ],
      sessionData: [
        const ChartData(label: 'Mon', value: 45),
        const ChartData(label: 'Tue', value: 52),
        const ChartData(label: 'Wed', value: 48),
        const ChartData(label: 'Thu', value: 61),
        const ChartData(label: 'Fri', value: 58),
        const ChartData(label: 'Sat', value: 35),
        const ChartData(label: 'Sun', value: 42),
      ],
      trafficSources: [
        const ChartData(label: 'Direct', value: 35),
        const ChartData(label: 'Search', value: 28),
        const ChartData(label: 'Social', value: 20),
        const ChartData(label: 'Email', value: 17),
      ],
      deviceTypes: [
        const ChartData(label: 'Desktop', value: 45),
        const ChartData(label: 'Mobile', value: 35),
        const ChartData(label: 'Tablet', value: 20),
      ],
      topPages: [
        PageAnalytics('/dashboard', 1245, 8.5),
        PageAnalytics('/users', 892, 12.3),
        PageAnalytics('/groups', 654, 6.7),
        PageAnalytics('/analytics', 432, 15.2),
        PageAnalytics('/settings', 321, 9.8),
      ],
      performanceMetrics: PerformanceMetrics(
        averageLoadTime: 1.2,
        bounceRate: 32.5,
        pageViews: 8945,
        uniqueVisitors: 2134,
        conversionRate: 3.8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Analytics',
      actions: [
        DropdownButton<String>(
          value: _selectedPeriod,
          items: const [
            DropdownMenuItem(value: '24h', child: Text('Last 24 Hours')),
            DropdownMenuItem(value: '7d', child: Text('Last 7 Days')),
            DropdownMenuItem(value: '30d', child: Text('Last 30 Days')),
            DropdownMenuItem(value: '90d', child: Text('Last 90 Days')),
            DropdownMenuItem(value: '1y', child: Text('Last Year')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
            _loadAnalytics();
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadAnalytics,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _exportAnalytics,
          tooltip: 'Export',
        ),
      ],
      child: _isLoading ? _buildLoadingState() : _buildAnalytics(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewStats(),
          const SizedBox(height: 24),
          _buildChartsSection(),
          const SizedBox(height: 24),
          _buildDetailedAnalytics(),
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
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
              title: 'Page Views',
              value: _formatNumber(_analyticsData.performanceMetrics.pageViews),
              icon: Icons.visibility,
              color: AppColors.primary,
              subtitle: 'Total views',
              trend: '+12.3%',
              trendUp: true,
            ),
            StatsCard(
              title: 'Unique Visitors',
              value: _formatNumber(
                  _analyticsData.performanceMetrics.uniqueVisitors),
              icon: Icons.people,
              color: AppColors.success,
              subtitle: 'Unique users',
              trend: '+8.7%',
              trendUp: true,
            ),
            StatsCard(
              title: 'Bounce Rate',
              value:
                  '${_analyticsData.performanceMetrics.bounceRate.toStringAsFixed(1)}%',
              icon: Icons.exit_to_app,
              color: AppColors.warning,
              subtitle: 'Exit rate',
              trend: '-2.1%',
              trendUp: false,
            ),
            StatsCard(
              title: 'Avg Load Time',
              value:
                  '${_analyticsData.performanceMetrics.averageLoadTime.toStringAsFixed(1)}s',
              icon: Icons.speed,
              color: AppColors.info,
              subtitle: 'Page speed',
              trend: '-15.2%',
              trendUp: false,
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
            title: 'User Growth',
            type: ChartType.area,
            data: _analyticsData.userGrowth,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ChartWidget(
            title: 'Traffic Sources',
            type: ChartType.donut,
            data: _analyticsData.trafficSources,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedAnalytics() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildTopPagesTable(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              ChartWidget(
                title: 'Device Types',
                type: ChartType.donut,
                data: _analyticsData.deviceTypes,
              ),
              const SizedBox(height: 16),
              ChartWidget(
                title: 'Weekly Sessions',
                type: ChartType.bar,
                data: _analyticsData.sessionData,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopPagesTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Pages',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Page',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Views',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Avg Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              ..._analyticsData.topPages.map((page) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        page.path,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _formatNumber(page.views),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${page.avgTime.toStringAsFixed(1)}s',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _exportAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Analytics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
              subtitle: const Text('Spreadsheet format'),
              onTap: () {
                Navigator.pop(context);
                _performExport('csv');
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON'),
              subtitle: const Text('JSON format'),
              onTap: () {
                Navigator.pop(context);
                _performExport('json');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              subtitle: const Text('PDF report'),
              onTap: () {
                Navigator.pop(context);
                _performExport('pdf');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _performExport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting analytics to $format...'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {},
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class AnalyticsData {
  final List<ChartData> userGrowth;
  final List<ChartData> sessionData;
  final List<ChartData> trafficSources;
  final List<ChartData> deviceTypes;
  final List<PageAnalytics> topPages;
  final PerformanceMetrics performanceMetrics;

  AnalyticsData({
    required this.userGrowth,
    required this.sessionData,
    required this.trafficSources,
    required this.deviceTypes,
    required this.topPages,
    required this.performanceMetrics,
  });
}

class PageAnalytics {
  final String path;
  final int views;
  final double avgTime;

  PageAnalytics(this.path, this.views, this.avgTime);
}

class PerformanceMetrics {
  final double averageLoadTime;
  final double bounceRate;
  final int pageViews;
  final int uniqueVisitors;
  final double conversionRate;

  PerformanceMetrics({
    required this.averageLoadTime,
    required this.bounceRate,
    required this.pageViews,
    required this.uniqueVisitors,
    required this.conversionRate,
  });
}
