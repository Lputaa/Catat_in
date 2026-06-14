import 'package:catat_in/features/activity/domain/activity_category.dart';
import 'package:catat_in/features/activity/domain/time_value.dart';
import 'package:catat_in/features/activity/presentation/providers/activity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/activity_model.dart';

class TimelineItem extends ConsumerStatefulWidget {
  final ActivityModel activity;

  const TimelineItem({super.key, required this.activity});

  @override
  ConsumerState<TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends ConsumerState<TimelineItem> {
  // ── Formatting helpers ──────────────────────────────────────────────────────
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}j ${m}m';
    if (h > 0) return '${h}j';
    return '${m}m';
  }

  // ── Save with validation & loading guard ────────────────────────────────────
  Future<void> _saveEdit({
    required ActivityModel activity,
    required String name,
    required TimeValue timeValue,
    required List<String> tags,
    required String category,
    required DateTime? startAt,
    required DateTime? endAt,
    required String notes,
    required VoidCallback onSaved,
    required ValueSetter<bool> setLoading,
  }) async {
    // Validate time range
    if (startAt != null && endAt != null && !endAt.isAfter(startAt)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waktu selesai harus setelah waktu mulai.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setLoading(true);

    try {
      await ref
          .read(activityListProvider.notifier)
          .updateActivity(
            activity,
            name: name.trim().isEmpty ? activity.name : name.trim(),
            timeValue: timeValue.name,
            tags: tags,
            category: category,
            startAt: startAt,
            endAt: endAt,
            isRunning: activity.isRunning,
            notes: notes.trim(),
          );
      HapticFeedback.mediumImpact();
      onSaved();
    } finally {
      setLoading(false);
    }
  }

  // ── Edit sheet (local state — no stale data) ────────────────────────────────
  void _showEditSheet() {
    final activity = widget.activity;

    // All edit state is local to this sheet invocation.
    // Fresh from activity data every time the sheet opens.
    final nameController = TextEditingController(text: activity.name);
    final notesController = TextEditingController(text: activity.notes ?? '');
    var category = ActivityCategory.values.firstWhere(
      (item) => item.label == activity.category,
      orElse: () => ActivityCategory.lainnya,
    );
    var timeValue = TimeValue.fromString(activity.timeValue);
    final selectedTags = Set<String>.from(activity.tags);
    final customTags = <String>[];
    // Preserve custom tags (tags not in the current category's subTags)
    for (final tag in activity.tags) {
      if (!category.subTags.contains(tag) && !customTags.contains(tag)) {
        customTags.add(tag);
      }
    }
    DateTime? startAt = activity.startAt;
    DateTime? endAt = activity.endAt;
    bool isSaving = false;

    Future<void> pickTime(bool isStart, StateSetter setSheetState) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          (isStart ? startAt : endAt) ?? DateTime.now(),
        ),
      );
      if (picked == null) return;

      final base = (isStart ? startAt : endAt) ?? DateTime.now();
      final updated = DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      );

      setSheetState(() {
        if (isStart) {
          startAt = updated;
        } else {
          endAt = updated;
        }
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                // Fix keyboard overlap
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Aktivitas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama aktivitas',
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
                    Text(
                      'Nilai Waktu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: TimeValue.values.map((tv) {
                        final sel = timeValue == tv;
                        return ChoiceChip(
                          label: Text('${tv.emoji} ${tv.shortLabel}',
                              style: const TextStyle(fontSize: 12)),
                          selected: sel,
                          selectedColor: tv.color.withValues(alpha: 0.25),
                          onSelected: (v) {
                            if (v) {
                              setSheetState(() => timeValue = tv);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // ── Kategori (before tags) ──
                    DropdownButtonFormField<ActivityCategory>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: ActivityCategory.values
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text('${cat.emoji}  ${cat.label}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => category = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    // ── Tag (Sub Kategori) ──
                    Text(
                      'Tag (Sub Kategori)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...category.subTags.map((tag) {
                          final selected = selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: selected,
                            onSelected: (value) {
                              setSheetState(() {
                                if (value) { selectedTags.add(tag); }
                                else { selectedTags.remove(tag); }
                              });
                            },
                          );
                        }),
                        ...customTags.map((tag) {
                          final selected = selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: selected,
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              setSheetState(() {
                                customTags.remove(tag);
                                selectedTags.remove(tag);
                              });
                            },
                            onSelected: (value) {
                              setSheetState(() {
                                if (value) { selectedTags.add(tag); }
                                else { selectedTags.remove(tag); }
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
                              setSheetState(() => customTags.add(tag));
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickTime(true, setSheetState),
                            icon: const Icon(Icons.play_circle_outline_rounded),
                            label: Text(
                              startAt == null
                                  ? 'Waktu Mulai'
                                  : '${startAt!.hour.toString().padLeft(2, '0')}:${startAt!.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickTime(false, setSheetState),
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: Text(
                              endAt == null
                                  ? 'Waktu Selesai'
                                  : '${endAt!.hour.toString().padLeft(2, '0')}:${endAt!.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isSaving
                            ? null
                            : () => _saveEdit(
                                  activity: activity,
                                  name: nameController.text,
                                  timeValue: timeValue,
                                  tags: selectedTags.toList(),
                                  category: category.label,
                                  startAt: startAt,
                                  endAt: endAt,
                                  notes: notesController.text,
                                  onSaved: () {
                                    if (mounted) Navigator.of(context).pop();
                                  },
                                  setLoading: (v) =>
                                      setSheetState(() => isSaving = v),
                                ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Simpan Perubahan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Dispose controllers when sheet is closed
      nameController.dispose();
      notesController.dispose();
    });
  }

  // ── Delete with confirmation + undo SnackBar ────────────────────────────────
  Future<void> _showDeleteConfirmDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Aktivitas?'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus aktivitas ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final notifier = ref.read(activityListProvider.notifier);
      final activityName = widget.activity.name;
      await notifier.deleteActivity(widget.activity);
      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$activityName" dihapus.'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await notifier.undoDelete();
              },
            ),
          ),
        );
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final start = activity.startAt ?? activity.createdAt;
    final end = activity.endAt;
    final duration = end != null ? end.difference(start) : Duration.zero;
    final isRunning = activity.isRunning;

    final timeValueColor = TimeValue.fromString(activity.timeValue).color;
    final dotColor = isRunning ? Colors.green : timeValueColor;
    final cardTint = isRunning ? Colors.green : timeValueColor;

    // Category emoji lookup
    final categoryEmoji = ActivityCategory.values
        .where((c) => c.label == activity.category)
        .map((c) => c.emoji)
        .firstOrNull;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: time range column ──────────────────────────────
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // End time at top (lighter – where we came from above)
                Text(
                  end != null ? _formatTime(end) : '···',
                  style: TextStyle(
                    fontSize: 11,
                    color: end != null
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Colors.green,
                    fontWeight: end == null ? FontWeight.w600 : null,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                // Start time at bottom (bold – the anchor of this entry)
                Text(
                  _formatTime(start),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.15,
                  ),
                ),
                const Spacer(),
                if (end != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cardTint.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cardTint,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Middle: dot + vertical connector line ────────────────
          SizedBox(
            width: 30,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Continuous vertical line (light→dark for reversed flow)
                Container(
                  width: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        dotColor.withValues(alpha: 0.12),
                        dotColor.withValues(alpha: 0.50),
                      ],
                    ),
                  ),
                ),
                // Dot
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 3,
                      ),
                      boxShadow: isRunning
                          ? [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.45),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Right: activity card ─────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cardTint.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cardTint.withValues(alpha: isRunning ? 0.40 : 0.22),
                  width: isRunning ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: emoji + name + edit/delete
                  Row(
                    children: [
                      if (categoryEmoji != null) ...[
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cardTint.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            categoryEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          activity.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (!isRunning) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: _showEditSheet,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: _showDeleteConfirmDialog,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Category + duration chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildChip(
                        activity.category,
                        bgColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                      if (isRunning)
                        _buildChip(
                          'Sedang berjalan...',
                          bgColor: Colors.green.withValues(alpha: 0.15),
                          textColor: Colors.green.shade700,
                          icon: Icons.circle,
                          iconSize: 8,
                          iconColor: Colors.green,
                        )
                      else if (end != null)
                        _buildChip(
                          _formatDuration(duration),
                          bgColor: cardTint.withValues(alpha: 0.12),
                          textColor: cardTint,
                        ),
                    ],
                  ),

                  if ((activity.notes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              activity.notes ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (activity.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: activity.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    String label, {
    Color? bgColor,
    Color? textColor,
    IconData? icon,
    double? iconSize,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize ?? 12, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
