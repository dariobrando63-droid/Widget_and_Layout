import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/tanggal_utils.dart';
import '../../data/models/pomodoro_models.dart';
import '../../data/pomodoro_storage.dart';
import 'pomodoro_engine.dart';

/// Mengelola timer, transisi siklus, dan snapshot yang dipulihkan saat dibuka.
class PomodoroController extends ChangeNotifier {
  PomodoroController({
    required this._storage,
    this._engine = const PomodoroEngine(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    tick.value = _data.timer.remainingSeconds;
  }

  final PomodoroStorage _storage;
  final PomodoroEngine _engine;
  final DateTime Function() _clock;
  PomodoroData _data = const PomodoroData();
  Timer? _ticker;
  bool _disposed = false;
  Object? lastError;
  final ValueNotifier<int> tick = ValueNotifier<int>(25 * detikPerMenit);
  int _sessionCompletionEvents = 0;
  PomodoroMode? _lastCompletedMode;

  PomodoroSettings get settings => _data.settings;
  PomodoroTimerState get timer => _data.timer;
  int get completedFocusToday => _data.completedFocusToday;
  int get sessionCompletionEvents => _sessionCompletionEvents;
  PomodoroMode? get lastCompletedMode => _lastCompletedMode;
  int get remainingSeconds => _engine.remainingSeconds(
    status: timer.status,
    savedSeconds: timer.remainingSeconds,
    endsAt: timer.endsAt,
    now: _clock(),
  );
  ValueListenable<int> get remainingSecondsListenable => tick;

  /// Memuat snapshot lokal dan menyelesaikan sesi yang sudah melewati deadline.
  Future<void> restore() async {
    _data = _storage.load(now: _clock());
    final now = _clock();
    _rolloverDay(now);
    if (_engine.shouldFinalizeOnRestore(
      status: timer.status,
      endsAt: timer.endsAt,
      now: now,
    )) {
      _finishSession(now);
      await _persist();
    } else if (timer.status == TimerStatus.running) {
      tick.value = remainingSeconds;
      _startTicker();
      await _refreshRunningTimer(now, persist: false);
    } else {
      tick.value = timer.remainingSeconds;
    }
    _notify();
  }

  /// Memeriksa deadline ketika aplikasi kembali terlihat setelah di-background.
  Future<void> refreshAfterResume() async {
    final now = _clock();
    _rolloverDay(now);
    if (timer.status == TimerStatus.running && remainingSeconds == 0) {
      _ticker?.cancel();
      _ticker = null;
      _finishSession(now);
      await _persist();
    } else {
      tick.value = remainingSeconds;
    }
    _notify();
  }

  /// Mulai atau lanjutkan timer dari nilai sisa yang tersimpan.
  Future<void> startOrResume() async {
    final now = _clock();
    _rolloverDay(now);
    if (remainingSeconds == 0) {
      _finishSession(now);
    } else {
      final seconds = remainingSeconds;
      tick.value = seconds;
      _data = _data.copyWith(
        timer: timer.copyWith(
          status: TimerStatus.running,
          remainingSeconds: seconds,
          startedAt: now,
          endsAt: now.add(Duration(seconds: seconds)),
        ),
      );
      _startTicker();
    }
    _notify();
    await _persist();
  }

  /// Menjeda timer dengan menghitung sisa waktu dari deadline.
  Future<void> pause() async {
    if (timer.status != TimerStatus.running) return;
    final seconds = remainingSeconds;
    _ticker?.cancel();
    _ticker = null;
    if (seconds == 0) {
      _finishSession(_clock(), notifyCompletion: true);
    } else {
      _data = _data.copyWith(
        timer: timer.copyWith(
          status: TimerStatus.paused,
          remainingSeconds: seconds,
          clearStartedAt: true,
          clearEndsAt: true,
        ),
      );
      tick.value = seconds;
    }
    _notify();
    await _persist();
  }

  /// Mengembalikan timer ke durasi mode saat ini tanpa mengubah siklus.
  Future<void> reset() async {
    _ticker?.cancel();
    _ticker = null;
    final seconds = settings.secondsFor(timer.mode);
    tick.value = seconds;
    _data = _data.copyWith(
      timer: timer.copyWith(
        status: TimerStatus.ready,
        remainingSeconds: seconds,
        durationSeconds: seconds,
        clearStartedAt: true,
        clearEndsAt: true,
      ),
    );
    _notify();
    await _persist();
  }

  /// Lewati mode saat ini; fokus yang dilewati tidak dihitung selesai.
  Future<void> skip() async {
    _ticker?.cancel();
    _ticker = null;
    final mode = _engine.nextAfterSkip(timer.mode);
    _setReadyMode(mode);
    _notify();
    await _persist();
  }

  /// Mengubah mode secara manual dan mengatur ulang durasinya.
  Future<void> selectMode(PomodoroMode mode) async {
    _ticker?.cancel();
    _ticker = null;
    _setReadyMode(mode);
    _notify();
    await _persist();
  }

  /// Menyimpan pengaturan valid dan menerapkannya pada timer yang belum berjalan.
  Future<void> updateSettings(PomodoroSettings value) async {
    if (!value.isValid) {
      throw ArgumentError.value(
        value,
        'value',
        'Pengaturan timer tidak valid.',
      );
    }
    final previousData = _data;
    _data = _data.copyWith(settings: value);
    if (timer.status != TimerStatus.running) {
      final seconds = value.secondsFor(timer.mode);
      tick.value = seconds;
      _data = _data.copyWith(
        timer: timer.copyWith(
          remainingSeconds: seconds,
          durationSeconds: seconds,
        ),
      );
    }
    _notify();
    await _persist();
    if (lastError != null) {
      final error = lastError;
      _data = previousData;
      tick.value = remainingSeconds;
      _notify();
      throw StateError('Pengaturan tidak tersimpan: $error');
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      unawaited(_onTick());
    });
  }

  Future<void> _onTick() async {
    if (_disposed || timer.status != TimerStatus.running) return;
    final now = _clock();
    final oldDate = _data.localDateKey;
    _rolloverDay(now);
    if (remainingSeconds == 0) {
      _ticker?.cancel();
      _ticker = null;
      _finishSession(now, notifyCompletion: true);
      _notify();
      await _persist();
      return;
    }
    tick.value = remainingSeconds;
    if (_data.localDateKey != oldDate) _notify();
  }

  Future<void> _refreshRunningTimer(
    DateTime now, {
    required bool persist,
  }) async {
    if (timer.status != TimerStatus.running) return;
    if (remainingSeconds == 0) {
      _ticker?.cancel();
      _ticker = null;
      _finishSession(now, notifyCompletion: true);
      if (persist) await _persist();
      return;
    }
    tick.value = remainingSeconds;
  }

  void _finishSession(DateTime now, {bool notifyCompletion = false}) {
    final finishedMode = timer.mode;
    if (notifyCompletion) {
      _lastCompletedMode = finishedMode;
      _sessionCompletionEvents++;
    }
    var cyclePosition = timer.cyclePosition;
    var completed = _data.completedFocusToday;
    late PomodoroMode nextMode;

    if (finishedMode == PomodoroMode.focus) {
      completed++;
      nextMode = _engine.nextAfterFocus(
        completedInCycle: cyclePosition,
        focusesBeforeLongBreak: settings.focusesBeforeLongBreak,
      );
      cyclePosition = _engine.cycleAfterFocus(
        completedInCycle: cyclePosition,
        focusesBeforeLongBreak: settings.focusesBeforeLongBreak,
      );
    } else {
      nextMode = _engine.nextAfterBreak();
    }

    final nextSeconds = settings.secondsFor(nextMode);
    tick.value = nextSeconds;
    _data = _data.copyWith(
      completedFocusToday: completed,
      localDateKey: kunciTanggalLokal(now),
      timer: PomodoroTimerState(
        mode: nextMode,
        status: TimerStatus.ready,
        remainingSeconds: nextSeconds,
        durationSeconds: nextSeconds,
        cyclePosition: cyclePosition,
      ),
    );
  }

  void _setReadyMode(PomodoroMode mode) {
    final seconds = settings.secondsFor(mode);
    tick.value = seconds;
    _data = _data.copyWith(
      timer: timer.copyWith(
        mode: mode,
        status: TimerStatus.ready,
        remainingSeconds: seconds,
        durationSeconds: seconds,
        clearStartedAt: true,
        clearEndsAt: true,
      ),
    );
  }

  void _rolloverDay(DateTime now) {
    final date = kunciTanggalLokal(now);
    if (_data.localDateKey == date) return;
    _data = PomodoroData(settings: settings, timer: timer, localDateKey: date);
  }

  Future<void> _persist() async {
    try {
      await _storage.save(_data);
      lastError = null;
    } catch (error) {
      lastError = error;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    tick.dispose();
    super.dispose();
  }
}
