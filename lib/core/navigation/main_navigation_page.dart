import 'package:catat_in/features/activity/presentation/pages/calendar_page.dart';
import 'package:catat_in/features/activity/presentation/pages/log_page.dart';
import 'package:catat_in/features/activity/presentation/pages/report_page.dart';
import 'package:catat_in/features/activity/presentation/pages/settings_page.dart';
import 'package:catat_in/features/activity/presentation/pages/today_page.dart';
import 'package:catat_in/features/activity/presentation/providers/activity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() =>
      _MainNavigationPageState();
}

class _MainNavigationPageState
    extends ConsumerState<MainNavigationPage> {

  int currentIndex = 0;

  final List<Widget> pages = const [
    TodayPage(),
    CalendarPage(),
    ReportPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _handleWidgetLaunch();
  }

  /// Handles both cold-start and hot-start deep links from the widget.
  Future<void> _handleWidgetLaunch() async {
    // Cold start: app launched from widget
    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (initialUri != null) {
      _navigateFromWidget(initialUri);
    }

    // Hot start: app already running, user tapped widget
    HomeWidget.widgetClicked.listen(_navigateFromWidget);
  }

  void _navigateFromWidget(Uri? uri) {
    if (uri == null || !mounted) return;
    final action = uri.host;

    if (action == 'start') {
      // Open tracking form
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LogPage()),
      );
    } else if (action == 'stop') {
      // Open tracking form to finish running activity
      final notifier = ref.read(activityListProvider.notifier);
      final running = notifier.getRunningActivity();
      if (running != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LogPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Catat'),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Hari Ini',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Rapor',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
