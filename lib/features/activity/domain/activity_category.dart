enum ActivityCategory {
  kerja,
  belajar,
  olahraga,
  hiburan,
  keseharian,
  sosial,
  ibadah,
  lainnya,
}

extension ActivityCategoryExtension on ActivityCategory {
  String get label {
    switch (this) {
      case ActivityCategory.kerja:
        return 'Kerja';
      case ActivityCategory.belajar:
        return 'Belajar';
      case ActivityCategory.olahraga:
        return 'Olahraga';
      case ActivityCategory.hiburan:
        return 'Hiburan';
      case ActivityCategory.keseharian:
        return 'Keseharian';
      case ActivityCategory.sosial:
        return 'Sosial';
      case ActivityCategory.ibadah:
        return 'Ibadah';
      case ActivityCategory.lainnya:
        return 'Lainnya';
    }
  }

  String get emoji {
    switch (this) {
      case ActivityCategory.kerja:
        return '🏢';
      case ActivityCategory.belajar:
        return '📚';
      case ActivityCategory.olahraga:
        return '🏃';
      case ActivityCategory.hiburan:
        return '🎮';
      case ActivityCategory.keseharian:
        return '🍽';
      case ActivityCategory.sosial:
        return '👥';
      case ActivityCategory.ibadah:
        return '🕌';
      case ActivityCategory.lainnya:
        return '📌';
    }
  }
}
