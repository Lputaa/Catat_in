import 'package:catat_in/core/services/notification_service.dart';
import 'package:catat_in/features/activity/domain/activity_category.dart';
import 'package:catat_in/features/activity/domain/time_value.dart';
import 'package:catat_in/features/activity/presentation/providers/activity_provider.dart';
import 'package:catat_in/features/activity/presentation/widgets/catat_in_app_bar.dart';
import 'package:catat_in/features/activity/presentation/widgets/log/template_section.dart';
import 'package:catat_in/features/activity/presentation/widgets/timeline_item.dart';
import 'package:catat_in/features/activity/presentation/widgets/today/gap_indicator.dart';
import 'package:catat_in/features/activity/presentation/widgets/today/now_marker.dart';
import 'package:catat_in/features/activity/presentation/widgets/today/running_banner.dart';
import 'package:catat_in/features/activity/presentation/widgets/today/summary_stat.dart';
import 'package:catat_in/features/activity/presentation/widgets/today/timeline_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/activity_model.dart';

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
              RunningBanner(
                activity: runningActivity,
                onStop: () async {
                  if (runningActivity.templateName != null) {
                    // Template-based: show confirmation first
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dlg) => AlertDialog(
                        title: const Text('Selesaikan Aktivitas?'),
                        content: Text(
                          '${runningActivity.name} akan disimpan dengan durasi saat ini.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dlg, false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dlg, true),
                            child: const Text('Ya, Selesai'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await notifier.stopActivity();
                      await NotificationService.finishTrackingNotification(
                        runningActivity.name,
                        '',
                      );
                    }
                  } else {
                    await NotificationService.cancelTrackingNotification();
                    if (context.mounted) {
                      await _showFinishSheet(context, runningActivity, notifier);
                    }
                  }
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
                  SummaryStat(
                    icon: Icons.check_circle_outline_rounded,
                    value: '${todayActivities.length}',
                    label: 'Aktivitas',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _divider(context),
                  SummaryStat(
                    icon: Icons.schedule_rounded,
                    value:
                        '${trackedMinutes ~/ 60}j ${trackedMinutes % 60}m',
                    label: 'Tercatat',
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  _divider(context),
                  SummaryStat(
                    icon: Icons.pie_chart_outline_rounded,
                    value: '${(coverage * 100).toStringAsFixed(0)}%',
                    label: coverageLabel,
                    color: coverageColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Template shortcuts (only when idle) ──────────────
            if (runningActivity == null) ...[
              const TemplateQuickStartSection(),
              const SizedBox(height: 20),
            ],

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
                          NowMarkerEntry() => const NowMarker(),
                          UntrackedEntry(:final start, :final end, :final minutes) =>
                            GapIndicator(
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
                    const Text('Pilih kategori sebelum menyimpan.'),
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
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          await notifier.finishRunningActivity(
                            timeValue: finishTimeValue,
                            category: finishCategory.label,
                            name: finishNameController.text.trim(),
                            notes: finishNotesController.text.trim(),
                          );
                          await NotificationService.finishTrackingNotification(
                            finishNameController.text.trim().isNotEmpty
                                ? finishNameController.text.trim()
                                : runningActivity.name,
                            '',
                          );
                          if (sheetContext.mounted) {
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
