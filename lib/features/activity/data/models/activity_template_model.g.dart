// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_template_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityTemplateModelAdapter extends TypeAdapter<ActivityTemplateModel> {
  @override
  final int typeId = 1;

  @override
  ActivityTemplateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return ActivityTemplateModel(
      name: (fields[0] as String?) ?? 'Template',
      emoji: (fields[1] as String?) ?? '📌',
      category: (fields[2] as String?) ?? 'Lainnya',
      timeValue: (fields[4] as String?) ?? 'kebutuhan',
      isDefault: (fields[5] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityTemplateModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.emoji)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.timeValue)
      ..writeByte(5)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityTemplateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
