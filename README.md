<div align="center">
  <h1>✨ Catat-In ✨<br><i>Activity Tracker & Productivity Grader</i></h1>
  
  <p>
    <b>Catat-In</b> adalah aplikasi pelacak aktivitas cerdas yang bukan hanya menghitung durasi waktu, tetapi juga menilai <b>seberapa berharga</b> waktu Anda!
  </p>

  <p>
    <img alt="Flutter" src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white">
    <img alt="Dart" src="https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white">
    <img alt="Android" src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white">
  </p>
</div>

<br>

> *"Jangan hanya sibuk, jadilah produktif. Catat-In membantu Anda mengubah setiap detik menjadi investasi masa depan."*

---

## 🌟 Fitur Utama

| Fitur | Deskripsi |
| --- | --- |
| ⏱️ **Pencatatan Live & Manual** | Tersedia stopwatch terintegrasi untuk melacak aktivitas secara *real-time* atau tambahkan entri waktu masa lalu secara manual. |
| 📊 **Rapor Produktivitas** | Dapatkan Grade (A-E) berdasarkan metrik nilai waktu yang Anda kumpulkan setiap minggunya. Dilengkapi grafik visual yang indah. |
| 📅 **Kalender Interaktif** | Lihat riwayat seluruh aktivitas Anda dalam format kalender bulanan yang minimalis dan terorganisir. |
| 🏷️ **Kategori & Nilai Waktu** | Kelompokkan aktivitas (Kerja, Belajar, Hiburan) dan bobot waktu (Investasi 📈, Produktif ✅, Kebutuhan 🔧, Santai ☕, Terbuang ⚠️). |
| 🔄 **Ekspor / Impor Data** | Cadangkan data ke memori perangkat (Backup JSON), ekspor ke Spreadsheet (**CSV**), atau ke Google Calendar (**ICS**). Impor kembali kapan saja! |
| 🔔 **Pengingat Harian** | Jangan pernah lupa mencatat lagi! Notifikasi lokal akan mengingatkan Anda setiap hari pada jam yang disesuaikan. |
| ⚡ **Template Cepat** | Buat template (contoh: *Jogging Pagi*, *Membaca Buku*) dan catat aktivitas rutin Anda hanya dengan satu klik. |
| 📱 **Widget Beranda** | Kontrol timer aktivitas langsung dari layar utama *smartphone* Android Anda tanpa harus membuka aplikasi! |

---

## 🛠️ Tech Stack & Library

Dibangun dengan antusiasme menggunakan **Flutter** dan **Dart**.
Library pendukung utama:
- 📦 **State Management:** `flutter_riverpod`
- 💾 **Local Storage:** `hive`, `hive_flutter`
- 📈 **Data Visualization:** `fl_chart`
- 📅 **Date & Time:** `table_calendar`, `intl`
- 🔔 **Notifications:** `flutter_local_notifications`
- 📂 **File Handling:** `file_picker`, `csv`, `path_provider`
- 🧩 **Native Extensions:** `home_widget` (Android Widgets)

---

## 🚀 Memulai Proyek (Development)

Tertarik untuk mengembangkan lebih lanjut? Ikuti langkah-langkah mudah di bawah ini!

### Persyaratan:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versi `^3.10.x`)
- [Android Studio](https://developer.android.com/studio) atau [VS Code](https://code.visualstudio.com/)

### Langkah Instalasi:

1. **Clone repositori ini:**
   ```bash
   git clone https://github.com/Lputaa/Catat_in.git
   cd Catat_in
   ```

2. **Unduh semua paket dependensi:**
   ```bash
   flutter pub get
   ```

3. **Generate file otomatis (Hive Models dsb):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Jalankan Aplikasi:**
   ```bash
   flutter run
   ```

---

## 📂 Struktur Direktori

Kami menggunakan struktur berbasis fitur (Feature-Driven) yang bersih dan mudah dinavigasi:

```bash
lib/
├── core/                   # Utilitas inti, layanan sistem, & tema
│   ├── services/           # (Notification & Android Widget Handler)
│   └── theme/              # (App Theme, Custom Colors)
├── features/
│   └── activity/           # Modul fitur aktivitas
│       ├── data/           # (Model Hive untuk database)
│       ├── domain/         # (Entitas, Enum Kategori & Nilai Waktu)
│       └── presentation/   # (Halaman UI, Komponen, dan Provider Riverpod)
└── main.dart               # Entry point utama aplikasi
```

---

## 🤝 Mari Berkontribusi!

Kami sangat menyambut kontribusi, mulai dari laporan *bug*, perbaikan antarmuka, hingga usulan fitur baru.
1. Fork proyek ini
2. Buat branch fitur Anda: `git checkout -b fitur/fitur-keren`
3. Commit perubahan Anda: `git commit -m 'Menambahkan fitur keren'`
4. Push ke branch Anda: `git push origin fitur/fitur-keren`
5. Buka **Pull Request**!

---

<div align="center">
  Dibuat dengan ❤️ dan ☕ untuk hidup yang lebih produktif.
</div>
