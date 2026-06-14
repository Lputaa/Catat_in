// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityModelAdapter extends TypeAdapter<ActivityModel> {
  @override
  final int typeId = 0;

  @override
  ActivityModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Migration: derive timeValue from old isProductive field
    final storedTimeValue = fields[11] as String?;
    String? resolvedTimeValue;
    if (storedTimeValue != null) {
      resolvedTimeValue = storedTimeValue;
    } else if (fields.containsKey(3)) {
      final oldProductive = fields[3] as bool?;
      resolvedTimeValue =
          (oldProductive ?? true) ? 'produktif' : 'santai';
    }
    // else: null → model getter defaults to 'kebutuhan'

    return ActivityModel(
      name: (fields[0] as String?) ?? 'Aktivitas',
      tags: ((fields[4] as List?)?.cast<String>()) ?? [],
      createdAt: (fields[5] as DateTime?) ?? DateTime.now(),
      category: (fields[6] as String?) ?? 'Lainnya',
      startAt: fields[7] as DateTime?,
      endAt: fields[8] as DateTime?,
      isRunning: (fields[9] as bool?) ?? false,
      notes: fields[10] as String?,
      timeValue: resolvedTimeValue,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.isProductive)
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.startAt)
      ..writeByte(8)
      ..write(obj.endAt)
      ..writeByte(9)
      ..write(obj.isRunning)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.timeValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
