import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/tanggal_utils.dart';
import 'models/pomodoro_models.dart';

/// Menangani persistensi lokal tanpa membocorkan plugin ke UI.
class PomodoroStorage {
  PomodoroStorage(this._preferences);

  final SharedPreferences _preferences;

  /// Membaca snapshot; data rusak dikembalikan ke nilai awal yang aman.
  PomodoroData load({DateTime? now}) {
    final currentDate = kunciTanggalLokal(now ?? DateTime.now());
    final raw = _preferences.getString(kunciPenyimpananPomodoro);
    if (raw == null) {
      return PomodoroData(localDateKey: currentDate);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return PomodoroData(localDateKey: currentDate);
      }
      final settings = _readSettings(decoded['settings']);
      final timer = _readTimer(decoded['timer'], settings);
      final savedDate = decoded['localDateKey'];
      final savedCount = decoded['completedFocusToday'];
      final sameDay = savedDate is String && savedDate == currentDate;
      return PomodoroData(
        settings: settings,
        timer: timer,
        completedFocusToday: sameDay && savedCount is int && savedCount >= 0
            ? savedCount
            : 0,
        localDateKey: currentDate,
      );
    } on FormatException {
      return PomodoroData(localDateKey: currentDate);
    } on TypeError {
      return PomodoroData(localDateKey: currentDate);
    } on StateError {
      return PomodoroData(localDateKey: currentDate);
    }
  }

  /// Menulis satu JSON agar snapshot timer dan penghitung hari tidak terpisah.
  Future<void> save(PomodoroData data) async {
    final saved = await _preferences.setString(
      kunciPenyimpananPomodoro,
      jsonEncode({
        'settings': {
          'focusMinutes': data.settings.focusMinutes,
          'shortBreakMinutes': data.settings.shortBreakMinutes,
          'longBreakMinutes': data.settings.longBreakMinutes,
          'focusesBeforeLongBreak': data.settings.focusesBeforeLongBreak,
        },
        'timer': {
          'mode': data.timer.mode.name,
          'status': data.timer.status.name,
          'remainingSeconds': data.timer.remainingSeconds,
          'durationSeconds': data.timer.durationSeconds,
          'cyclePosition': data.timer.cyclePosition,
          'startedAt': data.timer.startedAt?.toUtc().toIso8601String(),
          'endsAt': data.timer.endsAt?.toUtc().toIso8601String(),
        },
        'completedFocusToday': data.completedFocusToday,
        'localDateKey': data.localDateKey,
      }),
    );
    if (!saved) {
      throw PlatformException(
        code: 'PREFERENCES_WRITE_FAILED',
        message: 'Penyimpanan lokal menolak perubahan.',
      );
    }
  }

  PomodoroSettings _readSettings(dynamic value) {
    if (value is! Map<String, dynamic>) return pengaturanDefault;
    final settings = PomodoroSettings(
      focusMinutes: _readInt(value['focusMinutes'], 25),
      shortBreakMinutes: _readInt(value['shortBreakMinutes'], 5),
      longBreakMinutes: _readInt(value['longBreakMinutes'], 15),
      focusesBeforeLongBreak: _readInt(value['focusesBeforeLongBreak'], 4),
    );
    return settings.isValid ? settings : pengaturanDefault;
  }

  PomodoroTimerState _readTimer(dynamic value, PomodoroSettings settings) {
    if (value is! Map<String, dynamic>) {
      return _initialTimer(settings);
    }
    final modeName = value['mode'];
    final statusName = value['status'];
    final mode = PomodoroMode.values.where((item) => item.name == modeName);
    final status = TimerStatus.values.where((item) => item.name == statusName);
    final remaining = _readInt(value['remainingSeconds'], -1);
    final duration = _readInt(value['durationSeconds'], -1);
    final cycle = _readInt(value['cyclePosition'], -1);
    final startedAt = _readDate(value['startedAt']);
    final endsAt = _readDate(value['endsAt']);
    if (mode.isEmpty ||
        status.isEmpty ||
        remaining < 0 ||
        duration < 1 ||
        cycle < 0 ||
        cycle >= settings.focusesBeforeLongBreak ||
        (status.first == TimerStatus.running &&
            (startedAt == null || endsAt == null)) ||
        (status.first != TimerStatus.running && endsAt != null)) {
      return _initialTimer(settings);
    }
    return PomodoroTimerState(
      mode: mode.first,
      status: status.first,
      remainingSeconds: remaining,
      durationSeconds: duration,
      cyclePosition: cycle,
      startedAt: startedAt,
      endsAt: endsAt,
    );
  }

  PomodoroTimerState _initialTimer(PomodoroSettings settings) =>
      PomodoroTimerState(
        remainingSeconds: settings.secondsFor(PomodoroMode.focus),
        durationSeconds: settings.secondsFor(PomodoroMode.focus),
      );

  int _readInt(dynamic value, int fallback) => value is int ? value : fallback;

  DateTime? _readDate(dynamic value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
