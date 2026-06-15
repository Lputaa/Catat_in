import 'package:hive/hive.dart';

part 'activity_template_model.g.dart';

@HiveType(typeId: 1)
class ActivityTemplateModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String emoji;

  @HiveField(2)
  final String category;

  @HiveField(4)
  final String timeValue;

  @HiveField(5)
  final bool isDefault;

  ActivityTemplateModel({
    required this.name,
    required this.emoji,
    required this.category,
    required this.timeValue,
    this.isDefault = false,
  });
}
