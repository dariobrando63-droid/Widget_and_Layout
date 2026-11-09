# Pomodoro Belajar

Aplikasi Flutter untuk membantu belajar dalam sesi fokus Pomodoro. Aplikasi
memiliki akun lokal, pilihan masuk tanpa akun, timer tersimpan lokal,
pengaturan durasi, dan tampilan yang mengikuti tema sistem.

## Fitur

- Onboarding singkat dan formulir pendaftaran akun lokal.
- Masuk dengan email/kata sandi, opsi ingat sesi, dan penguncian sementara
  setelah lima percobaan masuk yang gagal.
- Masuk tanpa akun dengan sesi tamu; progresnya tersimpan lokal dan tetap
  terpisah dari data akun.
- Pemulihan dan pengubahan kata sandi melalui jawaban keamanan, serta
  pengubahan nama dan penghapusan akun.
- Timer fokus, istirahat pendek, dan istirahat panjang yang menghitung mundur
  berdasarkan deadline sehingga dapat dipulihkan setelah aplikasi ditutup.
- Dialog akhir sesi menawarkan mulai jeda atau kembali ke fokus. Alarm suara
  berulang berbunyi di web dan ponsel sampai pengguna memilih salah satu
  tindakan pada dialog. Di web, notifikasi browser juga dapat diaktifkan dari
  layar timer.
- Hitungan fokus harian, pengaturan durasi, dan data timer yang dipisahkan per
  akun.
- Tema terang/gelap sistem, font lokal Inter, serta
  ilustrasi tomat lokal.

## Batasan penyimpanan lokal

Akun dan progres disimpan di perangkat melalui `shared_preferences`; tidak ada
server, sinkronisasi, atau pemulihan lintas perangkat. Penyimpanan tersebut
tidak terenkripsi. Kata sandi dan jawaban keamanan disimpan sebagai hash
bersalt dengan pengulangan SHA-256, bukan sebagai teks asli. Ini hanya
perlindungan dasar untuk aplikasi belajar lokal dan bukan pengganti autentikasi
atau penyimpanan rahasia yang dirancang untuk penggunaan sensitif/produksi.
Menghapus akun juga menghapus data timer lokal dengan ID akun tersebut.

Pengingat web memerlukan izin notifikasi browser dan koneksi HTTPS atau
localhost. Tab timer harus tetap terbuka; browser dapat menunda timer saat tab
tidak aktif, dan alarm/notifikasi tidak dijadwalkan ketika browser ditutup.
Sesi yang melewati deadline diselesaikan saat timer dipulihkan.

## Menjalankan

Prasyarat: Flutter SDK; untuk Android, Android SDK/emulator atau perangkat.

```bash
flutter pub get
flutter run
```

Verifikasi:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Struktur

```text
lib/
├── app/                 # App shell, rute, tema
├── core/                # Validator dan fungsi yang dapat diuji
├── data/                # Model serta penyimpanan lokal akun/timer
├── features/auth/       # Onboarding, akun, pemulihan, profil
├── features/timer/      # Engine, controller, layar, pengaturan
└── shared/              # Komponen UI bersama
assets/fonts/            # Font lokal berlisensi OFL
assets/images/           # Ilustrasi tomat
docs/                    # Pemetaan materi pembelajaran
test/                    # Unit dan widget tests
```

Untuk ringkasan konsep Flutter/Dart, lihat
[docs/PEMETAAN_MATERI.md](docs/PEMETAAN_MATERI.md).
