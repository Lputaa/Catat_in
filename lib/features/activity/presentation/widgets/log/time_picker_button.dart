import 'package:flutter/material.dart';

class TimePickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? time;
  final VoidCallback onTap;

  const TimePickerButton({
    super.key,
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
                  Text(label,
                      style: TextStyle(
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
