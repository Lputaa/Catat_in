import 'dart:async';
import 'dart:math' as math;

import 'package:catat_in/core/services/notification_service.dart';
import 'package:catat_in/features/activity/data/models/activity_model.dart';
import 'package:catat_in/features/activity/data/models/activity_template_model.dart';
import 'package:catat_in/features/activity/domain/activity_category.dart';
import 'package:catat_in/features/activity/domain/time_value.dart';
import 'package:catat_in/features/activity/presentation/providers/activity_provider.dart';
import 'package:catat_in/features/activity/presentation/providers/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _LogTab { tracking, manual }

class LogPage extends ConsumerStatefulWidget {
  const LogPage({super.key});

  @override
  ConsumerState<LogPage> createState() => _LogPageState();
}

class _LogPageState extends ConsumerState<LogPage> {
  final PageController _formController = PageController(viewportFraction: 0.95);
  final trackingController = TextEditingController();
  final manualActivityController = TextEditingController();
  final manualNotesController = TextEditingController();

  _LogTab _activeTab = _LogTab.tracking;

  DateTime? startAt;
  DateTime? endAt;

  TimeValue selectedTimeValue = TimeValue.kebutuhan;

  ActivityCategory selectedCategory = ActivityCategory.lainnya;
  ActivityCategory trackingCategory = ActivityCategory.lainnya;

  Timer? trackingTimer;
  Duration currentDuration = Duration.zero;

  @override
  void dispose() {
    trackingTimer?.cancel();
    _formController.dispose();
    trackingController.dispose();
    manualActivityController.dispose();
    manualNotesController.dispose();
    super.dispose();
  }

  Future<void> pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;

    final now = DateTime.now();
    final dateTime = DateTime(
      now.year, now.month, now.day, picked.hour, picked.minute,
    );

