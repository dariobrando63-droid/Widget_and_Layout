/// Mode belajar atau istirahat dalam satu siklus Pomodoro.
enum PomodoroMode { focus, shortBreak, longBreak }

/// Kondisi timer yang dapat dipulihkan setelah aplikasi dibuka kembali.
enum TimerStatus { ready, running, paused }

/// Durasi sesi dan jumlah fokus sebelum istirahat panjang.
class PomodoroSettings {
  const PomodoroSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.focusesBeforeLongBreak = 4,
  });

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int focusesBeforeLongBreak;

  /// Mengembalikan panjang sesi dalam detik untuk mode yang dipilih.
  int secondsFor(PomodoroMode mode) {
    switch (mode) {
      case PomodoroMode.focus:
        return focusMinutes * 60;
      case PomodoroMode.shortBreak:
        return shortBreakMinutes * 60;
      case PomodoroMode.longBreak:
        return longBreakMinutes * 60;
    }
  }

  /// Memastikan setiap nilai berada dalam rentang yang mudah digunakan.
  bool get isValid =>
      focusMinutes >= 1 &&
      focusMinutes <= 120 &&
      shortBreakMinutes >= 1 &&
      shortBreakMinutes <= 60 &&
      longBreakMinutes >= 1 &&
      longBreakMinutes <= 60 &&
      focusesBeforeLongBreak >= 2 &&
      focusesBeforeLongBreak <= 8;

  /// Membuat pengaturan baru dengan nilai yang diubah saja.
  PomodoroSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? focusesBeforeLongBreak,
  }) => PomodoroSettings(
    focusMinutes: focusMinutes ?? this.focusMinutes,
    shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
    longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
    focusesBeforeLongBreak:
        focusesBeforeLongBreak ?? this.focusesBeforeLongBreak,
  );
}

/// Snapshot timer yang bisa disimpan dan dipulihkan.
class PomodoroTimerState {
  const PomodoroTimerState({
    this.mode = PomodoroMode.focus,
    this.status = TimerStatus.ready,
    this.remainingSeconds = 25 * 60,
    this.durationSeconds = 25 * 60,
    this.cyclePosition = 0,
    this.startedAt,
    this.endsAt,
  });

  final PomodoroMode mode;
  final TimerStatus status;
  final int remainingSeconds;
  final int durationSeconds;
  final int cyclePosition;
  final DateTime? startedAt;
  final DateTime? endsAt;

  /// Menyalin snapshot sambil mempertahankan nilai yang tidak berubah.
  PomodoroTimerState copyWith({
    PomodoroMode? mode,
    TimerStatus? status,
    int? remainingSeconds,
    int? durationSeconds,
    int? cyclePosition,
    DateTime? startedAt,
    DateTime? endsAt,
    bool clearStartedAt = false,
    bool clearEndsAt = false,
  }) => PomodoroTimerState(
    mode: mode ?? this.mode,
    status: status ?? this.status,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    cyclePosition: cyclePosition ?? this.cyclePosition,
    startedAt: clearStartedAt ? null : startedAt ?? this.startedAt,
    endsAt: clearEndsAt ? null : endsAt ?? this.endsAt,
  );
}

/// Seluruh data lokal yang disimpan sebagai satu snapshot.
class PomodoroData {
  const PomodoroData({
    this.settings = const PomodoroSettings(),
    this.timer = const PomodoroTimerState(),
    this.completedFocusToday = 0,
    this.localDateKey = '',
  });

  final PomodoroSettings settings;
  final PomodoroTimerState timer;
  final int completedFocusToday;
  final String localDateKey;

  /// Menyalin snapshot dengan mengganti bidang yang telah diperbarui.
  PomodoroData copyWith({
    PomodoroSettings? settings,
    PomodoroTimerState? timer,
    int? completedFocusToday,
    String? localDateKey,
  }) => PomodoroData(
    settings: settings ?? this.settings,
    timer: timer ?? this.timer,
    completedFocusToday: completedFocusToday ?? this.completedFocusToday,
    localDateKey: localDateKey ?? this.localDateKey,
  );
}
