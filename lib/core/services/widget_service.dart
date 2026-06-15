import 'package:hive/hive.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/activity/data/models/activity_model.dart';

/// Syncs tracking state from Hive to the Android home screen widget.
class WidgetService {
  /// Call this whenever activity data changes to keep the widget in sync.
  static Future<void> updateFromFlutter() async {
    try {
      final box = Hive.isBoxOpen('activities')
          ? Hive.box<ActivityModel>('activities')
          : null;

      if (box == null) {
        await _saveIdleState();
        return;
      }

      ActivityModel? running;
      for (var i = 0; i < box.length; i++) {
        final activity = box.getAt(i);
        if (activity != null && activity.isRunning) {
          running = activity;
          break;
        }
      }

      if (running != null) {
        await HomeWidget.saveWidgetData<bool>('is_tracking', true);
        await HomeWidget.saveWidgetData<String>('activity_name', running.name);
        await HomeWidget.saveWidgetData<String>(
          'activity_category',
          running.category,
        );
        await HomeWidget.saveWidgetData<int>(
          'start_millis',
          running.startAt!.millisecondsSinceEpoch,
        );
      } else {
        await _saveIdleState();
      }

      await HomeWidget.updateWidget(
        androidName: 'TrackingWidgetProvider',
      );
    } catch (_) {
      // Silently fail — widget update is non-critical
    }
  }

  static Future<void> _saveIdleState() async {
    await HomeWidget.saveWidgetData<bool>('is_tracking', false);
    await HomeWidget.saveWidgetData<String>('activity_name', '');
    await HomeWidget.saveWidgetData<String>('activity_category', '');
    await HomeWidget.saveWidgetData<int>('start_millis', 0);
  }
}

/// Background callback from the native widget (runs in a separate isolate).
@pragma('vm:entry-point')
Future<void> widgetCallback(Uri? uri) async {
  if (uri == null) return;

  // Must re-init Hive in this isolate
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ActivityModelAdapter());
  }
  if (!Hive.isBoxOpen('activities')) {
    await Hive.openBox<ActivityModel>('activities');
  }

  final action = uri.host; // 'start' or 'stop'
  final box = Hive.box<ActivityModel>('activities');

  if (action == 'start') {
    final hasRunning = box.values.any((a) => a.isRunning);
    if (!hasRunning) {
      final activity = ActivityModel(
        name: 'Aktivitas tanpa judul',
        category: 'Lainnya',
        createdAt: DateTime.now(),
        startAt: DateTime.now(),
        endAt: null,
        isRunning: true,
        timeValue: 'kebutuhan',
      );
      await box.add(activity);
    }
  } else if (action == 'stop') {
    ActivityModel? running;
    dynamic runningKey;
    for (var i = 0; i < box.length; i++) {
      final activity = box.getAt(i);
      if (activity != null && activity.isRunning) {
        running = activity;
        runningKey = box.keyAt(i);
        break;
      }
    }
    if (running != null && runningKey != null) {
      final finished = ActivityModel(
        name: running.name,
        createdAt: running.createdAt,
        category: running.category,
        startAt: running.startAt,
        endAt: DateTime.now(),
        isRunning: false,
        notes: running.notes,
        timeValue: running.timeValue,
      );
      await box.put(runningKey, finished);
    }
  }

  await WidgetService.updateFromFlutter();
}
