import 'package:catat_in/features/activity/data/models/activity_model.dart';

// ─── Shared utility ───────────────────────────────────────────────────────────
String formatHM(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

// ─── Timeline entry sealed class (type-safe union) ────────────────────────────
sealed class TimelineEntry {
  const TimelineEntry();
}

class ActivityEntry extends TimelineEntry {
  final ActivityModel activity;
  const ActivityEntry(this.activity);
}

class UntrackedEntry extends TimelineEntry {
  final DateTime start;
  final DateTime end;
  final int minutes;
  const UntrackedEntry({
    required this.start,
    required this.end,
    required this.minutes,
  });
}

class NowMarkerEntry extends TimelineEntry {
  const NowMarkerEntry();
}

// ─── Timeline builder logic (extracted for testability) ───────────────────────
List<TimelineEntry> buildTimelineEntries({
  required List<ActivityModel> todayActivities,
  required ActivityModel? runningActivity,
  required DateTime now,
}) {
  final entries = <TimelineEntry>[];
  if (todayActivities.isEmpty) return entries;

  final first = todayActivities.first;
  final last = todayActivities.last;
  final firstStart = first.startAt ?? first.createdAt;
  final lastEnd = last.endAt;

  // Untracked time from midnight to first activity
  final midnight = DateTime(now.year, now.month, now.day);
  final minutesBeforeFirst =
      firstStart.difference(midnight).inMinutes.clamp(0, 1440);
  if (minutesBeforeFirst >= 15) {
    entries.add(UntrackedEntry(
      start: midnight,
      end: firstStart,
      minutes: minutesBeforeFirst,
    ));
  }

  // Activities with gaps between them
  for (int i = 0; i < todayActivities.length; i++) {
    entries.add(ActivityEntry(todayActivities[i]));

    if (i < todayActivities.length - 1) {
      final current = todayActivities[i];
      final next = todayActivities[i + 1];
      if (current.endAt != null && next.startAt != null) {
        final gapMin = next.startAt!.difference(current.endAt!).inMinutes;
        // Only show gap if positive and >= 15 minutes (skip overlaps)
        if (gapMin >= 15) {
          entries.add(UntrackedEntry(
            start: current.endAt!,
            end: next.startAt!,
            minutes: gapMin,
          ));
        }
      }
    }
  }

  // "Now" marker or untracked time after last activity
  if (runningActivity != null) {
    entries.add(const NowMarkerEntry());
  } else if (lastEnd != null) {
    final minutesAfterLast = now.difference(lastEnd).inMinutes;
    if (minutesAfterLast >= 15) {
      entries.add(UntrackedEntry(
        start: lastEnd,
        end: now,
        minutes: minutesAfterLast,
      ));
    }
  }

  return entries;
}
