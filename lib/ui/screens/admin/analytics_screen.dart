import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/providers/analytics_provider.dart';
import '../../../data/models/analytics/chatbot_analytics_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load analytics data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadAnalyticsData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Theme Colors
  static const Color primaryColor = Color(0xFF2D5A27);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primarySurface = Color(0xFFF1F8E9);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        actions: [
          Consumer<AnalyticsProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: provider.isLoading ? null : () {
                  provider.refreshAnalytics();
                },
                icon: provider.isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textSecondary,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Content'),
            Tab(text: 'Chatbot'),
          ],
        ),
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState();
          }

          if (provider.error.isNotEmpty) {
            return _buildErrorState(provider.error);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(provider),
              _buildContentTab(provider),
              _buildChatbotTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryLight),
          SizedBox(height: 16),
          Text(
            'Memuat data analytics...',
            style: TextStyle(
              color: textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat data analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<AnalyticsProvider>().loadAnalyticsData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(AnalyticsProvider provider) {
    final overview = provider.overview;
    if (overview == null) return _buildNoDataState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(overview),
          const SizedBox(height: 32),
          _buildUserActivityChart(provider.userActivity),
          const SizedBox(height: 32),
          _buildGrowthChart(provider.growthData),
        ],
      ),
    );
  }

  Widget _buildContentTab(AnalyticsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentPerformanceCards(provider),
          const SizedBox(height: 32),
          _buildTopPlantsSection(provider.topPlants),
          const SizedBox(height: 32),
          _buildTopArticlesSection(provider.topArticles),
        ],
      ),
    );
  }

  Widget _buildChatbotTab(AnalyticsProvider provider) {
    final chatbotAnalytics = provider.chatbotAnalytics;
    if (chatbotAnalytics == null) return _buildNoDataState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChatbotStatsCards(chatbotAnalytics),
          const SizedBox(height: 32),
          _buildTopQuestionsSection(chatbotAnalytics.topQuestions),
          const SizedBox(height: 32),
          _buildTopTopicsSection(chatbotAnalytics.topTopics),
          const SizedBox(height: 32),
          _buildContentGapsSection(chatbotAnalytics.contentGaps),
          const SizedBox(height: 32),
          _buildHourlyUsageChart(chatbotAnalytics.hourlyUsage),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada data analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        // Use Row instead of Wrap for better control
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.8, // Width:Height ratio
                child: _buildStatCard(
                  'Total Pengguna',
                  overview.totalUsers.toString(),
                  Icons.people,
                  primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.8, // Width:Height ratio
                child: _buildStatCard(
                  'Total Tanaman',
                  overview.totalPlants.toString(),
                  Icons.eco,
                  Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.8, // Width:Height ratio
                child: _buildStatCard(
                  'Total Artikel',
                  overview.totalArticles.toString(),
                  Icons.article,
                  Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.8, // Width:Height ratio
                child: _buildStatCard(
                  'Total Percakapan',
                  overview.totalConversations.toString(),
                  Icons.chat,
                  Colors.orange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Secondary stats with Row layout
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.5, // Slightly taller for smaller text
                child: _buildStatCard(
                  'Aktif Hari Ini',
                  overview.activeUsersToday.toString(),
                  Icons.today,
                  Colors.purple,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.5, // Slightly taller for smaller text
                child: _buildStatCard(
                  'Aktif Minggu Ini',
                  overview.activeUsersWeek.toString(),
                  Icons.date_range,
                  Colors.indigo,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.5, // Slightly taller for smaller text
                child: _buildStatCard(
                  'Aktif Bulan Ini',
                  overview.activeUsersMonth.toString(),
                  Icons.calendar_month,
                  Colors.teal,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox( // Use FittedBox to scale content down if needed
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: IntrinsicHeight( // Ensures minimum height
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 8,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip, // Use clip instead of ellipsis
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserActivityChart(List<dynamic> userActivity) {
    if (userActivity.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivitas Pengguna (30 Hari Terakhir)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: userActivity.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.activeUsers.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(List<dynamic> growthData) {
    if (growthData.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pertumbuhan (12 Bulan Terakhir)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: growthData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.users.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: growthData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.conversations.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap( // Change from Row to Wrap
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('Pengguna', Colors.blue),
              _buildLegendItem('Percakapan', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, // Reduced from 12
            height: 8, // Reduced from 12
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4), // Reduced from 8
          Text(
            label,
            style: const TextStyle(
              fontSize: 10, // Reduced from 12
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPerformanceCards(AnalyticsProvider provider) {
    final metrics = provider.getEngagementMetrics();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performa Konten',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        // Use Row instead of Wrap for better control
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.8, // Width:Height ratio
                child: _buildStatCard(
                  'Total Views',
                  metrics['totalViews']?.toInt().toString() ?? '0',
                  Icons.visibility,
                  Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.8, // Width:Height ratio
                child: _buildStatCard(
                  'Total Likes',
                  metrics['totalLikes']?.toInt().toString() ?? '0',
                  Icons.favorite,
                  Colors.red,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.8, // Width:Height ratio
                child: _buildStatCard(
                  'Engagement Rate',
                  '${metrics['engagementRate']?.toStringAsFixed(1) ?? '0'}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.8, // Width:Height ratio
                child: _buildStatCard(
                  'Avg Rating',
                  metrics['avgRating']?.toStringAsFixed(1) ?? '0',
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopPlantsSection(List<dynamic> topPlants) {
    if (topPlants.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 10 Tanaman Populer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topPlants.take(10).length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final plant = topPlants[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: primarySurface,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
                title: Text(
                  plant.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${plant.views} views • ${plant.likes} likes • Rating: ${plant.rating.toStringAsFixed(1)}',
                  style: const TextStyle(color: textSecondary),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${plant.engagementRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopArticlesSection(List<dynamic> topArticles) {
    if (topArticles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 10 Artikel Populer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topArticles.take(10).length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final article = topArticles[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                title: Text(
                  article.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${article.views} views • ${article.likes} likes • Rating: ${article.rating.toStringAsFixed(1)}',
                  style: const TextStyle(color: textSecondary),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${article.engagementRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatbotStatsCards(dynamic chatbotAnalytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Chatbot',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        // Use Row instead of Wrap for better control
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.8, // Width:Height ratio
                child: _buildStatCard(
                  'Total Percakapan',
                  chatbotAnalytics.totalConversations.toString(),
                  Icons.chat,
                  Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.8, // Width:Height ratio
                child: _buildStatCard(
                  'Total Pesan',
                  chatbotAnalytics.totalMessages.toString(),
                  Icons.message,
                  Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.8, // Width:Height ratio
                child: _buildStatCard(
                  'Rata-rata Panjang',
                  chatbotAnalytics.avgConversationLength.toStringAsFixed(1),
                  Icons.timeline,
                  Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.8, // Width:Height ratio
                child: _buildStatCard(
                  'Kepuasan User',
                  '${chatbotAnalytics.userSatisfactionScore.toStringAsFixed(1)}/5',
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopQuestionsSection(Map<String, int> topQuestions) {
    if (topQuestions.isEmpty) return const SizedBox.shrink();

    final sortedQuestions = topQuestions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pertanyaan Paling Sering',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedQuestions.take(10).length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final question = sortedQuestions[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade50,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                title: Text(
                  question.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${question.value}x',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopTopicsSection(Map<String, int> topTopics) {
    if (topTopics.isEmpty) return const SizedBox.shrink();

    final sortedTopics = topTopics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Topik Paling Populer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: sortedTopics.take(5).map((topic) {
                  final total = sortedTopics.fold(0, (sum, t) => sum + t.value);
                  final percentage = (topic.value / total) * 100;
                  final colors = [
                    primaryColor,
                    Colors.blue,
                    Colors.orange,
                    Colors.green,
                    Colors.purple,
                  ];
                  final colorIndex = sortedTopics.indexOf(topic) % colors.length;
                  
                  return PieChartSectionData(
                    value: topic.value.toDouble(),
                    title: '${percentage.toStringAsFixed(1)}%',
                    color: colors[colorIndex],
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: sortedTopics.take(5).map((topic) {
              final colors = [
                primaryColor,
                Colors.blue,
                Colors.orange,
                Colors.green,
                Colors.purple,
              ];
              final colorIndex = sortedTopics.indexOf(topic) % colors.length;
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[colorIndex],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${topic.key} (${topic.value})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentGapsSection(List<ContentGap> contentGaps) {
    if (contentGaps.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible( // Make text flexible
                child: const Text(
                  'Content Gaps & Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis, // Add overflow handling
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6), // Reduced radius
                ),
                child: Text(
                  'Prioritas Tinggi',
                  style: TextStyle(
                    fontSize: 9, // Reduced font size
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: contentGaps.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final gap = contentGaps[index];
              Color priorityColor;
              String priorityText;
              
              if (gap.priority >= 8) {
                priorityColor = Colors.red;
                priorityText = 'HIGH';
              } else if (gap.priority >= 5) {
                priorityColor = Colors.orange;
                priorityText = 'MEDIUM';
              } else {
                priorityColor = Colors.green;
                priorityText = 'LOW';
              }
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: priorityColor.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            gap.topic,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            priorityText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${gap.questionCount} pertanyaan terkait',
                      style: const TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rekomendasi:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: priorityColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gap.suggestedAction,
                            style: const TextStyle(
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (gap.relatedQuestions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Contoh pertanyaan:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...gap.relatedQuestions.take(3).map(
                        (question) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '• $question',
                            style: const TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyUsageChart(Map<String, int> hourlyUsage) {
    if (hourlyUsage.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Penggunaan Chatbot per Jam',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: hourlyUsage.values.reduce((a, b) => a > b ? a : b).toDouble() + 5,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 4,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final hour = value.toInt();
                        return Text(
                          '$hour:00',
                          style: const TextStyle(
                            fontSize: 10,
                            color: textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: hourlyUsage.entries.map((entry) {
                  final hour = int.parse(entry.key);
                  final count = entry.value;
                  
                  // Different colors for different times of day
                  Color barColor;
                  if (hour >= 6 && hour < 12) {
                    barColor = Colors.orange; // Morning
                  } else if (hour >= 12 && hour < 18) {
                    barColor = Colors.blue; // Afternoon
                  } else if (hour >= 18 && hour < 24) {
                    barColor = primaryColor; // Evening
                  } else {
                    barColor = Colors.grey; // Night
                  }
                  
                  return BarChartGroupData(
                    x: hour,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: barColor,
                        width: 8,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap( // Change from Row to Wrap to prevent overflow
            spacing: 8, // Reduced spacing
            runSpacing: 8,
            children: [
              _buildLegendItem('Pagi (6-12)', Colors.orange),
              _buildLegendItem('Siang (12-18)', Colors.blue),
              _buildLegendItem('Malam (18-24)', primaryColor),
              _buildLegendItem('Malam (0-6)', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}
