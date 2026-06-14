import 'dart:convert';
import 'dart:io';

import 'package:catat_in/core/services/notification_service.dart';
import 'package:catat_in/features/activity/presentation/providers/activity_provider.dart';
import 'package:catat_in/features/activity/presentation/widgets/catat_in_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hive_flutter/hive_flutter.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late bool _dailyReminderEnabled;
  late TimeOfDay _reminderTime;

  @override
  void initState() {
    super.initState();
    _dailyReminderEnabled = Hive.box('settings').get('daily_reminder', defaultValue: false);
    final hour = Hive.box('settings').get('daily_reminder_hour', defaultValue: 20);
    final minute = Hive.box('settings').get('daily_reminder_minute', defaultValue: 0);
    _reminderTime = TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activities = ref.watch(activityListProvider);
    final box = ref.read(activityBoxProvider);

    return Scaffold(
      appBar: const CatatInAppBar(title: 'PENGATURAN'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengaturan Aplikasi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Atur tampilan, notifikasi, dan data aktivitas agar sesuai dengan gaya kerja Anda.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'Preferensi',
              children: [
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Tema',
                  subtitle: 'Mode terang / gelap',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tema akan mengikuti pengaturan sistem.')),
                    );
                  },
                ),
                _SettingsSwitchTile(
                  icon: Icons.alarm_rounded,
                  title: 'Reminder Harian',
                  subtitle: 'Aktifkan pengingat otomatis',
                  value: _dailyReminderEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _dailyReminderEnabled = value;
                    });
                    Hive.box('settings').put('daily_reminder', value);

                    if (value) {
                      await NotificationService.scheduleDailyReminder(_reminderTime.hour, _reminderTime.minute);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Reminder harian diaktifkan pada ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}.')),
                        );
                      }
                    } else {
                      await NotificationService.cancelDailyReminder();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reminder harian dinonaktifkan.')),
                        );
                      }
                    }
                  },
                ),
                if (_dailyReminderEnabled)
                  _SettingsTile(
                    icon: Icons.schedule_rounded,
                    title: 'Waktu Pengingat',
                    subtitle: 'Berbunyi setiap pukul ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime,
                      );
                      if (picked != null) {
                        setState(() {
                          _reminderTime = picked;
                        });
                        Hive.box('settings').put('daily_reminder_hour', picked.hour);
                        Hive.box('settings').put('daily_reminder_minute', picked.minute);
                        await NotificationService.scheduleDailyReminder(picked.hour, picked.minute);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Waktu pengingat diubah ke ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}.')),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'Data',
              children: [
                _SettingsTile(
                  icon: Icons.download_outlined,
                  title: 'Export Data',
                  subtitle: 'Ekspor aktivitas ke file',
                  onTap: () async {
                    final file = await _writeExportFile(activities, 'export');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export selesai: ${file.path}')),
                      );
                    }
                  },
                ),
                _SettingsTile(
                  icon: Icons.upload_outlined,
                  title: 'Backup Data',
                  subtitle: 'Cadangkan data aktivitas',
                  onTap: () async {
                    final file = await _writeExportFile(activities, 'backup');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Backup selesai: ${file.path}')),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'Lainnya',
              children: [
                _SettingsTile(
                  icon: Icons.feedback_outlined,
                  title: 'Kirim Feedback',
                  subtitle: 'Saran, masukan, atau lapor bug',
                  onTap: () async {
                    String? encodeQueryParameters(Map<String, String> params) {
                      return params.entries
                          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
                          .join('&');
                    }
                    
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'laputaa2429@gmail.com',
                      query: encodeQueryParameters(<String, String>{
                        'subject': '[Catat-In] Masukan & Saran',
                        'body': 'Halo developer Catat-In,\n\nSaya ingin menyampaikan feedback berikut:\n\n',
                      }),
                    );
                    
                    if (await canLaunchUrl(emailLaunchUri)) {
                      await launchUrl(emailLaunchUri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tidak dapat membuka aplikasi email.')),
                        );
                      }
                    }
                  },
                ),
                _DangerSettingsTile(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Reset Data?'),
                          content: const Text('Semua aktivitas akan dihapus.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Batal'),
                            ),
                            FilledButton(
                              onPressed: () async {
                                await box.clear();
                                ref.read(activityListProvider.notifier).loadActivities();
                                if (context.mounted) {
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Semua data aktivitas berhasil dihapus.')),
                                  );
                                }
                              },
                              child: const Text('Reset'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: const AboutListTile(
                    icon: Icon(Icons.info_outline),
                    applicationName: 'Catat-In',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Future<File> _writeExportFile(List<dynamic> activities, String kind) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final file = File('${directory.path}/catat_in_${kind}_$timestamp.json');

    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'count': activities.length,
      'activities': activities.map((activity) => {
        'name': activity.name,
        'isProductive': activity.isProductive,
        'timeValue': activity.timeValue,
        'tags': activity.tags,
        'createdAt': activity.createdAt.toIso8601String(),
        'category': activity.category,
        'startAt': activity.startAt?.toIso8601String(),
        'endAt': activity.endAt?.toIso8601String(),
        'isRunning': activity.isRunning,
      }).toList(),
    };

    await file.writeAsString(jsonEncode(payload));
    return file;
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _DangerSettingsTile extends StatelessWidget {
  const _DangerSettingsTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.red.withValues(alpha: 0.12),
          child: const Icon(Icons.delete_outline, color: Colors.red),
        ),
        title: const Text('Reset Semua Data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
        subtitle: const Text('Hapus semua data aktivitas yang tersimpan.'),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        secondary: CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}