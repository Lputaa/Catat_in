import 'package:catat_in/features/activity/domain/category_meta.dart';
import 'package:catat_in/features/activity/domain/time_value.dart';
import 'package:catat_in/features/activity/presentation/pages/log_page.dart';
import 'package:catat_in/features/activity/presentation/providers/activity_provider.dart';
import 'package:catat_in/features/activity/presentation/widgets/catat_in_app_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── #1: Time Range Enum ────────────────────────────────────────────────────
enum ReportRange { week, month, custom }

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  ReportRange _range = ReportRange.week;
  DateTimeRange? _customRange;

  // ── #1: Filter activities by selected range ──
  List<T> _filterByRange<T>(List<T> items, DateTime Function(T) getDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_range) {
      case ReportRange.week:
        final start = today.subtract(const Duration(days: 6));
        return items.where((e) {
          final d = getDate(e);
          return !d.isBefore(start);
        }).toList();
      case ReportRange.month:
        final start = today.subtract(const Duration(days: 29));
        return items.where((e) {
          final d = getDate(e);
          return !d.isBefore(start);
        }).toList();
      case ReportRange.custom:
        if (_customRange == null) return items;
        return items.where((e) {
          final d = getDate(e);
          return !d.isBefore(_customRange!.start) &&
              d.isBefore(_customRange!.end.add(const Duration(days: 1)));
        }).toList();
    }
  }

  int get _rangeDays {
    switch (_range) {
      case ReportRange.week:
        return 7;
      case ReportRange.month:
        return 30;
      case ReportRange.custom:
        if (_customRange == null) return 7;
        return _customRange!.end.difference(_customRange!.start).inDays + 1;
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange:
          _customRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allActivities = ref.watch(activityListProvider);
    final theme = Theme.of(context);

    // #1: Filter by range
    final activities = _filterByRange(allActivities, (a) => a.createdAt);

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

    // Top categories (sorted by minutes)
    final topCategories = categoryMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayCategories = topCategories.take(5).toList();

    // ── Daily category data (based on range) ──
    final now = DateTime.now();
    final days = _rangeDays.clamp(1, 60);
    final allDayCategories = <String>{};
    final dailyCategoryData = List.generate(days, (i) {
      final day = DateTime(now.year, now.month, now.day - (days - 1 - i));
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

    // #8: Positive percentage
    final positivePercent = totalMinutes > 0
        ? (positiveMinutes / totalMinutes * 100).toStringAsFixed(0)
        : '0';

    return Scaffold(
      appBar: const CatatInAppBar(title: 'RAPOR'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── #1: Time Range Filter ──
          _TimeRangeSelector(
            range: _range,
            customRange: _customRange,
            onRangeChanged: (r) async {
              if (r == ReportRange.custom) {
                await _pickCustomRange();
              }
              setState(() => _range = r);
            },
          ),
          const SizedBox(height: 16),

          // ── Hero grade card (with #5 progress bar) ──
          _HeroGradeCard(
            grade: grade,
            gradeColor: gradeColor,
            avgScore: avgScore,
            summary: summaryMsg(),
          ),
          const SizedBox(height: 12),

          // ── Stat grid (#4 InkWell removed, #8 subtitle added) ──
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
                  value: CategoryMeta.formatDurationLong(totalMinutes),
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: '🚀',
                  label: 'Positif',
                  value: CategoryMeta.formatDurationLong(positiveMinutes),
                  subtitle: '$positivePercent% dari total',
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Charts (#2 empty state, #9 tab labels) ──
          if (activities.isNotEmpty) ...[
            _ChartCarousel(
              dailyCategoryData: dailyCategoryData,
              categories: sortedDayCategories,
              timeValueMinutes: timeValueMinutes,
              totalMinutes: totalMinutes,
            ),
          ],

          // ── #2: Informative empty state ──
          if (activities.isEmpty) ...[
            const SizedBox(height: 16),
            _EmptyChartPlaceholder(
              onStartLogging: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogPage()),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),

          // ── Category Breakdown (#7 "Lihat semua") ──
          if (displayCategories.isNotEmpty) ...[
            _sectionHeader(theme, Icons.category_rounded, 'Kategori'),
            const SizedBox(height: 12),
            ...displayCategories.map((e) {
              final emoji = CategoryMeta.emojiFor(e.key);
              final pct = totalMinutes == 0 ? 0.0 : e.value / totalMinutes;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CategoryRow(
                  emoji: emoji,
                  name: e.key,
                  minutes: e.value,
                  percentage: pct,
                  color: CategoryMeta.colorFor(e.key),
                ),
              );
            }),
            // #7: "Lihat semua" button
            if (topCategories.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Center(
                  child: TextButton(
                    onPressed: () => _showAllCategories(
                      context,
                      topCategories,
                      totalMinutes,
                    ),
                    child: Text(
                      'Lihat semua ${topCategories.length} kategori →',
                    ),
                  ),
                ),
              ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── #7: Show all categories in a bottom sheet ──
  void _showAllCategories(
    BuildContext context,
    List<MapEntry<String, int>> categories,
    int totalMinutes,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semua Kategori',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ...categories.map((e) {
                  final emoji = CategoryMeta.emojiFor(e.key);
                  final pct = totalMinutes == 0 ? 0.0 : e.value / totalMinutes;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CategoryRow(
                      emoji: emoji,
                      name: e.key,
                      minutes: e.value,
                      percentage: pct,
                      color: CategoryMeta.colorFor(e.key),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
}

// ─── #1: Time Range Selector ─────────────────────────────────────────────────
class _TimeRangeSelector extends StatelessWidget {
  final ReportRange range;
  final DateTimeRange? customRange;
  final ValueChanged<ReportRange> onRangeChanged;

  const _TimeRangeSelector({
    required this.range,
    required this.customRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<ReportRange>(
          segments: const [
            ButtonSegment(
              value: ReportRange.week,
              label: Text('7 Hari'),
              icon: Icon(Icons.calendar_view_week, size: 16),
            ),
            ButtonSegment(
              value: ReportRange.month,
              label: Text('30 Hari'),
              icon: Icon(Icons.calendar_month, size: 16),
            ),
            ButtonSegment(
              value: ReportRange.custom,
              label: Text('Custom'),
              icon: Icon(Icons.date_range, size: 16),
            ),
          ],
          selected: {range},
          onSelectionChanged: (sel) => onRangeChanged(sel.first),
          showSelectedIcon: false,
        ),
        if (range == ReportRange.custom && customRange != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${customRange!.start.day}/${customRange!.start.month}/${customRange!.start.year}'
              ' – '
              '${customRange!.end.day}/${customRange!.end.month}/${customRange!.end.year}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── #2: Empty State Chart Placeholder ───────────────────────────────────────
class _EmptyChartPlaceholder extends StatelessWidget {
  final VoidCallback onStartLogging;

  const _EmptyChartPlaceholder({required this.onStartLogging});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Skeleton bars
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _skeletonBar(theme, 0.3),
                _skeletonBar(theme, 0.6),
                _skeletonBar(theme, 0.4),
                _skeletonBar(theme, 0.8),
                _skeletonBar(theme, 0.5),
                _skeletonBar(theme, 0.35),
                _skeletonBar(theme, 0.65),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Icon(
            Icons.insights_rounded,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            'Catat 3 aktivitas pertamamu\nuntuk melihat grafik ini muncul!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onStartLogging,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Mulai Catat'),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBar(ThemeData theme, double heightFraction) {
    return Container(
      width: 22,
      height: 120 * heightFraction,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

// ─── #9: Chart Carousel with Tab Labels ──────────────────────────────────────
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
    final pageLabels = <String>[];

    if (widget.dailyCategoryData.isNotEmpty) {
      pages.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReportPageState._sectionHeader(
              theme,
              Icons.bar_chart_rounded,
              'Berdasarkan Kategori',
            ),
            const SizedBox(height: 12),
            _DailyCategoryChart(
              dailyCategoryData: widget.dailyCategoryData,
              categories: widget.categories,
            ),
          ],
        ),
      );
      pageLabels.add('Kategori per Hari');
    }

    if (widget.totalMinutes > 0) {
      pages.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReportPageState._sectionHeader(
              theme,
              Icons.stars_rounded,
              'Distribusi Nilai Waktu',
            ),
            const SizedBox(height: 12),
            _TimeValueDonut(
              timeValueMinutes: widget.timeValueMinutes,
              totalMinutes: widget.totalMinutes,
            ),
          ],
        ),
      );
      pageLabels.add('Nilai Waktu');
    }

    if (pages.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 380,
          child: PageView(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            children: pages,
          ),
        ),
        // #9: Tab labels instead of dots
        if (pages.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageLabels.length, (index) {
              final isActive = _currentPage == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? theme.colorScheme.primary.withValues(alpha: 0.4)
                            : theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                      ),
                    ),
                    child: Text(
                      pageLabels[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

// ─── #5, #10: Hero Grade Card ────────────────────────────────────────────────
class _HeroGradeCard extends StatefulWidget {
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
  State<_HeroGradeCard> createState() => _HeroGradeCardState();
}

class _HeroGradeCardState extends State<_HeroGradeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // #10: Animation plays only once on first build
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    // Delay start by 600ms like the original
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.gradeColor.withValues(alpha: 0.15),
            widget.gradeColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.gradeColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grade circle with #10 fixed animation
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: widget.gradeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.gradeColor, width: 2.5),
                ),
                child: Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      widget.grade,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: widget.gradeColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Score + label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: widget.avgScore),
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
          // #5: Score progress bar
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: widget.avgScore / 5.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutExpo,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  color: widget.gradeColor,
                  backgroundColor: widget.gradeColor.withValues(alpha: 0.15),
                  minHeight: 8,
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.summary,
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

// ─── #11: Score Info Sheet with Grade Table ───────────────────────────────────
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
            // #11: Visual grade table
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Grade',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'Skor',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Warna',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _gradeTableRow(theme, 'A', '≥ 4.5', Colors.amber),
                  _gradeTableRow(theme, 'B', '≥ 3.5', Colors.green),
                  _gradeTableRow(theme, 'C', '≥ 2.5', Colors.blue),
                  _gradeTableRow(theme, 'D', '≥ 1.5', Colors.orange),
                  _gradeTableRow(theme, 'E', '< 1.5', Colors.red, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Skor dihitung dari nilai waktu (bobot) setiap aktivitas yang kamu catat dikalikan dengan durasinya.\n\n'
              '⭐ Investasi: 5 Poin\n'
              '✅ Produktif: 4 Poin\n'
              '🔧 Kebutuhan: 3 Poin\n'
              '🎯 Santai: 2 Poin\n'
              '⚠️ Terbuang: 1 Poin\n\n'
              'Rata-rata tertimbang akan menentukan Grade akhirmu.',
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

  Widget _gradeTableRow(
    ThemeData theme,
    String grade,
    String score,
    Color color, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              grade,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: color,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(score, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── #4: Stat Card (InkWell removed, #8 subtitle added) ─────────────────────
class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
          // #8: Subtitle for percentage
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── #3: Daily Category Stacked Bar Chart (Today highlight) ──────────────────
class _DailyCategoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> dailyCategoryData;
  final List<String> categories;

  const _DailyCategoryChart({
    required this.dailyCategoryData,
    required this.categories,
  });

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

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
                    // #14: Consistent formatting
                    for (final cat in categories) {
                      final mins = catMap[cat] ?? 0;
                      if (mins <= 0) continue;
                      final emoji = CategoryMeta.emojiFor(cat);
                      buf.write(
                        '$emoji $cat: ${CategoryMeta.formatDuration(mins)}\n',
                      );
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
                    reservedSize: 32,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= dailyCategoryData.length) {
                        return const SizedBox.shrink();
                      }
                      final day = dailyCategoryData[idx]['day'] as DateTime;
                      final isToday =
                          now.year == day.year &&
                          now.month == day.month &&
                          now.day == day.day;
                      // #3: Today indicator with dot
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${day.day}',
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
                            if (isToday) ...[
                              const SizedBox(height: 2),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
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
                final day = dailyCategoryData[i]['day'] as DateTime;
                final isToday =
                    now.year == day.year &&
                    now.month == day.month &&
                    now.day == day.day;

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
                      CategoryMeta.colorFor(cat),
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
                      // #3: Highlight today's bar background
                      backDrawRodData: BackgroundBarChartRodData(
                        show: isToday,
                        toY: maxHrs * 1.2,
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.06,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend — uses centralized CategoryMeta
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: categories.map((cat) {
            final emoji = CategoryMeta.emojiFor(cat);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: CategoryMeta.colorFor(cat),
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

// ─── #6: TimeValue Donut Chart (Enlarged) ────────────────────────────────────
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
            radius: 48, // #6: Increased from 40
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
          width: 180, // #6: Increased from 140
          height: 180, // #6: Increased from 140
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40, // #6: Increased from 28
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // #14: Consistent duration formatting
            children: TimeValue.values.map((tv) {
              final mins = timeValueMinutes[tv] ?? 0;
              if (mins == 0) return const SizedBox.shrink();
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
                      CategoryMeta.formatDuration(mins),
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

// ─── #14: Category Row (Uses centralized formatting) ─────────────────────────
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
              CategoryMeta.formatDurationLong(minutes),
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
