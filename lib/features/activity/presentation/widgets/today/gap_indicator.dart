import 'package:catat_in/features/activity/domain/activity_category.dart';
import 'package:catat_in/features/activity/domain/time_value.dart';
import 'package:catat_in/features/activity/presentation/providers/activity_provider.dart';
import 'package:catat_in/features/activity/presentation/widgets/today/timeline_models.dart';
import 'package:flutter/material.dart';

class GapIndicator extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  final int minutes;
  final ActivityNotifier notifier;

  const GapIndicator({
    super.key,
    required this.start,
    required this.end,
    required this.minutes,
    required this.notifier,
  });

  @override
  State<GapIndicator> createState() => _GapIndicatorState();
}

class _GapIndicatorState extends State<GapIndicator> {
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
                            icon: const Icon(Icons.stop_circle_outlined),
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
                      spacing: 8,
                      runSpacing: 8,
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
                        prefixIcon: const Icon(Icons.category_rounded),
                      ),
                      items: ActivityCategory.values
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('${c.emoji}  ${c.label}')))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSheet(() => category = v);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Masukkan nama aktivitas.'),
                              ),
                            );
                            return;
                          }
                          final base = widget.start;
                          final startDt = DateTime(
                            base.year,
                            base.month,
                            base.day,
                            startTime.hour,
                            startTime.minute,
                          );
                          final endDt = DateTime(
                            base.year,
                            base.month,
                            base.day,
                            endTime.hour,
                            endTime.minute,
                          );
                          await widget.notifier.addManualActivity(
                            name: name,
                            startAt: startDt,
                            endAt: endDt,
                            category: category.label,
                            timeValue: timeValue,
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
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
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
