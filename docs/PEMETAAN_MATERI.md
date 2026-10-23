# Pemetaan Materi

Dokumen ini menghubungkan konsep dasar Dart dan Flutter dengan implementasi
Pomodoro Belajar.

## Dart

| Materi | Contoh |
| --- | --- |
| Variabel, konstanta, dan tipe data | `PomodoroSettings`, `PomodoroTimerState`, serta konstanta di `core/constants/app_constants.dart` |
| Enum dan percabangan | `PomodoroMode`, `TimerStatus`, dan `switch` pada engine |
| Fungsi dan nilai balik | Formatter waktu, validasi model, serta fungsi preview siklus |
| Koleksi dan perulangan | Pembuatan titik siklus dan daftar urutan sesi |
| Null safety dan operator | Nilai opsional `endsAt`, `tryParse`, `??`, dan `?.` |
| Async/await | Memuat dan menyimpan snapshot melalui `PomodoroStorage` |

## Flutter

| Materi | Contoh |
| --- | --- |
| `StatelessWidget` | Selector mode, kontrol timer, kartu hitungan, dan field durasi |
| `StatefulWidget` | Layar timer untuk lifecycle dan sheet pengaturan untuk input |
| Komposisi widget | `TimerScreen` tersusun dari widget kecil dengan satu tanggung jawab |
| State bawaan Flutter | `ChangeNotifier`, `AnimatedBuilder`, dan `ValueListenableBuilder` |
| Form dan validasi | `Form`, `TextFormField`, dan validasi rentang durasi |
| Layout responsif | `SafeArea`, `ListView`, `Center`, dan `ConstrainedBox` |
| Tema dan aset | Tema Material 3 serta ilustrasi PNG lokal |

## Desain aplikasi

- `PomodoroEngine` memuat aturan hitung waktu dan perpindahan mode secara
  terpisah dari UI.
- `PomodoroController` mengoordinasikan state, timer periodik UI, dan siklus.
- `PomodoroStorage` membatasi akses plugin penyimpanan pada lapisan data.
- Uji unit mencakup aturan waktu dan transisi; widget test mencakup kontrol
  utama dan pengaturan.
