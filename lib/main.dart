import 'package:catat_in/core/services/notification_service.dart';
import 'package:catat_in/core/theme/app_theme.dart';
import 'package:catat_in/features/activity/data/models/activity_model.dart';
import 'package:catat_in/features/activity/presentation/pages/calendar_page.dart';
import 'package:catat_in/features/activity/presentation/pages/log_page.dart';
import 'package:catat_in/features/activity/presentation/pages/report_page.dart';
import 'package:catat_in/features/activity/presentation/pages/settings_page.dart';
import 'package:catat_in/features/activity/presentation/pages/today_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(ActivityModelAdapter());

  await Hive.openBox<ActivityModel>('activities');
  await Hive.openBox('settings');

  await NotificationService.init();

  runApp(
    const ProviderScope(
      child: CatatInApp(),
    ),
  );
}

class CatatInApp extends StatelessWidget {
  const CatatInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catat-In',
      debugShowCheckedModeBanner: false,

    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.system,

      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() =>
      _MainNavigationPageState();
}

class _MainNavigationPageState
    extends State<MainNavigationPage> {

  int currentIndex = 0;

  final List<Widget> pages = const [

    TodayPage(),

    CalendarPage(),

    ReportPage(),

    SettingsPage(),
  ];

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),

      floatingActionButton:
          FloatingActionButton.extended(

        onPressed: () {

          Navigator.push(
            context,

            MaterialPageRoute(
              builder:
                  (_) =>
                      const LogPage(),
            ),
          );
        },

        icon: const Icon(
          Icons.add,
        ),

        label: const Text(
          'Catat',
        ),
      ),

      bottomNavigationBar:
          NavigationBar(

        height: 72,

        selectedIndex:
            currentIndex,

        onDestinationSelected:
            (index) {

          setState(() {

            currentIndex =
                index;
          });
        },

        destinations: const [

          NavigationDestination(
            icon:
                Icon(
              Icons.today_outlined,
            ),

            selectedIcon:
                Icon(
              Icons.today,
            ),

            label:
                'Hari Ini',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons.calendar_month_outlined,
            ),

            selectedIcon:
                Icon(
              Icons.calendar_month,
            ),

            label:
                'Kalender',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons.assessment_outlined,
            ),

            selectedIcon:
                Icon(
              Icons.assessment,
            ),

            label:
                'Rapor',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons.settings_outlined,
            ),

            selectedIcon:
                Icon(
              Icons.settings,
            ),

            label:
                'Pengaturan',
          ),
        ],
      ),
    );
  }
}