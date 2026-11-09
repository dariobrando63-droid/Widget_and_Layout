# Pemetaan Materi

Dokumen ini menghubungkan konsep Dart dan Flutter dengan fitur Pomodoro Belajar.

## Dart

| Materi | Contoh |
| --- | --- |
| Variabel, konstanta, dan tipe data | `Akun`, `PomodoroSettings`, `PomodoroTimerState`, dan konstanta aplikasi |
| Enum dan percabangan | `PomodoroMode`, `TimerStatus`, dan perpindahan mode pada engine |
| Fungsi dan nilai balik | Validator form, formatter waktu, dan preview siklus |
| Koleksi dan perulangan | Daftar akun lokal, pertanyaan keamanan, dan titik siklus |
| Null safety | Sesi opsional, deadline timer, dan hasil navigasi |
| Async/await | Memulihkan sesi akun/tamu serta menyimpan akun dan timer |
| Hash dan normalisasi | Salt acak, hash kredensial lokal, dan normalisasi jawaban |

## Flutter

| Materi | Contoh |
| --- | --- |
| `StatelessWidget` | Tombol pil dan kartu bersama |
| `StatefulWidget` | Form akun, onboarding, profil, dan lifecycle timer |
| Komposisi widget | Layar timer dan form disusun dari komponen terfokus |
| State reaktif | `ChangeNotifier`, `AnimatedBuilder`, dan `ValueListenableBuilder` |
| Form dan validasi | `Form`, `TextFormField`, dropdown pertanyaan, serta validator bersama |
| Navigasi | Rute masuk, sesi tamu, daftar, pemulihan sandi, dan profil |
| Layout responsif | `SafeArea`, `ListView`, `Center`, dan `ConstrainedBox` |
| Tema dan aset | Tema Material 3, font lokal, dan ilustrasi tomat |

## Arsitektur

- `PomodoroEngine` menangani perhitungan sisa waktu dan transisi mode secara
  terpisah dari UI.
- `PomodoroController` mengoordinasikan state timer, deadline, pemulihan, dan
  penyimpanan.
- `AuthController` mengelola akun lokal, sesi akun/tamu, pemulihan, dan aturan
  percobaan masuk; `AuthStorage` membatasi akses penyimpanan akun.
- `PomodoroStorage` membuat ruang penyimpanan berdasarkan ID akun atau sesi
  tamu agar timer tidak bercampur.
- `AppTheme` dan widget bersama menyatukan gaya lintas layar.

## Pengujian

Unit test mencakup validasi alur autentikasi, sesi tamu,
penguncian/pemulihan akun, isolasi penyimpanan timer, perhitungan waktu, dan
siklus sesi. Widget test mencakup login dan akses tanpa akun, kontrol timer,
serta pengaturan.
