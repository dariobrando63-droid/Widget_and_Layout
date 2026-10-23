# Pomodoro Belajar

Aplikasi timer Pomodoro sederhana dengan satu layar utama dan pengaturan durasi
yang disimpan di perangkat. Dapat dijalankan sebagai aplikasi Android maupun
melalui browser lokal.

## Fitur

- Mode fokus, istirahat pendek, dan istirahat panjang.
- Halaman login demo lokal dengan validasi form dan tombol keluar.
- Countdown mengikuti deadline sehingga tetap akurat setelah aplikasi kembali
  dibuka.
- Siklus fokus, hitungan sesi fokus harian, dan pengaturan durasi tersimpan lokal.
- Tema terang/gelap mengikuti pengaturan sistem.
- Validasi durasi serta preview satu siklus pada lembar pengaturan.
- Notifikasi browser saat sesi selesai, selama halaman tetap terbuka dan izin
  notifikasi sudah diberikan.

Tidak ada akun, server, database, notifikasi terjadwal, statistik, atau pencatatan
mata kuliah. Notifikasi web tidak dijamin saat tab/browser ditutup atau halaman
ditangguhkan; push notification memerlukan service worker dan server.
Login saat ini hanya demo navigasi: tidak memverifikasi atau membuat akun dan
tidak boleh digunakan sebagai autentikasi untuk data sensitif.

## Menjalankan secara lokal

Prasyarat: Flutter SDK dan, untuk Android, Android SDK/emulator atau perangkat.
Web memerlukan Chrome/Chromium.

```bash
flutter pub get
flutter run -d chrome
```

Untuk menjalankan di Android:

```bash
flutter devices
flutter run -d <device-id>
```

Verifikasi/build:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Data disimpan oleh `shared_preferences` pada browser/perangkat yang sedang
digunakan. Data web dan Android terpisah.

## Struktur

```text
lib/
├── app/                 # App shell dan tema
├── core/                # Konstanta dan fungsi kecil yang dapat diuji
├── data/                # Model dan penyimpanan lokal
└── features/timer/      # Engine, controller, layar, dan pengaturan
assets/images/           # Ilustrasi tomat lokal
docs/                    # Pemetaan materi pembelajaran
test/                    # Unit dan widget tests
```

Untuk ringkasan konsep Flutter/Dart yang dipakai, lihat
[docs/PEMETAAN_MATERI.md](docs/PEMETAAN_MATERI.md).
