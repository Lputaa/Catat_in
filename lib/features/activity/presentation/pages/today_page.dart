import 'package:catat_in/features/activity/domain/activity_category.dart';
import 'package:catat_in/features/activity/domain/time_value.dart';
import 'package:catat_in/features/activity/presentation/providers/activity_provider.dart';
import 'package:catat_in/features/activity/presentation/widgets/catat_in_app_bar.dart';
import 'package:catat_in/features/activity/presentation/widgets/timeline_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/activity_model.dart';

// ─── Shared utility ───────────────────────────────────────────────────────────
String formatHM(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

// ─── Timeline entry sealed class (type-safe union) ────────────────────────────
sealed class TimelineEntry {
  const TimelineEntry();
}

class ActivityEntry extends TimelineEntry {
  final ActivityModel activity;
  const ActivityEntry(this.activity);
}

class UntrackedEntry extends TimelineEntry {
  final DateTime start;
  final DateTime end;
  final int minutes;
  const UntrackedEntry({
    required this.start,
    required this.end,
    required this.minutes,
  });
}

class NowMarkerEntry extends TimelineEntry {
  const NowMarkerEntry();
}

// ─── Timeline builder logic (extracted for testability) ───────────────────────
List<TimelineEntry> buildTimelineEntries({
  required List<ActivityModel> todayActivities,
  required ActivityModel? runningActivity,
  required DateTime now,
}) {
  final entries = <TimelineEntry>[];
  if (todayActivities.isEmpty) return entries;

  final first = todayActivities.first;
  final last = todayActivities.last;
  final firstStart = first.startAt ?? first.createdAt;
  final lastEnd = last.endAt;

  // Untracked time from midnight to first activity
  final midnight = DateTime(now.year, now.month, now.day);
  final minutesBeforeFirst = firstStart.difference(midnight).inMinutes.clamp(0, 1440);
  if (minutesBeforeFirst >= 15) {
    entries.add(UntrackedEntry(
      start: midnight,
      end: firstStart,
      minutes: minutesBeforeFirst,
    ));
  }

  // Activities with gaps between them
  for (int i = 0; i < todayActivities.length; i++) {
    entries.add(ActivityEntry(todayActivities[i]));

    if (i < todayActivities.length - 1) {
      final current = todayActivities[i];
      final next = todayActivities[i + 1];
      if (current.endAt != null && next.startAt != null) {
        final gapMin = next.startAt!.difference(current.endAt!).inMinutes;
        // Only show gap if positive and >= 15 minutes (skip overlaps)
        if (gapMin >= 15) {
          entries.add(UntrackedEntry(
            start: current.endAt!,
            end: next.startAt!,
            minutes: gapMin,
          ));
        }
      }
    }
  }

  // "Now" marker or untracked time after last activity
  if (runningActivity != null) {
    entries.add(const NowMarkerEntry());
  } else if (lastEnd != null) {
    final minutesAfterLast = now.difference(lastEnd).inMinutes;
    if (minutesAfterLast >= 15) {
      entries.add(UntrackedEntry(
        start: lastEnd,
        end: now,
        minutes: minutesAfterLast,
      ));
    }
  }

  return entries;
}

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activityListProvider);
    // Use ref.watch for notifier too, so we react to provider recreation
    final notifier = ref.watch(activityListProvider.notifier);
    final runningActivity = notifier.getRunningActivity();

    final now = DateTime.now();
    final todayActivities =
        activities.where((activity) {
          return activity.createdAt.year == now.year &&
              activity.createdAt.month == now.month &&
              activity.createdAt.day == now.day;
        }).toList()..sort((a, b) {
          final aTime = a.startAt ?? a.createdAt;
          final bTime = b.startAt ?? b.createdAt;
          return aTime.compareTo(bTime);
        });

    final trackedMinutes = todayActivities.fold<int>(0, (sum, activity) {
      if (activity.startAt == null || activity.endAt == null) return sum;
      return sum + activity.endAt!.difference(activity.startAt!).inMinutes;
    });

    final coverage = trackedMinutes / (24 * 60);

    // Build interleaved timeline entries using extracted logic
    final entries = buildTimelineEntries(
      todayActivities: todayActivities,
      runningActivity: runningActivity,
      now: now,
    );

    // Reverse: newest at top
    final reversedEntries = entries.reversed.toList();

    String coverageLabel;
    Color coverageColor;
    if (coverage >= 0.8) {
      coverageLabel = 'Sangat Lengkap';
      coverageColor = Colors.green;
    } else if (coverage >= 0.5) {
      coverageLabel = 'Cukup Lengkap';
      coverageColor = Colors.orange;
    } else {
      coverageLabel = 'Banyak Waktu Belum Tercatat';
      coverageColor = Colors.red;
    }

    return Scaffold(
      appBar: const CatatInAppBar(title: 'HARI INI'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Running activity banner ─────────────────────────────
            if (runningActivity != null) ...[
              _RunningBanner(
                activity: runningActivity,
                onStop: () async {
                  await _showFinishSheet(context, runningActivity, notifier);
                },
              ),
              const SizedBox(height: 14),
            ],

            // ── Summary strip ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.30),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  _SummaryStat(
                    icon: Icons.check_circle_outline_rounded,
                    value: '${todayActivities.length}',
                    label: 'Aktivitas',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _divider(context),
                  _SummaryStat(
                    icon: Icons.schedule_rounded,
                    value:
                        '${trackedMinutes ~/ 60}j ${trackedMinutes % 60}m',
                    label: 'Tercatat',
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  _divider(context),
                  _SummaryStat(
                    icon: Icons.pie_chart_outline_rounded,
                    value: '${(coverage * 100).toStringAsFixed(0)}%',
                    label: coverageLabel,
                    color: coverageColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Timeline header ─────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Timeline',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (todayActivities.isNotEmpty)
                  Text(
                    '${formatHM(todayActivities.first.startAt ?? todayActivities.first.createdAt)}'
                    ' – '
                    '${formatHM(todayActivities.last.endAt ?? now)}',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Timeline list (reversed – newest first) ────────────
            Expanded(
              child: todayActivities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada aktivitas hari ini',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mulai catat aktivitasmu!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: reversedEntries.length,
                      itemBuilder: (context, index) {
                        final entry = reversedEntries[index];
                        return switch (entry) {
                          NowMarkerEntry() => const _NowMarker(),
                          UntrackedEntry(:final start, :final end, :final minutes) =>
                            _GapIndicator(
                              start: start,
                              end: end,
                              minutes: minutes,
                              notifier: notifier,
                            ),
                          ActivityEntry(:final activity) =>
                            TimelineItem(activity: activity),
                        };
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }

  Future<void> _showFinishSheet(
    BuildContext context,
    ActivityModel runningActivity,
    ActivityNotifier notifier,
  ) async {
    final finishNameController =
        TextEditingController(text: runningActivity.name);
    final finishNotesController = TextEditingController();
    final finishTags = <String>{};
    final finishCustomTags = <String>[];
    var finishCategory = ActivityCategory.lainnya;
    var finishTimeValue = TimeValue.fromString(runningActivity.timeValue);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selesaikan Aktivitas',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: finishNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama aktivitas saat disimpan',
                        hintText: 'Contoh: Belajar Flutter',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: finishNotesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                        hintText: 'Tambahkan catatan...',
                        prefixIcon: Icon(Icons.notes_rounded),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Nilai Waktu',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: TimeValue.values.map((tv) {
                        final sel = finishTimeValue == tv;
                        return ChoiceChip(
                          label: Text('${tv.emoji} ${tv.shortLabel}'),
                          selected: sel,
                          selectedColor: tv.color.withValues(alpha: 0.25),
                          onSelected: (v) {
                            if (v) {
                              setSheetState(() => finishTimeValue = tv);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    const Text('Pilih kategori dan tag sebelum menyimpan.'),
                    const SizedBox(height: 12),
                    // ── Kategori ──
                    DropdownButtonFormField<ActivityCategory>(
                      initialValue: finishCategory,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                        prefixIcon:
                            const Icon(Icons.category_rounded),
                      ),
                      items: ActivityCategory.values
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text('${c.emoji}  ${c.label}')))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => finishCategory = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    // ── Tag (Sub Kategori) ──
                    Text(
                      'Tag (Sub Kategori)',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...finishCategory.subTags.map((tag) {
                          final selected = finishTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: selected,
                            onSelected: (value) {
                              setSheetState(() {
                                if (value) { finishTags.add(tag); }
                                else { finishTags.remove(tag); }
                              });
                            },
                          );
                        }),
                        ...finishCustomTags.map((tag) {
                          final selected = finishTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: selected,
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              setSheetState(() {
                                finishCustomTags.remove(tag);
                                finishTags.remove(tag);
                              });
                            },
                            onSelected: (value) {
                              setSheetState(() {
                                if (value) { finishTags.add(tag); }
                                else { finishTags.remove(tag); }
                              });
                            },
                          );
                        }),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: const Text('Tambah'),
                          onPressed: () async {
                            final controller = TextEditingController();
                            final tag = await showDialog<String>(
                              context: sheetContext,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Tambah Tag Baru'),
                                content: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    labelText: 'Nama tag',
                                    prefixIcon: const Icon(Icons.local_offer_rounded),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Batal'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                                    child: const Text('Tambah'),
                                  ),
                                ],
                              ),
                            );
                            if (tag != null && tag.isNotEmpty) {
                              setSheetState(() => finishCustomTags.add(tag));
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (finishTags.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pilih minimal 1 tag sebelum menyimpan.',
                                ),
                              ),
                            );
                            return;
                          }
                          await notifier.finishRunningActivity(
                            timeValue: finishTimeValue,
                            category: finishCategory.label,
                            tags: finishTags.toList(),
                            name: finishNameController.text.trim(),
                            notes: finishNotesController.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                        child: const Text('Simpan Aktivitas'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Running activity banner ──────────────────────────────────────────────
class _RunningBanner extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback onStop;

  const _RunningBanner({required this.activity, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sedang Berjalan',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: onStop,
            icon: const Icon(Icons.stop_rounded, size: 18),
            label: const Text('Selesai'),
          ),
        ],
      ),
    );
  }
}

