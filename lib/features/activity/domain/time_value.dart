import 'package:flutter/material.dart';

enum TimeValue {
  investasi,
  produktif,
  kebutuhan,
  santai,
  terbuang;

  String get label {
    switch (this) {
      case TimeValue.investasi:
        return 'Investasi Waktu';
      case TimeValue.produktif:
        return 'Produktif';
      case TimeValue.kebutuhan:
        return 'Kebutuhan';
      case TimeValue.santai:
        return 'Santai';
      case TimeValue.terbuang:
        return 'Terbuang';
    }
  }

  String get shortLabel {
    switch (this) {
      case TimeValue.investasi:
        return 'Investasi';
      case TimeValue.produktif:
        return 'Produktif';
      case TimeValue.kebutuhan:
        return 'Kebutuhan';
      case TimeValue.santai:
        return 'Santai';
      case TimeValue.terbuang:
        return 'Terbuang';
    }
  }

  String get emoji {
    switch (this) {
      case TimeValue.investasi:
        return '⭐';
      case TimeValue.produktif:
        return '✅';
      case TimeValue.kebutuhan:
        return '🔧';
      case TimeValue.santai:
        return '🎯';
      case TimeValue.terbuang:
        return '⚠️';
    }
  }

  Color get color {
    switch (this) {
      case TimeValue.investasi:
        return Colors.amber;
      case TimeValue.produktif:
        return Colors.green;
      case TimeValue.kebutuhan:
        return Colors.blue;
      case TimeValue.santai:
        return Colors.teal;
      case TimeValue.terbuang:
        return Colors.red;
    }
  }

  int get score {
    switch (this) {
      case TimeValue.investasi:
        return 5;
      case TimeValue.produktif:
        return 4;
      case TimeValue.kebutuhan:
        return 3;
      case TimeValue.santai:
        return 2;
      case TimeValue.terbuang:
        return 1;
    }
  }

  bool get isPositive =>
      this == TimeValue.investasi || this == TimeValue.produktif;

  static TimeValue fromString(String? value) {
    if (value == null) return TimeValue.kebutuhan;
    return TimeValue.values.firstWhere(
      (v) => v.name == value,
      orElse: () => TimeValue.kebutuhan,
    );
  }

  static TimeValue fromLegacy(bool? isProductive) {
    if (isProductive == null) return TimeValue.kebutuhan;
    return isProductive ? TimeValue.produktif : TimeValue.santai;
  }
}
