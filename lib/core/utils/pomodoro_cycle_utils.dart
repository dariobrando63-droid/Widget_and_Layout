import '../../data/models/pomodoro_models.dart';

const Set<PomodoroMode> modeIstirahat = {
  PomodoroMode.shortBreak,
  PomodoroMode.longBreak,
};

/// Label, ikon, dan pesan yang dipakai UI untuk setiap mode timer.
({String label, IconDataPlaceholder icon, String message}) detailMode(
  PomodoroMode mode,
) {
  switch (mode) {
    case PomodoroMode.focus:
      return (
        label: 'Fokus',
        icon: IconDataPlaceholder.timer,
        message: 'Fokus pada satu hal. Satu sesi kecil tetap kemajuan.',
      );
    case PomodoroMode.shortBreak:
      return (
        label: 'Istirahat Pendek',
        icon: IconDataPlaceholder.coffee,
        message: 'Tarik napas sejenak sebelum kembali belajar.',
      );
    case PomodoroMode.longBreak:
      return (
        label: 'Istirahat Panjang',
        icon: IconDataPlaceholder.selfImprovement,
        message: 'Istirahat lebih lama, kamu sudah bekerja keras.',
      );
  }
}

/// Ikon simbolik agar fungsi pemetaan mode tetap bebas dari Flutter.
enum IconDataPlaceholder { timer, coffee, selfImprovement }

/// Membentuk urutan siklus dengan satu iterasi minimum yang terdefinisi.
List<PomodoroMode> pratinjauSiklus(int jumlahFokus) {
  final sesi = jumlahFokus < 2 || jumlahFokus > 8 ? 4 : jumlahFokus;
  final hasil = <PomodoroMode>[];
  var indeks = 0;
  do {
    hasil.add(PomodoroMode.focus);
    indeks++;
    if (indeks < sesi) {
      hasil.add(PomodoroMode.shortBreak);
    } else {
      hasil.add(PomodoroMode.longBreak);
    }
  } while (indeks < sesi);
  return hasil;
}

/// Menghitung seluruh waktu siklus, termasuk jeda panjang terakhir.
int totalMenitSiklus(PomodoroSettings settings) {
  final durasi = <PomodoroMode, int>{
    PomodoroMode.focus: settings.focusMinutes,
    PomodoroMode.shortBreak: settings.shortBreakMinutes,
    PomodoroMode.longBreak: settings.longBreakMinutes,
  };
  final urutan = pratinjauSiklus(settings.focusesBeforeLongBreak);
  final modeJedaValid = <PomodoroMode>{};
  for (final mode in modeIstirahat) {
    modeJedaValid.add(mode);
  }
  final jumlahMode = <PomodoroMode, int>{
    for (final mode in PomodoroMode.values) mode: 0,
  };
  for (final mode in urutan) {
    if (!modeJedaValid.contains(mode) || durasi.containsKey(mode)) {
      jumlahMode[mode] = (jumlahMode[mode] ?? 0) + 1;
    }
  }
  var total = 0;
  for (final entry in durasi.entries) {
    final mode = entry.key;
    final menit = entry.value;
    total += menit * (jumlahMode[mode] ?? 0);
  }
  return total;
}

/// Menghitung menit fokus saja dengan melewati jeda dan berhenti di jeda panjang.
int totalMenitFokus(PomodoroSettings settings) {
  final urutan = pratinjauSiklus(settings.focusesBeforeLongBreak);
  var indeks = 0;
  var total = 0;
  while (indeks < urutan.length) {
    final mode = urutan[indeks];
    indeks++;
    if (modeIstirahat.contains(mode)) {
      if (mode == PomodoroMode.longBreak) break;
      continue;
    }
    total += settings.focusMinutes;
  }
  return total;
}

/// Mengubah siklus menjadi teks yang mudah dibaca di lembar pengaturan.
String teksPratinjauSiklus(PomodoroSettings settings) {
  final mode = pratinjauSiklus(settings.focusesBeforeLongBreak);
  final durasi = <PomodoroMode, int>{
    PomodoroMode.focus: settings.focusMinutes,
    PomodoroMode.shortBreak: settings.shortBreakMinutes,
    PomodoroMode.longBreak: settings.longBreakMinutes,
  };
  final bagian = <String>[];
  for (final item in mode) {
    final detail = detailMode(item);
    bagian.add('${detail.label} ${durasi[item]}');
  }
  return bagian.join(' → ');
}
