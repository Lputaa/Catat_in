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

  /// Specific sub-category tags for each broad category.
  List<String> get subTags {
    switch (this) {
      case ActivityCategory.kerja:
        return [
          'Meeting', 'Coding', 'Review', 'Planning',
          'Email', 'Presentasi', 'Admin',
        ];
      case ActivityCategory.belajar:
        return [
          'Membaca', 'Course', 'Tutorial', 'Riset',
          'Latihan', 'Diskusi', 'Menulis',
        ];
      case ActivityCategory.olahraga:
        return [
          'Lari', 'Gym', 'Renang', 'Sepeda',
          'Yoga', 'Jalan Kaki',
        ];
      case ActivityCategory.hiburan:
        return [
          'Film', 'Musik', 'Gaming', 'Scrolling',
          'YouTube', 'Jalan-jalan', 'Nongkrong', 'Buku',
        ];
      case ActivityCategory.keseharian:
        return [
          'Makan', 'Masak', 'Tidur', 'Perjalanan',
          'Bersih-bersih', 'Belanja', 'Mandi',
        ];
      case ActivityCategory.sosial:
        return [
          'Keluarga', 'Teman', 'Komunitas',
          'Acara', 'Telepon',
        ];
      case ActivityCategory.ibadah:
        return [
          'Sholat', 'Mengaji', 'Gereja', 'Meditasi',
        ];
      case ActivityCategory.lainnya:
        return [];
    }
  }
}
