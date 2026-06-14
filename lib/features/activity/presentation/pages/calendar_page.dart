import 'package:catat_in/features/activity/data/models/activity_model.dart';
import 'package:catat_in/features/activity/domain/time_value.dart';
import 'package:catat_in/features/activity/presentation/providers/activity_provider.dart';
import 'package:catat_in/features/activity/presentation/widgets/catat_in_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  /// Returns average timeValue score for a day (0 if no activities).
  double _getDayScore(DateTime day, List<ActivityModel> activities) {
    int totalMin = 0;
    int weighted = 0;
    for (final a in activities) {
      if (a.startAt == null || a.endAt == null) continue;
      if (a.createdAt.year != day.year ||
          a.createdAt.month != day.month ||
          a.createdAt.day != day.day) {
        continue;
      }
      final dur = a.endAt!.difference(a.startAt!).inMinutes;
      if (dur <= 0) continue;
      totalMin += dur;
      weighted += TimeValue.fromString(a.timeValue).score * dur;
    }
    return totalMin == 0 ? 0 : weighted / totalMin;
  }

  Color _scoreColor(double score) {
    if (score == 0) return Colors.grey.shade300;
    if (score >= 4.0) return Colors.green;
    if (score >= 3.0) return Colors.blue;
    if (score >= 2.0) return Colors.orange;
    return Colors.red;
  }

  static const _dayNames = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  static const _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  String _formatDate(DateTime d) {
    final dayName = _dayNames[d.weekday - 1];
    return '$dayName, ${d.day} ${_monthNames[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final activities = ref.watch(activityListProvider);

    // Filter + sort activities for selected day
    final selectedActivities = activities.where((a) {
      return a.createdAt.year == selectedDay.year &&
          a.createdAt.month == selectedDay.month &&
          a.createdAt.day == selectedDay.day;
    }).toList();

    selectedActivities.sort((a, b) {
      final aT = a.startAt ?? a.createdAt;
      final bT = b.startAt ?? b.createdAt;
      return aT.compareTo(bT);
    });

    // TimeValue breakdown
    final tvMins = <TimeValue, int>{};
    int totalMin = 0;
    for (final a in selectedActivities) {
      if (a.startAt == null || a.endAt == null) continue;
      final dur = a.endAt!.difference(a.startAt!).inMinutes;
      if (dur <= 0) continue;
      totalMin += dur;
      final tv = TimeValue.fromString(a.timeValue);
      tvMins[tv] = (tvMins[tv] ?? 0) + dur;
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CatatInAppBar(title: 'KALENDER'),
      body: Column(
        children: [
          // ── Compact Google-style calendar ──
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2035),
            focusedDay: focusedDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              leftChevronIcon: Icon(Icons.chevron_left,
                  color: theme.colorScheme.onSurfaceVariant),
              rightChevronIcon: Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              weekendStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              weekendTextStyle:
                  TextStyle(color: theme.colorScheme.onSurface),
              defaultTextStyle:
                  TextStyle(color: theme.colorScheme.onSurface),
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(4),
            ),
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });
            },
            eventLoader: (day) {
              return activities
                  .where((a) =>
                      a.createdAt.year == day.year &&
                      a.createdAt.month == day.month &&
                      a.createdAt.day == day.day)
                  .toList();
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  final score = _getDayScore(day, activities);
                  final color = _scoreColor(score);
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),

          // ── Day header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${selectedDay.day}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(selectedDay),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      selectedActivities.isEmpty
                          ? 'Tidak ada aktivitas'
                          : '${selectedActivities.length} aktivitas'
                              '  ·  '
                              '${totalMin ~/ 60}j ${totalMin % 60}m',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Compact TimeValue chips ──
          if (totalMin > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: TimeValue.values.map((tv) {
                  final mins = tvMins[tv] ?? 0;
                  if (mins == 0) return const SizedBox.shrink();
                  final h = mins ~/ 60;
                  final m = mins % 60;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tv.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${tv.emoji} ${h > 0 ? '${h}j' : ''}${m}m',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tv.color,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const Divider(height: 20),

          // ── Google Calendar-style event list ──
          Expanded(
            child: selectedActivities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_rounded,
                            size: 48,
                            color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada aktivitas',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: selectedActivities.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _EventCard(
                          activity: selectedActivities[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Google Calendar-style event card ───────────────────────────────────────
class _EventCard extends StatelessWidget {
  final ActivityModel activity;

  const _EventCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tv = TimeValue.fromString(activity.timeValue);
    final color = tv.color;

    final start = activity.startAt ?? activity.createdAt;
    final end = activity.endAt;

    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:'
        '${start.minute.toString().padLeft(2, '0')}';
    final endStr = end != null
        ? '${end.hour.toString().padLeft(2, '0')}:'
            '${end.minute.toString().padLeft(2, '0')}'
        : '--:--';

    final duration = end != null
        ? end.difference(start).inMinutes
        : 0;
    final h = duration ~/ 60;
    final m = duration % 60;
    final durLabel =
        duration > 0 ? (h > 0 ? '$h jam $m mnt' : '$m mnt') : '';

    // Category emoji lookup
    const emojiMap = {
      'Kerja': '🏢', 'Belajar': '📚', 'Olahraga': '🏃',
      'Hiburan': '🎮', 'Keseharian': '🍽', 'Sosial': '👥',
      'Ibadah': '🕌', 'Lainnya': '📌',
    };
    final emoji = emojiMap[activity.category] ?? '📌';

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Time column
            SizedBox(
              width: 60,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 4, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      endStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text('$emoji ${activity.category}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                        if (durLabel.isNotEmpty) ...[
                          Text('  ·  ',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                          Text(durLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                        ],
                      ],
                    ),
                    if ((activity.notes ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              activity.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (activity.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: activity.tags
                            .take(3)
                            .map((t) => Text(
                                  '#$t',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: color.withValues(alpha: 0.8),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