// ─── Summary stat cell ────────────────────────────────────────────────────
class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── "Now" marker ─────────────────────────────────────────────────────────
class _NowMarker extends StatelessWidget {
  const _NowMarker();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Sedang berlangsung...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
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
}

// ─── Tappable untracked-time indicator with add-activity sheet ────────────
class _GapIndicator extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  final int minutes;
  final ActivityNotifier notifier;

  const _GapIndicator({
    required this.start,
    required this.end,
    required this.minutes,
    required this.notifier,
  });

  @override
  State<_GapIndicator> createState() => _GapIndicatorState();
}

class _GapIndicatorState extends State<_GapIndicator> {
  String _durationLabel() {
    final h = widget.minutes ~/ 60;
    final m = widget.minutes % 60;
    if (h > 0 && m > 0) return '${h}j ${m}m';
    if (h > 0) return '$h jam';
    return '$m menit';
  }

  void _openAddSheet() async {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    var startTime = TimeOfDay.fromDateTime(widget.start);
    var endTime = TimeOfDay.fromDateTime(widget.end);
    var category = ActivityCategory.lainnya;
    var timeValue = TimeValue.kebutuhan;
    final tags = <String>{};
    final gapCustomTags = <String>[];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_circle_rounded,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Tambah Aktivitas',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Isi aktivitas yang lupa kamu catat pada rentang waktu ini.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nama aktivitas',
                        hintText: 'Contoh: Makan siang',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                        hintText: 'Tambahkan catatan...',
                        prefixIcon: Icon(Icons.notes_rounded),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final p = await showTimePicker(
                                context: sheetCtx,
                                initialTime: startTime,
                              );
                              if (p != null) {
                                setSheet(() => startTime = p);
                              }
                            },
                            icon: const Icon(
                                Icons.play_circle_outline_rounded),
                            label: Text(
                              '${startTime.hour.toString().padLeft(2, '0')}:'
                              '${startTime.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final p = await showTimePicker(
                                context: sheetCtx,
                                initialTime: endTime,
                              );
                              if (p != null) {
                                setSheet(() => endTime = p);
                              }
                            },
                            icon: const Icon(
                                Icons.stop_circle_outlined),
                            label: Text(
                              '${endTime.hour.toString().padLeft(2, '0')}:'
                              '${endTime.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Nilai Waktu',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: TimeValue.values.map((tv) {
                        final sel = timeValue == tv;
                        return ChoiceChip(
                          label: Text('${tv.emoji} ${tv.shortLabel}'),
                          selected: sel,
                          selectedColor: tv.color.withValues(alpha: 0.25),
                          onSelected: (v) {
                            if (v) setSheet(() => timeValue = tv);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // ── Kategori ──
                    DropdownButtonFormField<ActivityCategory>(
                      initialValue: category,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                        prefixIcon:
                            const Icon(Icons.category_rounded),
                      ),
                      items: ActivityCategory.values
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text('${c.emoji}  ${c.label}')))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSheet(() => category = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    // ── Tag (Sub Kategori) ──
                    Text('Tag (Sub Kategori)',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...category.subTags.map((tag) {
                          final sel = tags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: sel,
                            onSelected: (v) {
                              setSheet(() {
                                if (v) { tags.add(tag); }
                                else { tags.remove(tag); }
                              });
                            },
                          );
                        }),
                        ...gapCustomTags.map((tag) {
                          final sel = tags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: sel,
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              setSheet(() {
                                gapCustomTags.remove(tag);
                                tags.remove(tag);
                              });
                            },
                            onSelected: (v) {
                              setSheet(() {
                                if (v) { tags.add(tag); }
                                else { tags.remove(tag); }
                              });
                            },
                          );
                        }),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: const Text('Tambah'),
                          onPressed: () async {
                            final controller = TextEditingController();
                            final tag = await showDialog<String>(
                              context: sheetCtx,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Tambah Tag Baru'),
                                content: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    labelText: 'Nama tag',
                                    prefixIcon: const Icon(Icons.local_offer_rounded),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Batal'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                                    child: const Text('Tambah'),
                                  ),
                                ],
                              ),
                            );
                            if (tag != null && tag.isNotEmpty) {
                              setSheet(() => gapCustomTags.add(tag));
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Masukkan nama aktivitas.'),
                              ),
                            );
                            return;
                          }
                          if (tags.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Pilih minimal 1 tag.'),
                              ),
                            );
                            return;
                          }
                          final base = widget.start;
                          final startDt = DateTime(
                            base.year, base.month, base.day,
                            startTime.hour, startTime.minute,
                          );
                          final endDt = DateTime(
                            base.year, base.month, base.day,
                            endTime.hour, endTime.minute,
                          );
                          await widget.notifier.addManualActivity(
                            name: name,
                            startAt: startDt,
                            endAt: endDt,
                            category: category.label,
                            timeValue: timeValue,
                            tags: tags.toList(),
                            notes: notesController.text.trim(),
                          );
                          if (sheetCtx.mounted) {
                            Navigator.of(sheetCtx).pop();
                          }
                        },
                        child: const Text('Simpan Aktivitas'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = widget.minutes >= 60;
    final color = isLarge
        ? Colors.orange.shade700
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(left: 56, bottom: 10),
      child: Row(
        children: [
          // Dashed connector
          SizedBox(
            width: 30,
            child: Column(
              children: List.generate(
                4,
                (_) => Container(
                  margin: const EdgeInsets.only(bottom: 3),
                  width: 2,
                  height: 5,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Tappable card
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openAddSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isLarge
                        ? Colors.orange.withValues(alpha: 0.08)
                        : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLarge
                          ? Colors.orange.withValues(alpha: 0.25)
                          : Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isLarge) ...[
                        Icon(Icons.warning_amber_rounded,
                            size: 15, color: color),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${formatHM(widget.start)} – ${formatHM(widget.end)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        color.withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _durationLabel(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Belum tercatat – ketuk untuk menambahkan',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 22,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
