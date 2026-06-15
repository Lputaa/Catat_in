import 'package:catat_in/features/activity/domain/time_value.dart';
import 'package:catat_in/features/activity/presentation/providers/activity_provider.dart';
import 'package:catat_in/features/activity/presentation/widgets/catat_in_app_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activityListProvider);
    final theme = Theme.of(context);

    // ── Compute stats ──
    int totalMinutes = 0;
    int totalScoreWeighted = 0;
    final timeValueMinutes = <TimeValue, int>{};
    final categoryMinutes = <String, int>{};

    for (final a in activities) {
      if (a.startAt == null || a.endAt == null) continue;
      final dur = a.endAt!.difference(a.startAt!).inMinutes;
      if (dur <= 0) continue;

      totalMinutes += dur;
      final tv = TimeValue.fromString(a.timeValue);
      totalScoreWeighted += tv.score * dur;
      timeValueMinutes[tv] = (timeValueMinutes[tv] ?? 0) + dur;
      categoryMinutes[a.category] = (categoryMinutes[a.category] ?? 0) + dur;
    }

    final avgScore = totalMinutes == 0
        ? 0.0
        : totalScoreWeighted / totalMinutes;
    final positiveMinutes =
        (timeValueMinutes[TimeValue.investasi] ?? 0) +
        (timeValueMinutes[TimeValue.produktif] ?? 0);

    // Top categories (sorted by minutes, top 5)
    final topCategories = categoryMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayCategories = topCategories.take(5).toList();

    // ── Daily category data (last 7 days) ──
    final now = DateTime.now();
    // Collect all categories that appear in the last 7 days
    final allDayCategories = <String>{};
    final dailyCategoryData = List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day - (6 - i));
      final catMins = <String, int>{};
      for (final a in activities) {
        if (a.startAt == null || a.endAt == null) continue;
        final sameDay =
            a.createdAt.year == day.year &&
            a.createdAt.month == day.month &&
            a.createdAt.day == day.day;
        if (!sameDay) continue;
        final dur = a.endAt!.difference(a.startAt!).inMinutes;
        if (dur <= 0) continue;
        catMins[a.category] = (catMins[a.category] ?? 0) + dur;
        allDayCategories.add(a.category);
      }
      return {'day': day, 'categories': catMins};
    });
    final sortedDayCategories = allDayCategories.toList()
      ..sort((a, b) {
        final aTotal = categoryMinutes[a] ?? 0;
        final bTotal = categoryMinutes[b] ?? 0;
        return bTotal.compareTo(aTotal);
      });

    // Grade
    String grade;
    Color gradeColor;
    if (totalMinutes == 0) {
      grade = '-';
      gradeColor = Colors.grey;
    } else if (avgScore >= 4.5) {
      grade = 'A';
      gradeColor = Colors.amber;
    } else if (avgScore >= 3.5) {
      grade = 'B';
      gradeColor = Colors.green;
    } else if (avgScore >= 2.5) {
      grade = 'C';
      gradeColor = Colors.blue;
    } else if (avgScore >= 1.5) {
      grade = 'D';
      gradeColor = Colors.orange;
    } else {
      grade = 'E';
      gradeColor = Colors.red;
    }

    String summaryMsg() {
      if (activities.isEmpty) {
        return 'Mulai catat aktivitasmu untuk melihat rapor!';
      }
      if (avgScore >= 4.0) {
        return 'Luar biasa! Waktumu sangat bermakna.';
      }
      if (avgScore >= 3.0) {
        return 'Cukup baik! Terus tingkatkan kualitas waktumu.';
      }
      if (avgScore >= 2.0) {
        return 'Masih bisa lebih baik. Coba kurangi waktu terbuang.';
      }
      return 'Ayo mulai investasikan waktumu dengan lebih baik!';
    }

    return Scaffold(
      appBar: const CatatInAppBar(title: 'RAPOR'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Hero grade card ──
          _HeroGradeCard(
            grade: grade,
            gradeColor: gradeColor,
            avgScore: avgScore,
            summary: summaryMsg(),
          ),
          const SizedBox(height: 12),

          // ── Stat grid ──
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: '📋',
                  label: 'Total Aktivitas',
                  value: '${activities.length}',
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: '⏱',
                  label: 'Total Waktu',
                  value: _fmtHours(totalMinutes),
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: '🚀',
                  label: 'Positif',
                  value: _fmtHours(positiveMinutes),
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24), // Added spacing

          // ── Charts Carousel ──
          if (activities.isNotEmpty) ...[
            _ChartCarousel(
              dailyCategoryData: dailyCategoryData,
              categories: sortedDayCategories,
              timeValueMinutes: timeValueMinutes,
              totalMinutes: totalMinutes,
            ),
          ],

          const SizedBox(height: 24),

          // ── Category Breakdown ──
          if (displayCategories.isNotEmpty) ...[
            _sectionHeader(theme, Icons.category_rounded, 'Kategori'),
            const SizedBox(height: 12),
            ...displayCategories.map((e) {
              final emoji = _categoryEmoji(e.key);
              final pct = totalMinutes == 0 ? 0.0 : e.value / totalMinutes;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CategoryRow(
                  emoji: emoji,
                  name: e.key,
                  minutes: e.value,
                  percentage: pct,
                  color: theme.colorScheme.primary,
                ),
              );
            }),
          ],

          const SizedBox(height: 24),
        ].animate(interval: 50.ms).fade(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────

  static Widget _sectionHeader(ThemeData theme, IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  static String _fmtHours(int minutes) {
    if (minutes < 60) return '$minutes mnt';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h jam';
    return '$h jam $m mnt';
  }

  static String _categoryEmoji(String cat) {
    const map = {
      'Kerja': '🏢',
      'Belajar': '📚',
      'Olahraga': '🏃',
      'Hiburan': '🎮',
      'Keseharian': '🍽',
      'Sosial': '👥',
      'Ibadah': '🕌',
      'Lainnya': '📌',
    };
    return map[cat] ?? '📌';
  }
}

// ─── Chart Carousel ─────────────────────────────────────────────────────────
class _ChartCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> dailyCategoryData;
  final List<String> categories;
  final Map<TimeValue, int> timeValueMinutes;
  final int totalMinutes;

  const _ChartCarousel({
    required this.dailyCategoryData,
    required this.categories,
    required this.timeValueMinutes,
    required this.totalMinutes,
  });

  @override
  State<_ChartCarousel> createState() => _ChartCarouselState();
}

