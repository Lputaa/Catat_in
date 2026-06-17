import 'package:flutter/material.dart';

class RunningBanner extends StatelessWidget {
  final dynamic activity;
  final VoidCallback onStop;

  const RunningBanner({
    super.key,
    required this.activity,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final isTemplate = activity.templateName != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                label: Text(isTemplate ? 'Selesai' : 'Detail'),
              ),
            ],
          ),
          if (isTemplate) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.bolt_rounded,
                    size: 14, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Template · Ketuk "Selesai" untuk langsung simpan',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
