import '../../data/models/pomodoro_models.dart';

class PomodoroEngine {
  const PomodoroEngine();

  /// Menentukan apakah timer aktif sudah melewati deadline saat dipulihkan.
  bool shouldFinalizeOnRestore({
    required TimerStatus status,
    required DateTime? endsAt,
    required DateTime now,
  }) => status == TimerStatus.running && endsAt != null && !endsAt.isAfter(now);

  /// Menghitung sisa waktu dari deadline, bukan jumlah tick.
  int remainingSeconds({
    required TimerStatus status,
    required int savedSeconds,
    required DateTime? endsAt,
    required DateTime now,
  }) {
    if (status != TimerStatus.running || endsAt == null) {
      return savedSeconds < 0 ? 0 : savedSeconds;
    }
    final difference = (endsAt.difference(now).inMilliseconds / 1000).ceil();
    return difference < 0 ? 0 : difference;
  }

  /// Memilih istirahat setelah sesi fokus selesai.
  PomodoroMode nextAfterFocus({
    required int completedInCycle,
    required int focusesBeforeLongBreak,
  }) {
    if (completedInCycle + 1 >= focusesBeforeLongBreak) {
      return PomodoroMode.longBreak;
    }
    return PomodoroMode.shortBreak;
  }

  /// Menghitung ulang posisi fokus dalam siklus berikutnya.
  int cycleAfterFocus({
    required int completedInCycle,
    required int focusesBeforeLongBreak,
  }) {
    if (completedInCycle + 1 >= focusesBeforeLongBreak) return 0;
    return completedInCycle + 1;
  }

  /// Mode fokus setelah sesi istirahat selesai.
  PomodoroMode nextAfterBreak() => PomodoroMode.focus;

  /// Mode berikutnya untuk Lewati tanpa menambah hitungan fokus.
  PomodoroMode nextAfterSkip(PomodoroMode mode) {
    if (mode == PomodoroMode.focus) return PomodoroMode.shortBreak;
    return PomodoroMode.focus;
  }
}
