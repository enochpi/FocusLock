import 'package:flutter/material.dart';

import '../services/focus_stats_service.dart';
import '../services/streak_service.dart';

class FocusStatsScreen extends StatefulWidget {
  const FocusStatsScreen({super.key});

  @override
  State<FocusStatsScreen> createState() => _FocusStatsScreenState();
}

class _FocusStatsScreenState extends State<FocusStatsScreen> {
  late Future<FocusStatsSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  Future<FocusStatsSummary> _loadSummary() async {
    await StreakService().init();
    return FocusStatsService().getSummary();
  }

  Future<void> _refresh() async {
    final next = _loadSummary();
    setState(() => _summaryFuture = next);
    await next;
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}m';
  }

  String _dayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _dateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildHeroCard(FocusStatsSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.26),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🌱', style: TextStyle(fontSize: 30)),
              SizedBox(width: 10),
              Text(
                'Today',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _formatMinutes(summary.todayMinutes),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const Text(
            'focused today',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildHeroMetric(
                  icon: '🛡️',
                  value: '${summary.blockedToday}',
                  label: 'blocked today',
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white24,
              ),
              Expanded(
                child: _buildHeroMetric(
                  icon: '🔥',
                  value: '${StreakService().displayStreak}',
                  label: 'day streak',
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white24,
              ),
              Expanded(
                child: _buildHeroMetric(
                  icon: '✅',
                  value: '${summary.completedSessions}',
                  label: 'completed',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric({
    required String icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 19)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 25)),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(FocusStatsSummary summary) {
    final completionPercent =
        (summary.completionRate * 100).round();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.22,
      children: [
        _buildStatCard(
          icon: '📅',
          label: 'This week',
          value: _formatMinutes(summary.weekMinutes),
        ),
        _buildStatCard(
          icon: '⏱️',
          label: 'Total focus',
          value: _formatMinutes(summary.totalMinutes),
        ),
        _buildStatCard(
          icon: '🎯',
          label: 'Completion rate',
          value: '$completionPercent%',
          subtitle:
              '${summary.stoppedSessions} stopped session${summary.stoppedSessions == 1 ? '' : 's'}',
        ),
        _buildStatCard(
          icon: '📊',
          label: 'Average session',
          value: _formatMinutes(summary.averageSessionMinutes),
        ),
        _buildStatCard(
          icon: '🛡️',
          label: 'Distractions stopped',
          value: '${summary.totalBlocked}',
        ),
        _buildStatCard(
          icon: '🌾',
          label: 'Crops earned',
          value: '${summary.totalPeasEarned}',
        ),
      ],
    );
  }

  Widget _buildSevenDayChart(FocusStatsSummary summary) {
    int maxMinutes = 0;

    for (final day in summary.last7Days) {
      if (day.focusMinutes > maxMinutes) {
        maxMinutes = day.focusMinutes;
      }
    }

    if (maxMinutes < 1) maxMinutes = 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 7 Days',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Focused minutes each day',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: summary.last7Days.map((day) {
                final ratio = day.focusMinutes / maxMinutes;
                final barHeight = day.focusMinutes == 0
                    ? 8.0
                    : 18.0 + (ratio * 105.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${day.focusMinutes}',
                          style: TextStyle(
                            color: day.focusMinutes > 0
                                ? Colors.white70
                                : Colors.white24,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Tooltip(
                          message:
                              '${_dateLabel(day.date)}: ${day.focusMinutes} min, ${day.blockedAttempts} blocked',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: day.focusMinutes > 0
                                    ? const [
                                        Color(0xFF81C784),
                                        Color(0xFF2E7D32),
                                      ]
                                    : [
                                        Colors.white.withOpacity(0.08),
                                        Colors.white.withOpacity(0.04),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _dayLabel(day.date),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required String icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 23)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(FocusStatsSummary summary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 2, 4, 12),
            child: Text(
              'Your Patterns',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildInsightRow(
            icon: '🧠',
            title: 'Most-used focus mode',
            value: summary.mostUsedMode,
          ),
          const SizedBox(height: 8),
          _buildInsightRow(
            icon: '🏆',
            title: 'Best focus day',
            value: summary.bestDayLabel,
          ),
          const SizedBox(height: 8),
          _buildInsightRow(
            icon: '☀️',
            title: 'Best time to focus',
            value: summary.bestTimeOfDay,
          ),
          const SizedBox(height: 8),
          _buildInsightRow(
            icon: '📵',
            title: 'Most-blocked app',
            value: summary.mostBlockedApp,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(FocusStatsSummary summary) {
    if (summary.recentSessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Complete a focus session and it will appear here.',
          style: TextStyle(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Sessions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ...summary.recentSessions.map((session) {
            final color = session.completed
                ? const Color(0xFF66BB6A)
                : Colors.orangeAccent;

            return ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  session.completed
                      ? Icons.check_rounded
                      : Icons.stop_rounded,
                  color: color,
                ),
              ),
              title: Text(
                session.mode,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${_dateLabel(session.timestamp.toLocal())} · '
                '${session.completed ? 'Completed' : 'Stopped'}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
              trailing: Text(
                _formatMinutes(session.focusedMinutes),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const Column(
        children: [
          Text('📊', style: TextStyle(fontSize: 52)),
          SizedBox(height: 12),
          Text(
            'Your focus story starts here',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'New focus sessions and blocked distractions will be recorded from this update onward.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F3460),
      appBar: AppBar(
        title: const Text('Focus Stats'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh stats',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<FocusStatsSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF66BB6A),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load focus stats:\n${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final summary = snapshot.data;
          if (summary == null) {
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: const Color(0xFF2E7D32),
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _buildHeroCard(summary),
                const SizedBox(height: 12),
                if (!summary.hasActivity) ...[
                  _buildEmptyState(),
                  const SizedBox(height: 12),
                ],
                _buildOverviewGrid(summary),
                const SizedBox(height: 12),
                _buildSevenDayChart(summary),
                const SizedBox(height: 12),
                _buildInsights(summary),
                const SizedBox(height: 12),
                _buildRecentSessions(summary),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