    setState(() {
      if (isStart) {
        startAt = dateTime;
      } else {
        endAt = dateTime;
      }
    });
  }

  void startRealtimeTimer(DateTime startAt) {
    trackingTimer?.cancel();
    trackingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        currentDuration = DateTime.now().difference(startAt);
      });
    });
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ── Finish dialog ──────────────────────────────────────────────
  Future<void> showFinishDialog(ActivityModel activity) async {
    final finishNameController = TextEditingController(text: activity.name);
    final finishNotesController = TextEditingController();
    var finishCategory = ActivityCategory.lainnya;
    var finishTimeValue = TimeValue.fromString(activity.timeValue);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final duration = DateTime.now().difference(activity.startAt!);
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.stop_circle_rounded,
                              color: Colors.red),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Selesaikan Aktivitas',
                                  style: TextStyle(fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(formatDuration(duration),
                                  style: TextStyle(fontSize: 13,
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: finishNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama aktivitas saat disimpan',
                        hintText: 'Contoh: Belajar Flutter',
                        prefixIcon: Icon(Icons.label_outline_rounded),
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
                    const SizedBox(height: 16),
                    _sheetSectionLabel('Nilai Waktu'),
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
                            if (v) setSheet(() => finishTimeValue = tv);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // ── Kategori ──
                    _buildCategoryDropdown(
                      value: finishCategory,
                      onChanged: (v) {
                        if (v != null) setSheet(() => finishCategory = v);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(activityListProvider.notifier)
                              .finishRunningActivity(
                                timeValue: finishTimeValue,
                                category: finishCategory.label,
                                name: finishNameController.text.trim().isNotEmpty
                                    ? finishNameController.text.trim()
                                    : null,
                                notes: finishNotesController.text.trim(),
                              );
                          await NotificationService.finishTrackingNotification(
                            finishNameController.text.trim().isNotEmpty
                                ? finishNameController.text.trim()
                                : activity.name,
                            '',
                          );
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text('Simpan Aktivitas'),
                        ),
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

  // ── Shared widgets ─────────────────────────────────────────────
  Widget _sheetSectionLabel(String label) {
    return Text(label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600));
  }

  Widget _buildCategoryDropdown({
    required ActivityCategory value,
    required ValueChanged<ActivityCategory?> onChanged,
  }) {
    return DropdownButtonFormField<ActivityCategory>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'Kategori',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        prefixIcon: const Icon(Icons.category_rounded),
      ),
      items: ActivityCategory.values.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Text('${c.emoji}  ${c.label}'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // ── Tracking card ──────────────────────────────────────────────
  Widget _buildTrackingCard(
    BuildContext context, WidgetRef ref, ActivityModel? running,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 20,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mulai tracking aktivitas yang sedang berjalan. '
                    'Detail ditambahkan saat selesai.',
                    style: TextStyle(fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Hero timer area ──
          if (running != null && running.startAt != null) ...[
            Center(
              child: SizedBox(
                width: 200, height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CustomPaint(
                        painter: _TimerRingPainter(
                          progress: (currentDuration.inSeconds % 60) / 60,
                          color: theme.colorScheme.primary,
                          trackColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7, height: 7,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('Berjalan', style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          formatDuration(currentDuration),
                          style: TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    running.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    running.category,
                    style: TextStyle(fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  if (running.templateName != null) {
                    // Template-based: show confirmation first
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dlg) => AlertDialog(
                        title: const Text('Selesaikan Aktivitas?'),
                        content: Text(
                          '${running.name} akan disimpan dengan durasi saat ini.',
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
                      ref.read(activityListProvider.notifier).stopActivity();
                      NotificationService.finishTrackingNotification(
                        running.name,
                        '',
                      );
                    }
                  } else {
                    NotificationService.cancelTrackingNotification();
                    showFinishDialog(running);
                  }
                },
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Selesai & Simpan',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ] else ...[
            // ── Idle state: start form ──
            Center(
              child: SizedBox(
                width: 160, height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CustomPaint(
                        painter: _TimerRingPainter(
                          progress: 0,
                          color: theme.colorScheme.outlineVariant,
                          trackColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    Icon(Icons.play_circle_outline_rounded,
                        size: 56, color: theme.colorScheme.outlineVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: trackingController,
              decoration: InputDecoration(
                labelText: 'Apa yang sedang kamu lakukan?',
                hintText: 'Contoh: Belajar Flutter',
                prefixIcon: const Icon(Icons.edit_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryDropdown(
              value: trackingCategory,
              onChanged: (v) {
                if (v != null) setState(() => trackingCategory = v);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await ref.read(activityListProvider.notifier)
                      .startActivity(
                        name: trackingController.text.trim(),
                        category: trackingCategory.label,
                      );
                  trackingController.clear();
                  setState(() {
                    selectedCategory = ActivityCategory.lainnya;
                  });
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Mulai Tracking',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ── Template quick-start section ──
            _buildTemplateSection(context, ref, theme),
          ],
        ],
      ),
    );
  }

  void _confirmAndStartTemplate(
      BuildContext context, WidgetRef ref, ActivityTemplateModel t) {
    final tv = TimeValue.fromString(t.timeValue);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: tv.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tv.color.withValues(alpha: 0.25)),
              ),
              alignment: Alignment.center,
              child: Text(t.emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 16),
            Text('Mulai tracking?',
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(t.name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${t.category} · ${tv.shortLabel}',
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Batal'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref.read(activityListProvider.notifier)
                          .startFromTemplate(t);
                      NotificationService.showTrackingNotification(
                          t.name, t.emoji);
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Mulai'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Template quick-start section ─────────────────────────────────
  Widget _buildTemplateSection(
      BuildContext context, WidgetRef ref, ThemeData theme) {
    final templates = ref.watch(templateListProvider);
    if (templates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.bolt_rounded, size: 16,
                  color: theme.colorScheme.secondary),
            ),
            const SizedBox(width: 10),
            Text('Mulai Cepat',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${templates.length} template',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final t = templates[i];
              final tv = TimeValue.fromString(t.timeValue);
              return ActionChip(
                avatar: Text(t.emoji, style: const TextStyle(fontSize: 16)),
                label: Text(t.name, style: const TextStyle(fontSize: 13)),
                backgroundColor: tv.color.withValues(alpha: 0.08),
                side: BorderSide(
                  color: tv.color.withValues(alpha: 0.25),
                ),
                onPressed: () {
                  _confirmAndStartTemplate(context, ref, t);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Manual card ────────────────────────────────────────────────
  Widget _buildManualCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity name
          TextField(
            controller: manualActivityController,
            decoration: InputDecoration(
              labelText: 'Nama aktivitas',
              hintText: 'Contoh: Menulis laporan',
              prefixIcon: const Icon(Icons.label_outline_rounded),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          // Notes
          TextField(
            controller: manualNotesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Catatan',
              hintText: 'Tambahkan catatan...',
              prefixIcon: const Icon(Icons.notes_rounded),
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),

          const SizedBox(height: 20),

          // ── Section: Time ──
          _formSectionHeader(
            icon: Icons.schedule_rounded,
            label: 'Rentang Waktu',
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TimePickerButton(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Mulai',
                  time: startAt,
                  onTap: () => pickTime(true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 18,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              Expanded(
                child: _TimePickerButton(
                  icon: Icons.stop_circle_outlined,
                  label: 'Selesai',
                  time: endAt,
                  onTap: () => pickTime(false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Section: Time Value ──
          _formSectionHeader(
            icon: Icons.stars_rounded,
            label: 'Nilai Waktu',
            color: selectedTimeValue.color,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: TimeValue.values.map((tv) {
              final sel = selectedTimeValue == tv;
              return ChoiceChip(
                label: Text('${tv.emoji} ${tv.shortLabel}'),
                selected: sel,
                selectedColor: tv.color.withValues(alpha: 0.25),
                onSelected: (v) {
                  if (v) setState(() => selectedTimeValue = tv);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── Section: Kategori ──
          _formSectionHeader(
            icon: Icons.category_rounded,
            label: 'Kategori',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 10),
          _buildCategoryDropdown(
            value: selectedCategory,
            onChanged: (v) {
              if (v != null) setState(() => selectedCategory = v);
            },
          ),

          const SizedBox(height: 24),

          // ── Save button ──
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                if (manualActivityController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Masukkan nama aktivitas.')),
                  );
                  return;
                }
                if (startAt == null || endAt == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Pilih waktu mulai dan selesai.')),
                  );
                  return;
                }
                await ref.read(activityListProvider.notifier)
                    .addActivity(ActivityModel(
                  name: manualActivityController.text.trim(),
                  startAt: startAt,
                  endAt: endAt,
                  timeValue: selectedTimeValue.name,
                  createdAt: DateTime.now(),
                  category: selectedCategory.label,
                  notes: manualNotesController.text.trim(),
                ));
                manualActivityController.clear();
                manualNotesController.clear();
                setState(() {
                  startAt = null;
                  endAt = null;
                  selectedCategory = ActivityCategory.lainnya;
                  selectedTimeValue = TimeValue.kebutuhan;
                });
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aktivitas berhasil disimpan!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Simpan Aktivitas',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _formSectionHeader({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(activityListProvider.notifier);
    final runningActivity = notifier.getRunningActivity();

    if (runningActivity != null && runningActivity.startAt != null) {
      final duration = DateTime.now().difference(runningActivity.startAt!);
      if (duration != currentDuration) {
        startRealtimeTimer(runningActivity.startAt!);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Catat Aktivitas')),
      body: Column(
        children: [
          // ── Tab bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_LogTab>(
                segments: [
                  ButtonSegment(
                    value: _LogTab.tracking,
                    label: const Text('Tracking'),
                    icon: Icon(
                      runningActivity != null
                          ? Icons.fiber_manual_record_rounded
                          : Icons.play_circle_outline_rounded,
                      size: 18,
                      color: runningActivity != null
                          ? Colors.green : null,
                    ),
                  ),
                  const ButtonSegment(
                    value: _LogTab.manual,
                    label: Text('Input Manual'),
                    icon: Icon(Icons.edit_note_rounded, size: 18),
                  ),
                ],
                selected: {_activeTab},
                onSelectionChanged: (v) {
                  final tab = v.first;
                  setState(() => _activeTab = tab);
                  _formController.animateToPage(
                    tab.index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),

          // ── Form area ──
          Expanded(
            child: PageView(
              controller: _formController,
              onPageChanged: (i) {
                setState(() => _activeTab = _LogTab.values[i]);
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildTrackingCard(
                      context, ref, runningActivity),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildManualCard(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timer ring painter ─────────────────────────────────────────────────────
class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _TimerRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 6.0;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Time picker button ─────────────────────────────────────────────────────
class _TimePickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? time;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.icon,
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTime = time != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: hasTime
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasTime
                  ? theme.colorScheme.primary.withValues(alpha: 0.25)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20,
                  color: hasTime ? theme.colorScheme.primary : null),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
                  const SizedBox(height: 2),
                  Text(
                    hasTime
                        ? '${time!.hour.toString().padLeft(2, '0')}:'
                            '${time!.minute.toString().padLeft(2, '0')}'
                        : '--:--',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: hasTime ? theme.colorScheme.onSurface : null,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
