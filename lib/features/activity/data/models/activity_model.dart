import 'package:catat_in/features/activity/domain/time_value.dart';
import 'package:hive/hive.dart';

part 'activity_model.g.dart';

@HiveType(typeId: 0)
class ActivityModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(4)
  final List<String> tags;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String category;

  @HiveField(7)
  final DateTime? startAt;

  @HiveField(8)
  final DateTime? endAt;

  @HiveField(9)
  final bool isRunning;

  @HiveField(10)
  final String? notes;

  @HiveField(11)
  final String? _timeValue;

  /// Safe accessor — always returns a valid TimeValue.
  TimeValue get timeValueEnum =>
      TimeValue.fromString(_timeValue);

  /// Stored string (nullable for migration safety).
  String get timeValue => _timeValue ?? 'kebutuhan';

  /// Computed from timeValue. Replaces the old stored `isProductive` field.
  bool get isProductive => timeValueEnum.isPositive;

  ActivityModel({
    required this.name,
    required this.tags,
    required this.createdAt,
    required this.category,
    this.startAt,
    this.endAt,
    this.isRunning = false,
    this.notes,
    String? timeValue,
  }) : _timeValue = timeValue ?? 'kebutuhan';
}
