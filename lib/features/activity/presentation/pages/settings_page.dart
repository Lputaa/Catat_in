import 'dart:convert';
import 'dart:io';

import 'package:catat_in/core/services/notification_service.dart';
import 'package:catat_in/features/activity/data/models/activity_model.dart';
import 'package:catat_in/features/activity/presentation/pages/template_page.dart';
import 'package:catat_in/features/activity/presentation/providers/activity_provider.dart';
import 'package:catat_in/features/activity/presentation/widgets/catat_in_app_bar.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
    _dailyReminderEnabled = Hive.box(
      'settings',
    ).get('daily_reminder', defaultValue: false);
    final hour = Hive.box(
      'settings',
    ).get('daily_reminder_hour', defaultValue: 20);
    final minute = Hive.box(
      'settings',
    ).get('daily_reminder_minute', defaultValue: 0);
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
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'Preferensi',
              children: [
                _SettingsTile(
                  icon: Icons.bolt_rounded,
                  title: 'Kelola Template',
                  subtitle: 'Buat dan atur template aktivitas',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TemplatePage()),
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
                      await NotificationService.scheduleDailyReminder(
                        _reminderTime.hour,
                        _reminderTime.minute,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Reminder harian diaktifkan pada ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}.',
                            ),
                          ),
                        );
                      }
                    } else {
                      await NotificationService.cancelDailyReminder();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reminder harian dinonaktifkan.'),
                          ),
                        );
                      }
                    }
                  },
                ),
                if (_dailyReminderEnabled)
                  _SettingsTile(
                    icon: Icons.schedule_rounded,
                    title: 'Waktu Pengingat',
                    subtitle:
                        'Berbunyi setiap pukul ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime,
                      );
                      if (picked != null) {
                        setState(() {
                          _reminderTime = picked;
                        });
                        Hive.box(
                          'settings',
                        ).put('daily_reminder_hour', picked.hour);
                        Hive.box(
                          'settings',
                        ).put('daily_reminder_minute', picked.minute);
                        await NotificationService.scheduleDailyReminder(
                          picked.hour,
                          picked.minute,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Waktu pengingat diubah ke ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}.',
                              ),
                            ),
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
                  subtitle: 'Ekspor aktivitas ke file (ICS, CSV, JSON)',
                  onTap: () => _showExportOptions(context, activities),
                ),

                _SettingsTile(
                  icon: Icons.file_download_outlined,
                  title: 'Import / Restore Data',
                  subtitle: 'Impor dari CSV, ICS, atau file Backup',
                  onTap: () => _importData(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'Dukungan',
              children: [
                _SettingsTile(
                  icon: Icons.favorite_rounded,
                  title: 'Donasi',
                  subtitle: 'Dukung pengembangan Catat-In',
                  onTap: () => _showDonationSheet(context),
                ),
                _SettingsTile(
                  icon: Icons.share_rounded,
                  title: 'Bagikan Aplikasi',
                  subtitle: 'Ajak temanmu pakai Catat-In',
                  onTap: () {
                    Share.share(
                      'Coba Catat-In — aplikasi pencatat waktu yang bikin kamu lebih produktif! 🚀\n\nhttps://play.google.com/store/apps/details?id=com.lputaa.catatin',
                    );
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
                          .map(
                            (e) =>
                                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
                          )
                          .join('&');
                    }

                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'laputaa2429@gmail.com',
                      query: encodeQueryParameters(<String, String>{
                        'subject': '[Catat-In] Masukan & Saran',
                        'body':
                            'Halo developer Catat-In,\n\nSaya ingin menyampaikan feedback berikut:\n\n',
                      }),
                    );

                    try {
                      await launchUrl(
                        emailLaunchUri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tidak dapat membuka aplikasi email.',
                            ),
                          ),
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
                                ref
                                    .read(activityListProvider.notifier)
                                    .loadActivities();
                                if (context.mounted) {
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Semua data aktivitas berhasil dihapus.',
                                      ),
                                    ),
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
                    applicationLegalese: 'Laputaa © 2026',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Checks if an activity with the same name and start time already exists.
  bool _isDuplicate(Box<ActivityModel> box, String name, DateTime? startAt) {
    for (var i = 0; i < box.length; i++) {
      final existing = box.getAt(i);
      if (existing == null) continue;
      if (existing.name == name && existing.startAt == startAt) {
        return true;
      }
    }
    return false;
  }

  void _showExportOptions(BuildContext context, List<dynamic> activities) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${activities.length} aktivitas akan diekspor',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _ExportOptionTile(
              icon: Icons.calendar_month_rounded,
              color: Colors.blue,
              title: 'ICS (Google Calendar)',
              subtitle:
                  'Format kalender — bisa diimpor ke Google Calendar, Outlook, dll',
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _writeICSFile(activities);
                if (context.mounted) {
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text: 'Aktivitas Catat-In (${activities.length} kegiatan)',
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            _ExportOptionTile(
              icon: Icons.table_chart_rounded,
              color: Colors.green,
              title: 'CSV (Spreadsheet)',
              subtitle:
                  'Format tabel — bisa dibuka di Excel, Google Sheets, dll',
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _writeCSVFile(activities);
                if (context.mounted) {
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text: 'Aktivitas Catat-In (${activities.length} kegiatan)',
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            _ExportOptionTile(
              icon: Icons.code_rounded,
              color: Colors.orange,
              title: 'JSON (Developer)',
              subtitle: 'Format data mentah — untuk backup atau integrasi API',
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _writeExportFile(activities, 'export');
                if (context.mounted) {
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text: 'Aktivitas Catat-In (${activities.length} kegiatan)',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<File> _writeExportFile(List<dynamic> activities, String kind) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${directory.path}/catat_in_${kind}_$timestamp.json');

    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'count': activities.length,
      'activities': activities
          .map(
            (activity) => {
              'name': activity.name,
              'isProductive': activity.isProductive,
              'timeValue': activity.timeValue,
              'createdAt': activity.createdAt.toIso8601String(),
              'category': activity.category,
              'startAt': activity.startAt?.toIso8601String(),
              'endAt': activity.endAt?.toIso8601String(),
              'isRunning': activity.isRunning,
              'notes': activity.notes,
              'templateName': activity.templateName,
            },
          )
          .toList(),
    };

    await file.writeAsString(jsonEncode(payload));
    return file;
  }

  /// Generates a CSV file compatible with Excel, Google Sheets, etc.
  Future<File> _writeCSVFile(List<dynamic> activities) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${directory.path}/catat_in_$timestamp.csv');

    String escapeCSV(String text) {
      if (text.contains(',') || text.contains('"') || text.contains('\n')) {
        return '"${text.replaceAll('"', '""')}"';
      }
      return text;
    }

    final buffer = StringBuffer();
    // Header
    buffer.writeln(
      'Nama,Kategori,Nilai Waktu,Mulai,Selesai,Durasi (menit),Catatan',
    );

    for (final activity in activities) {
      final startAt = activity.startAt as DateTime?;
      final endAt = activity.endAt as DateTime?;
      final duration = (startAt != null && endAt != null)
          ? endAt.difference(startAt).inMinutes
          : '';
      final notes = (activity.notes ?? '') as String;

      buffer.writeln(
        [
          escapeCSV(activity.name),
          escapeCSV(activity.category),
          escapeCSV(activity.timeValue),
          startAt?.toIso8601String() ?? '',
          endAt?.toIso8601String() ?? '',
          duration.toString(),
          escapeCSV(notes),
        ].join(','),
      );
    }

    await file.writeAsString(buffer.toString());
    return file;
  }

  /// Generates an ICS (iCalendar) file compatible with Google Calendar,
  /// Apple Calendar, Outlook, and other calendar apps.
  Future<File> _writeICSFile(List<dynamic> activities) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${directory.path}/catat_in_$timestamp.ics');

    String formatDt(DateTime dt) {
      // ICS format: YYYYMMDDTHHmmssZ (UTC)
      final utc = dt.toUtc();
      return '${utc.year.toString().padLeft(4, '0')}'
          '${utc.month.toString().padLeft(2, '0')}'
          '${utc.day.toString().padLeft(2, '0')}T'
          '${utc.hour.toString().padLeft(2, '0')}'
          '${utc.minute.toString().padLeft(2, '0')}'
          '${utc.second.toString().padLeft(2, '0')}Z';
    }

    String escapeICS(String text) {
      return text
          .replaceAll('\\', '\\\\')
          .replaceAll(';', '\\;')
          .replaceAll(',', '\\,')
          .replaceAll('\n', '\\n');
    }

    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//CatatIn//Activity Tracker//ID');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:Catat-In Activities');
    buffer.writeln('X-WR-TIMEZONE:Asia/Jakarta');

    for (final activity in activities) {
      final startAt = activity.startAt as DateTime?;
      final endAt = activity.endAt as DateTime?;
      if (startAt == null || endAt == null) continue;

      final uid =
          '${activity.createdAt.millisecondsSinceEpoch}'
          '${activity.name.hashCode}@catatin.app';
      final now = formatDt(DateTime.now());

      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:$uid');
      buffer.writeln('DTSTAMP:$now');
      buffer.writeln('DTSTART:${formatDt(startAt)}');
      buffer.writeln('DTEND:${formatDt(endAt)}');
      buffer.writeln('SUMMARY:${escapeICS(activity.name)}');
      buffer.writeln('CATEGORIES:${escapeICS(activity.category)}');

      final description = [
        'Category: ${activity.category}',
        'Time Value: ${activity.timeValue}',
        if (activity.notes != null && activity.notes.isNotEmpty)
          'Notes: ${activity.notes}',
      ].join('\\n');
      buffer.writeln('DESCRIPTION:$description');

      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');

    await file.writeAsString(buffer.toString());
    return file;
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'ics', 'json'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User canceled
      }

      final file = File(result.files.single.path!);
      final extension = result.files.single.extension?.toLowerCase();
      final content = await file.readAsString();

      int importedCount = 0;
      final box = ref.read(activityBoxProvider);

      if (extension == 'json') {
        final data = jsonDecode(content);
        final activitiesList = data['activities'] as List;
        for (final item in activitiesList) {
          // Duplicate check: skip if same name + startAt already exists
          final startAt = item['startAt'] != null
              ? DateTime.parse(item['startAt'])
              : null;
          final name = item['name'] as String;
          if (_isDuplicate(box, name, startAt)) continue;

          final activity = ActivityModel(
            name: name,
            createdAt: DateTime.parse(item['createdAt']),
            category: item['category'],
            startAt: startAt,
            endAt: item['endAt'] != null ? DateTime.parse(item['endAt']) : null,
            isRunning: item['isRunning'] ?? false,
            timeValue: item['timeValue'],
            notes: item['notes'],
            templateName: item['templateName'],
          );
          await box.add(activity);
          importedCount++;
        }
      } else if (extension == 'csv') {
        final List<List<dynamic>> rowsAsListOfValues =
            const CsvToListConverter().convert(content);
        if (rowsAsListOfValues.isNotEmpty) {
          for (int i = 1; i < rowsAsListOfValues.length; i++) {
            final row = rowsAsListOfValues[i];
            if (row.length >= 5) {
              final name = row[0].toString();
              final category = row[1].toString();
              final timeValue = row[2].toString();
              final startAtStr = row[3].toString();
              final endAtStr = row[4].toString();
              final notes = row.length > 6 ? row[6].toString() : '';

              final parsedStart = startAtStr.isNotEmpty
                  ? DateTime.tryParse(startAtStr)
                  : null;

              // Duplicate check
              if (_isDuplicate(box, name, parsedStart)) continue;

              final activity = ActivityModel(
                name: name,
                createdAt: parsedStart ?? DateTime.now(),
                category: category,
                timeValue: timeValue.isNotEmpty ? timeValue : 'kebutuhan',
                startAt: parsedStart,
                endAt: endAtStr.isNotEmpty ? DateTime.tryParse(endAtStr) : null,
                notes: notes.isNotEmpty ? notes : null,
              );
              await box.add(activity);
              importedCount++;
            }
          }
        }
      } else if (extension == 'ics') {
        // Normalize line endings (ICS files may use \r\n from Windows/Outlook)
        final normalizedContent = content
            .replaceAll('\r\n', '\n')
            .replaceAll('\r', '\n');
        final lines = normalizedContent.split('\n');
        String? currentSummary;
        String? currentCategory;
        DateTime? currentStart;
        DateTime? currentEnd;
        String? currentDescription;

        for (String line in lines) {
          line = line.trim();
          if (line == 'BEGIN:VEVENT') {
            currentSummary = null;
            currentCategory = 'Lainnya';
            currentStart = null;
            currentEnd = null;
            currentDescription = null;
          } else if (line.startsWith('SUMMARY:')) {
            currentSummary = line
                .substring(8)
                .replaceAll('\\,', ',')
                .replaceAll('\\;', ';');
          } else if (line.startsWith('CATEGORIES:')) {
            currentCategory = line.substring(11);
          } else if (line.startsWith('DTSTART:')) {
            final dtStr = line.substring(8);
            if (dtStr.length >= 15) {
              final formatted =
                  '${dtStr.substring(0, 4)}-${dtStr.substring(4, 6)}-${dtStr.substring(6, 8)}T${dtStr.substring(9, 11)}:${dtStr.substring(11, 13)}:${dtStr.substring(13, 15)}Z';
              currentStart = DateTime.tryParse(formatted)?.toLocal();
            }
          } else if (line.startsWith('DTEND:')) {
            final dtStr = line.substring(6);
            if (dtStr.length >= 15) {
              final formatted =
                  '${dtStr.substring(0, 4)}-${dtStr.substring(4, 6)}-${dtStr.substring(6, 8)}T${dtStr.substring(9, 11)}:${dtStr.substring(11, 13)}:${dtStr.substring(13, 15)}Z';
              currentEnd = DateTime.tryParse(formatted)?.toLocal();
            }
          } else if (line.startsWith('DESCRIPTION:')) {
            currentDescription = line.substring(12).replaceAll('\\n', '\n');
          } else if (line == 'END:VEVENT') {
            if (currentSummary != null) {
              String timeValue = 'kebutuhan';
              String notes = '';
              if (currentDescription != null) {
                final descLines = currentDescription.split('\n');
                for (final descLine in descLines) {
                  if (descLine.startsWith('Time Value: ')) {
                    timeValue = descLine.substring(12);
                  } else if (descLine.startsWith('Notes: ')) {
                    notes = descLine.substring(7);
                  }
                }
              }
              // Duplicate check
              if (_isDuplicate(box, currentSummary, currentStart)) continue;

              final activity = ActivityModel(
                name: currentSummary,
                createdAt: currentStart ?? DateTime.now(),
                category: currentCategory ?? 'Lainnya',
                startAt: currentStart,
                endAt: currentEnd,
                timeValue: timeValue,
                notes: notes.isNotEmpty ? notes : null,
              );
              await box.add(activity);
              importedCount++;
            }
          }
        }
      }

      ref.read(activityListProvider.notifier).loadActivities();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengimpor $importedCount aktivitas'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengimpor file: $e')));
      }
    }
  }

  void _showDonationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dukung Pengembangan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Aplikasi ini dibuat gratis dan tanpa iklan. Dukungan Anda sangat berarti untuk server dan pengembangan fitur selanjutnya.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _ExportOptionTile(
              icon: Icons.coffee_rounded,
              color: Colors.orange,
              title: 'Trakteer',
              subtitle: 'Dukung kreator dengan mentraktir',
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('https://trakteer.id/');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
            const SizedBox(height: 8),
            _ExportOptionTile(
              icon: Icons.favorite_rounded,
              color: Colors.pink,
              title: 'Saweria',
              subtitle: 'Dukungan via dompet digital',
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('https://saweria.co/');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
            const SizedBox(height: 8),
            _ExportOptionTile(
              icon: Icons.local_cafe_rounded,
              color: Colors.blue,
              title: 'Ko-fi',
              subtitle: 'Buy me a coffee',
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('https://ko-fi.com/');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
          ],
        ),
      ),
    );
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
        title: const Text(
          'Reset Semua Data',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
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

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
