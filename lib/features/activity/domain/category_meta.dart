import 'package:flutter/material.dart';

/// Single source of truth for category presentation metadata.
///
/// Used by [ReportPage], chart widgets, and category rows
/// to avoid duplicating color/emoji maps across multiple files.
class CategoryMeta {
  CategoryMeta._();

  // ── Category Colors ─────────────────────────────────────────────
  static const colors = <String, Color>{
    'Kerja': Color(0xFF5C6BC0),
    'Belajar': Color(0xFF42A5F5),
    'Olahraga': Color(0xFF66BB6A),
    'Hiburan': Color(0xFFAB47BC),
    'Keseharian': Color(0xFFFFA726),
    'Sosial': Color(0xFF26C6DA),
    'Ibadah': Color(0xFFEF5350),
    'Lainnya': Color(0xFF78909C),
  };

  static Color colorFor(String category) =>
      colors[category] ?? const Color(0xFF78909C);

  // ── Category Emojis ─────────────────────────────────────────────
  static const emojis = <String, String>{
    'Kerja': '🏢',
    'Belajar': '📚',
    'Olahraga': '🏃',
    'Hiburan': '🎮',
    'Keseharian': '🍽',
    'Sosial': '👥',
    'Ibadah': '🕌',
    'Lainnya': '📌',
  };

  static String emojiFor(String category) => emojis[category] ?? '📌';

  // ── Duration Formatting ─────────────────────────────────────────

  /// Short format for charts & tooltips: `2j 30m`, `45m`, `3j`
  static String formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}j';
    return '${h}j ${m}m';
  }

  /// Long format for stat cards & labels: `2 jam 30 mnt`, `45 mnt`, `3 jam`
  static String formatDurationLong(int minutes) {
    if (minutes < 60) return '$minutes mnt';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h jam';
    return '$h jam $m mnt';
  }
}
