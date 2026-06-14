import 'package:catat_in/features/activity/data/models/activity_model.dart';

class ActivityUtils {

static int calculateMinutes(
  String time,
) {

  if (time.isEmpty) {
    return 0;
  }

  final parts = time.split(':');

  if (parts.length < 2) {
    return 0;
  }

  final hour =
      int.tryParse(parts[0]) ?? 0;

  final minute =
      int.tryParse(
            parts[1].split(' ')[0],
          ) ??
          0;

  return hour * 60 + minute;
}

  static int getDuration(
    String start,
    String end,
  ) {

    final startMinutes =
        calculateMinutes(start);

    final endMinutes =
        calculateMinutes(end);

    return endMinutes - startMinutes;
  }

  static String formatDuration(
    int minutes,
  ) {

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) {
      return '$mins m';
    }

    return '$hours j $mins m';
  }

  static int calculateStreak(
    List<ActivityModel> activities,
  ) {

    if (activities.isEmpty) {
      return 0;
    }

    final uniqueDates =
        activities
            .map(
              (e) =>
                  e.createdAt
                      .toString()
                      .split(' ')[0],
            )
            .toSet()
            .toList();

    uniqueDates.sort(
      (a, b) => b.compareTo(a),
    );

    int streak = 0;

    DateTime current =
        DateTime.now();

    for (final date in uniqueDates) {

      final currentDate =
          current
              .toString()
              .split(' ')[0];

      if (date == currentDate) {

        streak++;

        current = current.subtract(
          const Duration(days: 1),
        );
      } else {

        break;
      }
    }

    return streak;
  }
}