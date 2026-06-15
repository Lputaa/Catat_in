import 'package:catat_in/features/activity/data/models/activity_template_model.dart';
import 'package:catat_in/features/activity/domain/activity_category.dart';
import 'package:catat_in/features/activity/domain/time_value.dart';
import 'package:catat_in/features/activity/presentation/providers/template_provider.dart';
import 'package:catat_in/features/activity/presentation/widgets/catat_in_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TemplatePage extends ConsumerWidget {
  const TemplatePage({super.key});

  static const _emojiOptions = [
    '💻', '📋', '📧', '📖', '🎓', '🏃', '🏋️', '🍽', '🚗', '🕌',
    '🎮', '🎵', '📝', '🧘', '🛒', '👥', '🎬', '☕', '🏊', '🚴',
    '📱', '🔧', '💪', '🎨', '📞', '🧹', '💤', '🍳', '✈️', '🎯',
    '🏛', '🗣', '📊', '🖥', '🎸', '⚽', '🧠', '💡', '📦', '🛠',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templateListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CatatInAppBar(title: 'TEMPLATE'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemplateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Template Baru'),
      ),
      body: templates.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Belum ada template',
                      style: TextStyle(fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('Buat template untuk mulai tracking lebih cepat',
                      style: TextStyle(fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final t = templates[index];
                return _TemplateCard(
                  template: t,
                  onTap: () => _showTemplateSheet(context, ref, template: t),
                  onDelete: t.isDefault
                      ? null
                      : () => ref.read(templateListProvider.notifier)
                          .deleteTemplate(t),
                );
              },
            ),
    );
  }

  void _showTemplateSheet(
    BuildContext context,
    WidgetRef ref, {
    ActivityTemplateModel? template,
  }) {
    final isEdit = template != null;
    final nameController = TextEditingController(text: template?.name ?? '');
    var selectedEmoji = template?.emoji ?? '📌';
    var selectedCategory = ActivityCategory.values.firstWhere(
      (c) => c.label == (template?.category ?? 'Lainnya'),
      orElse: () => ActivityCategory.lainnya,
    );
    var selectedTimeValue = TimeValue.fromString(template?.timeValue ?? 'kebutuhan');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEdit ? 'Edit Template' : 'Template Baru',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // ── Emoji picker ──
                    Text('Emoji', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: _emojiOptions.map((e) {
                        final sel = selectedEmoji == e;
                        return GestureDetector(
                          onTap: () => setSheet(() => selectedEmoji = e),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: sel
                                  ? Theme.of(sheetCtx).colorScheme.primaryContainer
                                  : Theme.of(sheetCtx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10),
                              border: sel ? Border.all(
                                  color: Theme.of(sheetCtx).colorScheme.primary, width: 2) : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(e, style: const TextStyle(fontSize: 20)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── Name ──
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama template',
                        hintText: 'Contoh: Deep Work',
                        prefixIcon: const Icon(Icons.label_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Category ──
                    DropdownButtonFormField<ActivityCategory>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        prefixIcon: const Icon(Icons.category_rounded),
                      ),
                      items: ActivityCategory.values
                          .map((c) => DropdownMenuItem(value: c, child: Text('${c.emoji}  ${c.label}')))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSheet(() => selectedCategory = v);
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Time Value ──
                    Text('Nilai Waktu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: TimeValue.values.map((tv) {
                        final sel = selectedTimeValue == tv;
                        return ChoiceChip(
                          label: Text('${tv.emoji} ${tv.shortLabel}',
                              style: const TextStyle(fontSize: 12)),
                          selected: sel,
                          selectedColor: tv.color.withValues(alpha: 0.25),
                          onSelected: (v) {
                            if (v) setSheet(() => selectedTimeValue = tv);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ── Save button ──
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Masukkan nama template.')),
                            );
                            return;
                          }
                          final notifier = ref.read(templateListProvider.notifier);
                          if (isEdit) {
                            notifier.updateTemplate(
                              template,
                              name: name,
                              emoji: selectedEmoji,
                              category: selectedCategory.label,
                              timeValue: selectedTimeValue.name,
                            );
                          } else {
                            notifier.addTemplate(
                              name: name,
                              emoji: selectedEmoji,
                              category: selectedCategory.label,
                              timeValue: selectedTimeValue.name,
                            );
                          }
                          Navigator.of(sheetCtx).pop();
                        },
                        icon: const Icon(Icons.save_rounded),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(isEdit ? 'Simpan Perubahan' : 'Buat Template'),
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
}

class _TemplateCard extends StatelessWidget {
  final ActivityTemplateModel template;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tv = TimeValue.fromString(template.timeValue);

    // Resolve category emoji
    final catEnum = ActivityCategory.values.firstWhere(
      (c) => c.label == template.category,
      orElse: () => ActivityCategory.lainnya,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // ── Left accent strip ──
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: tv.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  // ── Content ──
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // Emoji container
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: tv.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: tv.color.withValues(alpha: 0.20),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(template.emoji,
                                style: const TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 14),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(template.name,
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('${catEnum.emoji} ${template.category}',
                                        style: TextStyle(fontSize: 12,
                                            color: theme.colorScheme.onSurfaceVariant)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: tv.color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tv.shortLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: tv.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Lock or delete
                          if (template.isDefault)
                            Icon(Icons.lock_outline_rounded, size: 18,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35))
                          else if (onDelete != null)
                            IconButton(
                              onPressed: onDelete,
                              icon: Icon(Icons.delete_outline_rounded, size: 20,
                                  color: theme.colorScheme.error.withValues(alpha: 0.7)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

