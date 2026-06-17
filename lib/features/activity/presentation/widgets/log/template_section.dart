import 'package:catat_in/features/activity/data/models/activity_template_model.dart';
import 'package:catat_in/features/activity/domain/time_value.dart';
import 'package:catat_in/features/activity/presentation/providers/activity_provider.dart';
import 'package:catat_in/features/activity/presentation/providers/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:catat_in/features/activity/presentation/pages/template_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TemplateQuickStartSection extends ConsumerWidget {
  const TemplateQuickStartSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templateListProvider);
    if (templates.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.bolt_rounded,
                  size: 16, color: theme.colorScheme.secondary),
            ),
            const SizedBox(width: 10),
            const Text('Mulai Cepat',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
            itemCount: templates.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Tambah', style: TextStyle(fontSize: 13)),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TemplatePage(),
                      ),
                    );
                  },
                );
              }
              
              final t = templates[i - 1];
              final tv = TimeValue.fromString(t.timeValue);
              return ActionChip(
                avatar:
                    Text(t.emoji, style: const TextStyle(fontSize: 16)),
                label: Text(t.name, style: const TextStyle(fontSize: 13)),
                backgroundColor: tv.color.withValues(alpha: 0.08),
                side: BorderSide(color: tv.color.withValues(alpha: 0.25)),
                onPressed: () => _confirmAndStart(context, ref, t),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmAndStart(
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
              width: 64,
              height: 64,
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
                      ref
                          .read(activityListProvider.notifier)
                          .startFromTemplate(t);
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
}
