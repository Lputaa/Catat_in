import 'package:catat_in/features/activity/data/models/activity_model.dart';
import 'package:catat_in/features/activity/data/models/activity_template_model.dart';
import 'package:catat_in/features/activity/domain/time_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final activityBoxProvider = Provider<Box<ActivityModel>>((ref) {
  return Hive.box<ActivityModel>('activities');
});

final activityListProvider =
    StateNotifierProvider<ActivityNotifier, List<ActivityModel>>((ref) {
      final box = ref.watch(activityBoxProvider);

      return ActivityNotifier(box);
    });

class ActivityNotifier extends StateNotifier<List<ActivityModel>> {
  /// Temporarily holds the last deleted activity for undo support.
  ActivityModel? _lastDeletedActivity;

  ActivityModel? getRunningActivity() {
    try {
      return state.firstWhere((activity) => activity.isRunning);
    } catch (_) {
      return null;
    }
  }

  Future<void> startActivity({
    String? name,
    String category = 'Lainnya',
    String? templateName,
    String? timeValue,
  }) async {
    final running = getRunningActivity();

    if (running != null) {
      return;
    }

    final normalizedName = (name ?? '').trim();

    final activityName = normalizedName.isEmpty
        ? 'Aktivitas tanpa judul'
        : normalizedName;

    final activity = ActivityModel(
      name: activityName,
      category: category,
      createdAt: DateTime.now(),
      startAt: DateTime.now(),
      endAt: null,
      isRunning: true,
      timeValue: timeValue ?? TimeValue.kebutuhan.name,
      templateName: templateName,
    );

    await box.add(activity);

    loadActivities();
  }

  /// Start tracking from a template — all fields pre-filled, auto-save on stop.
  Future<void> startFromTemplate(ActivityTemplateModel template) async {
    await startActivity(
      name: template.name,
      category: template.category,
      templateName: template.name,
      timeValue: template.timeValue,
    );
  }

  Future<void> finishRunningActivity({
    TimeValue timeValue = TimeValue.kebutuhan,
    String? category,
    String? name,
    String notes = '',
  }) async {
    final running = getRunningActivity();

    if (running == null) {
      return;
    }

    final finished = ActivityModel(
      name: (name != null && name.trim().isNotEmpty) ? name.trim() : running.name,
      createdAt: running.createdAt,
      category: category ?? running.category,
      startAt: running.startAt,
      endAt: DateTime.now(),
      isRunning: false,
      notes: notes,
      timeValue: timeValue.name,
      templateName: running.templateName,
    );

    await box.put(running.key, finished);

    loadActivities();
  }

  Duration getActivityDuration(ActivityModel activity) {
    if (activity.startAt == null) {
      return Duration.zero;
    }

    final end = activity.endAt ?? DateTime.now();

    return end.difference(activity.startAt!);
  }

  Future<void> stopActivity() async {
    final running = getRunningActivity();

    if (running == null) {
      return;
    }

    final finished = ActivityModel(
      name: running.name,
      createdAt: running.createdAt,
      category: running.category,
      startAt: running.startAt,
      endAt: DateTime.now(),
      isRunning: false,
      notes: running.notes,
      timeValue: running.timeValue,
      templateName: running.templateName,
    );

    await box.put(running.key, finished);

    loadActivities();
  }

  final Box<ActivityModel> box;

  ActivityNotifier(this.box) : super([]) {
    loadActivities();
  }

  void loadActivities() {
    debugPrint('LOAD DATA: ${box.length}');

    final activities = <ActivityModel>[];
    for (var i = 0; i < box.length; i++) {
      try {
        final activity = box.getAt(i);
        if (activity != null) activities.add(activity);
      } catch (e) {
        debugPrint('Skipping corrupt entry at index $i: $e');
      }
    }
    state = activities.reversed.toList();
  }

  Future<void> addActivity(ActivityModel activity) async {
    await box.add(activity);

    debugPrint('TOTAL DATA: ${box.length}');

    loadActivities();
  }

  Future<void> updateActivity(
    ActivityModel activity, {
    String? name,
    String? category,
    DateTime? startAt,
    DateTime? endAt,
    bool? isRunning,
    String? notes,
    String? timeValue,
  }) async {
    final updated = ActivityModel(
      name: name ?? activity.name,
      createdAt: activity.createdAt,
      category: category ?? activity.category,
      startAt: startAt ?? activity.startAt,
      endAt: endAt ?? activity.endAt,
      isRunning: isRunning ?? activity.isRunning,
      notes: notes ?? activity.notes,
      timeValue: timeValue ?? activity.timeValue,
      templateName: activity.templateName,
    );

    await box.put(activity.key, updated);

    loadActivities();
  }

  Future<void> addManualActivity({
    required String name,
    required DateTime startAt,
    required DateTime endAt,
    required String category,
    TimeValue timeValue = TimeValue.kebutuhan,
    String notes = '',
  }) async {
    final activity = ActivityModel(
      name: name,
      createdAt: startAt,
      category: category,
      startAt: startAt,
      endAt: endAt,
      isRunning: false,
      notes: notes,
      timeValue: timeValue.name,
    );

    await box.add(activity);
    loadActivities();
  }

  Future<void> deleteActivity(ActivityModel activity) async {
    // Store a copy for undo before deleting
    _lastDeletedActivity = ActivityModel(
      name: activity.name,
      createdAt: activity.createdAt,
      category: activity.category,
      startAt: activity.startAt,
      endAt: activity.endAt,
      isRunning: activity.isRunning,
      notes: activity.notes,
      timeValue: activity.timeValue,
      templateName: activity.templateName,
    );

    await activity.delete();
    loadActivities();
  }

  /// Restores the last deleted activity. Returns true if successful.
  Future<bool> undoDelete() async {
    if (_lastDeletedActivity == null) return false;

    await box.add(_lastDeletedActivity!);
    _lastDeletedActivity = null;
    loadActivities();
    return true;
  }
}
