import 'package:catat_in/core/navigation/main_navigation_page.dart';
import 'package:catat_in/core/navigation/onboarding_page.dart';
import 'package:catat_in/core/services/notification_service.dart';
import 'package:catat_in/core/services/widget_service.dart';
import 'package:catat_in/core/theme/app_theme.dart';
import 'package:catat_in/features/activity/data/models/activity_model.dart';
import 'package:catat_in/features/activity/data/models/activity_template_model.dart';
import 'package:catat_in/features/activity/presentation/providers/activity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HomeWidget.registerInteractivityCallback(widgetCallback);

  await Hive.initFlutter();

  Hive.registerAdapter(ActivityModelAdapter());
  Hive.registerAdapter(ActivityTemplateModelAdapter());

  await Hive.openBox<ActivityModel>('activities');
  await Hive.openBox<ActivityTemplateModel>('templates');
  await Hive.openBox('settings');

  await NotificationService.init();

  await WidgetService.updateFromFlutter();

  runApp(
    const ProviderScope(
      child: CatatInApp(),
    ),
  );
}

class CatatInApp extends ConsumerStatefulWidget {
  const CatatInApp({super.key});

  @override
  ConsumerState<CatatInApp> createState() => _CatatInAppState();
}

class _CatatInAppState extends ConsumerState<CatatInApp> {
  late bool _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _onboardingComplete =
        Hive.box('settings').get('onboarding_complete', defaultValue: false)
            as bool;
    // Auto-sync widget whenever activity list changes
    ref.listenManual(activityListProvider, (previous, next) {
      WidgetService.updateFromFlutter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catat-In',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: _onboardingComplete
          ? const MainNavigationPage()
          : OnboardingPage(
              onComplete: () {
                setState(() => _onboardingComplete = true);
              },
            ),
    );
  }
}