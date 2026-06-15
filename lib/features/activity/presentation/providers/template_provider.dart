import 'package:catat_in/features/activity/data/models/activity_template_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final templateBoxProvider = Provider<Box<ActivityTemplateModel>>((ref) {
  return Hive.box<ActivityTemplateModel>('templates');
});

final templateListProvider =
    StateNotifierProvider<TemplateNotifier, List<ActivityTemplateModel>>((ref) {
  final box = ref.watch(templateBoxProvider);
  return TemplateNotifier(box);
});

class TemplateNotifier extends StateNotifier<List<ActivityTemplateModel>> {
  final Box<ActivityTemplateModel> box;
  static const _defaultsVersionKey = 'template_defaults_version';
  static const _currentVersion = 2;

  TemplateNotifier(this.box) : super([]) {
    _migrateDefaults();
    loadTemplates();
  }

  static final _defaultTemplates = [
    ActivityTemplateModel(
      name: 'Coding',
      emoji: '💻',
      category: 'Kerja',
      timeValue: 'investasi',
      isDefault: true,
    ),
    ActivityTemplateModel(
      name: 'Meeting',
      emoji: '📋',
      category: 'Kerja',
      timeValue: 'kebutuhan',
      isDefault: true,
    ),
    ActivityTemplateModel(
      name: 'Gawe',
      emoji: '🔧',
      category: 'Kerja',
      timeValue: 'produktif',
      isDefault: true,
    ),
    ActivityTemplateModel(
      name: 'Membaca',
      emoji: '📖',
      category: 'Belajar',
      timeValue: 'investasi',
      isDefault: true,
    ),
    ActivityTemplateModel(
      name: 'Kuliah',
      emoji: '🎓',
      category: 'Belajar',
      timeValue: 'investasi',
      isDefault: true,
    ),
    ActivityTemplateModel(
      name: 'Lari',
      emoji: '🏃',
      category: 'Olahraga',
      timeValue: 'produktif',
      isDefault: true,
    ),
    ActivityTemplateModel(
      name: 'Makan',
      emoji: '🍽',
      category: 'Keseharian',
      timeValue: 'kebutuhan',
      isDefault: true,
    ),
    ActivityTemplateModel(
      name: 'Perjalanan',
      emoji: '🚗',
      category: 'Keseharian',
      timeValue: 'kebutuhan',
      isDefault: true,
    ),
    ActivityTemplateModel(
      name: 'Kerkom',
      emoji: '👥',
      category: 'Sosial',
      timeValue: 'kebutuhan',
      isDefault: true,
    ),
    ActivityTemplateModel(
      name: 'Organisasi',
      emoji: '🏛',
      category: 'Sosial',
      timeValue: 'investasi',
      isDefault: true,
    ),
    ActivityTemplateModel(
      name: 'Sholat',
      emoji: '🕌',
      category: 'Ibadah',
      timeValue: 'investasi',
      isDefault: true,
    ),
  ];

  /// Seeds defaults on first launch, or migrates when version changes.
  void _migrateDefaults() {
    final settingsBox = Hive.box('settings');
    final storedVersion = settingsBox.get(_defaultsVersionKey, defaultValue: 0) as int;

    if (box.isEmpty) {
      for (final t in _defaultTemplates) {
        box.add(t);
      }
      settingsBox.put(_defaultsVersionKey, _currentVersion);
      return;
    }

    if (storedVersion >= _currentVersion) return;

    // Remove stale defaults no longer in the current list
    final currentDefaultNames = _defaultTemplates.map((t) => t.name).toSet();
    final keysToDelete = <dynamic>[];
    for (var i = 0; i < box.length; i++) {
      final t = box.getAt(i);
      if (t != null && t.isDefault && !currentDefaultNames.contains(t.name)) {
        keysToDelete.add(box.keyAt(i));
      }
    }
    for (final key in keysToDelete) {
      box.delete(key);
    }

    // Add missing defaults
    final existingNames = <String>{};
    for (var i = 0; i < box.length; i++) {
      final t = box.getAt(i);
      if (t != null) existingNames.add(t.name);
    }
    for (final t in _defaultTemplates) {
      if (!existingNames.contains(t.name)) {
        box.add(t);
      }
    }

    settingsBox.put(_defaultsVersionKey, _currentVersion);
  }

  void loadTemplates() {
    final templates = <ActivityTemplateModel>[];
    for (var i = 0; i < box.length; i++) {
      final t = box.getAt(i);
      if (t != null) templates.add(t);
    }
    state = templates;
  }

  Future<void> addTemplate({
    required String name,
    required String emoji,
    required String category,
    required String timeValue,
  }) async {
    await box.add(ActivityTemplateModel(
      name: name,
      emoji: emoji,
      category: category,
      timeValue: timeValue,
      isDefault: false,
    ));
    loadTemplates();
  }

  Future<void> updateTemplate(
    ActivityTemplateModel template, {
    String? name,
    String? emoji,
    String? category,
    String? timeValue,
  }) async {
    final updated = ActivityTemplateModel(
      name: name ?? template.name,
      emoji: emoji ?? template.emoji,
      category: category ?? template.category,
      timeValue: timeValue ?? template.timeValue,
      isDefault: template.isDefault,
    );
    await box.put(template.key, updated);
    loadTemplates();
  }

  Future<void> deleteTemplate(ActivityTemplateModel template) async {
    await template.delete();
    loadTemplates();
  }
}