class _ChartCarouselState extends State<_ChartCarousel> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = <Widget>[];

    if (widget.dailyCategoryData.isNotEmpty) {
      pages.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportPage._sectionHeader(theme, Icons.bar_chart_rounded, 'Kategori per Hari'),
            const SizedBox(height: 12),
            _DailyCategoryChart(
              dailyCategoryData: widget.dailyCategoryData,
              categories: widget.categories,
            ),
          ],
        ),
      );
    }

    if (widget.totalMinutes > 0) {
      pages.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportPage._sectionHeader(theme, Icons.stars_rounded, 'Distribusi Nilai Waktu'),
            const SizedBox(height: 12),
            _TimeValueDonut(
              timeValueMinutes: widget.timeValueMinutes,
              totalMinutes: widget.totalMinutes,
            ),
          ],
        ),
      );
    }

    if (pages.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 380, // Allow enough space for legends
          child: PageView(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            children: pages,
          ),
        ),
        if (pages.length > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pages.length, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

// ─── Hero Grade Card ────────────────────────────────────────────────────────
class _HeroGradeCard extends StatelessWidget {
  final String grade;
  final Color gradeColor;
  final double avgScore;
  final String summary;

  const _HeroGradeCard({
    required this.grade,
    required this.gradeColor,
    required this.avgScore,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradeColor.withValues(alpha: 0.15),
            gradeColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gradeColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grade circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: gradeColor, width: 2.5),
                ),
                child: Center(
                  child: Text(
                    grade,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: gradeColor,
                    ),
                  ).animate(delay: 600.ms).scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Score + label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: avgScore),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutExpo,
                    builder: (context, value, child) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: theme.colorScheme.onSurface,
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      Text(
                        'Skor Rata-rata',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => const _ScoreInfoSheet(),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            summary,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreInfoSheet extends StatelessWidget {
  const _ScoreInfoSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Penjelasan Skor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Skor dihitung dari nilai waktu (bobot) setiap aktivitas yang kamu catat dikalikan dengan durasinya. Berikut adalah nilai bobot masing-masing aktivitas:\n\n'
              '⭐ Investasi: 5 Poin\n'
              '✅ Produktif: 4 Poin\n'
              '🔧 Kebutuhan: 3 Poin\n'
              '🎯 Santai: 2 Poin\n'
              '⚠️ Terbuang: 1 Poin\n\n'
              'Rata-rata tertimbang akan menentukan Grade akhirmu. Semakin tinggi rata-rata skormu (mendekati 5.0), semakin produktif dan berharga waktu yang kamu habiskan!',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Mengerti'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {}, // Adds ripple effect
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ),
   ),
  );
 }
}

// ─── Daily Category Stacked Bar Chart ────────────────────────────────────────
class _DailyCategoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> dailyCategoryData;
  final List<String> categories;

  const _DailyCategoryChart({
    required this.dailyCategoryData,
    required this.categories,
  });

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  static const _categoryColors = <String, Color>{
    'Kerja': Color(0xFF5C6BC0),
    'Belajar': Color(0xFF42A5F5),
    'Olahraga': Color(0xFF66BB6A),
    'Hiburan': Color(0xFFAB47BC),
    'Keseharian': Color(0xFFFFA726),
    'Sosial': Color(0xFF26C6DA),
    'Ibadah': Color(0xFFEF5350),
    'Lainnya': Color(0xFF78909C),
  };

  static Color _colorFor(String cat) =>
      _categoryColors[cat] ?? const Color(0xFF78909C);

  static const _categoryEmojis = <String, String>{
    'Kerja': '🏢',
    'Belajar': '📚',
    'Olahraga': '🏃',
    'Hiburan': '🎮',
    'Keseharian': '🍽',
    'Sosial': '👥',
    'Ibadah': '🕌',
    'Lainnya': '📌',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Compute max total hours in a single day for Y-axis scaling
    double maxHrs = 1;
    for (final d in dailyCategoryData) {
      final catMap = d['categories'] as Map<String, int>;
      final totalMins = catMap.values.fold<int>(0, (s, v) => s + v);
      final hrs = totalMins / 60;
      if (hrs > maxHrs) maxHrs = hrs;
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxHrs * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      theme.colorScheme.surfaceContainerHighest,
                  getTooltipItem: (group, gIdx, rod, rIdx) {
                    final dayData = dailyCategoryData[group.x];
                    final catMap = dayData['categories'] as Map<String, int>;
                    if (catMap.isEmpty) return null;
                    final day = dayData['day'] as DateTime;
                    final dayLabel = _dayLabels[day.weekday - 1];
                    final buf = StringBuffer(
                      '$dayLabel ${day.day}/${day.month}\n',
                    );
                    for (final cat in categories) {
                      final mins = catMap[cat] ?? 0;
                      if (mins <= 0) continue;
                      final emoji = _categoryEmojis[cat] ?? '📌';
                      final h = mins ~/ 60;
                      final m = mins % 60;
                      final time = h > 0 ? '${h}j ${m}m' : '${m}m';
                      buf.write('$emoji $cat: $time\n');
                    }
                    return BarTooltipItem(
                      buf.toString().trimRight(),
                      TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: (maxHrs / 3).ceilToDouble().clamp(1, 99),
                    getTitlesWidget: (v, meta) {
                      return Text(
                        '${v.toInt()}j',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= dailyCategoryData.length) {
                        return const SizedBox.shrink();
                      }
                      final day = dailyCategoryData[idx]['day'] as DateTime;
                      final isToday =
                          DateTime.now().year == day.year &&
                          DateTime.now().month == day.month &&
                          DateTime.now().day == day.day;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _dayLabels[day.weekday - 1],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxHrs / 3).ceilToDouble().clamp(1, 99),
                getDrawingHorizontalLine: (v) => FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  strokeWidth: 1,
                ),
              ),
              barGroups: List.generate(dailyCategoryData.length, (i) {
                final catMap =
                    dailyCategoryData[i]['categories'] as Map<String, int>;
                // Build stacked rod data from categories
                final rodStack = <BarChartRodStackItem>[];
                double cumulative = 0;
                for (final cat in categories) {
                  final mins = catMap[cat] ?? 0;
                  if (mins <= 0) continue;
                  final hrs = mins / 60;
                  rodStack.add(
                    BarChartRodStackItem(
                      cumulative,
                      cumulative + hrs,
                      _colorFor(cat),
                    ),
                  );
                  cumulative += hrs;
                }
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: cumulative == 0 ? 0 : cumulative,
                      width: 22,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      rodStackItems: rodStack,
                      color: Colors.transparent,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: categories.map((cat) {
            final emoji = _categoryEmojis[cat] ?? '📌';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _colorFor(cat),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Text('$emoji $cat', style: const TextStyle(fontSize: 11)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── TimeValue Donut Chart ───────────────────────────────────────────────────
class _TimeValueDonut extends StatelessWidget {
  final Map<TimeValue, int> timeValueMinutes;
  final int totalMinutes;

  const _TimeValueDonut({
    required this.timeValueMinutes,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = TimeValue.values
        .where((tv) {
          return (timeValueMinutes[tv] ?? 0) > 0;
        })
        .map((tv) {
          final mins = timeValueMinutes[tv] ?? 0;
          final pct = (mins / totalMinutes * 100).toStringAsFixed(0);
          return PieChartSectionData(
            value: mins.toDouble(),
            color: tv.color,
            radius: 40,
            showTitle: (mins / totalMinutes * 100) >= 5,
            title: '${tv.emoji}\n$pct%',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
            titlePositionPercentageOffset: 0.55,
          );
        })
        .toList();

    return Row(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 28,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: TimeValue.values.map((tv) {
              final mins = timeValueMinutes[tv] ?? 0;
              if (mins == 0) return const SizedBox.shrink();
              final h = mins ~/ 60;
              final m = mins % 60;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: tv.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${tv.emoji} ${tv.shortLabel}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      h > 0 ? '${h}j ${m}m' : '${m}m',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Category Row ───────────────────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final String emoji;
  final String name;
  final int minutes;
  final double percentage;
  final Color color;

  const _CategoryRow({
    required this.emoji,
    required this.name,
    required this.minutes,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final label = hours > 0 ? '$hours jam $mins mnt' : '$mins mnt';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$emoji $name',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.001, 1.0),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: color.withValues(alpha: 0.6),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
