import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_belajar/core/utils/format_waktu.dart';
import 'package:pomodoro_belajar/data/models/pomodoro_models.dart';
import 'package:pomodoro_belajar/features/timer/pomodoro_engine.dart';

void main() {
  const engine = PomodoroEngine();

  test('remaining time follows deadline and never becomes negative', () {
    final now = DateTime.utc(2026, 10, 22, 10);
    expect(
      engine.remainingSeconds(
        status: TimerStatus.running,
        savedSeconds: 100,
        endsAt: now.add(const Duration(seconds: 65)),
        now: now,
      ),
      65,
    );
    expect(
      engine.remainingSeconds(
        status: TimerStatus.running,
        savedSeconds: 0,
        endsAt: now.subtract(const Duration(seconds: 2)),
        now: now,
      ),
      0,
    );
  });

  test('restore finalizes only an expired running timer', () {
    final now = DateTime.utc(2026, 10, 22, 10);
    expect(
      engine.shouldFinalizeOnRestore(
        status: TimerStatus.running,
        endsAt: now.subtract(const Duration(seconds: 1)),
        now: now,
      ),
      isTrue,
    );
    expect(
      engine.shouldFinalizeOnRestore(
        status: TimerStatus.paused,
        endsAt: now.subtract(const Duration(seconds: 1)),
        now: now,
      ),
      isFalse,
    );
  });

  test('four completed focus sessions lead to a long break', () {
    var cyclePosition = 0;
    final nextModes = <PomodoroMode>[];
    for (var index = 0; index < 4; index++) {
      nextModes.add(
        engine.nextAfterFocus(
          completedInCycle: cyclePosition,
          focusesBeforeLongBreak: 4,
        ),
      );
      cyclePosition = engine.cycleAfterFocus(
        completedInCycle: cyclePosition,
        focusesBeforeLongBreak: 4,
      );
    }
    expect(nextModes, [
      PomodoroMode.shortBreak,
      PomodoroMode.shortBreak,
      PomodoroMode.shortBreak,
      PomodoroMode.longBreak,
    ]);
    expect(cyclePosition, 0);
    expect(engine.nextAfterBreak(), PomodoroMode.focus);
  });

  test('formatMmSs handles values below zero', () {
    expect(formatMmSs(65), '01:05');
    expect(formatMmSs(-1), '00:00');
  });

  test('settings accept only supported ranges', () {
    expect(const PomodoroSettings().isValid, isTrue);
    expect(const PomodoroSettings(focusMinutes: 0).isValid, isFalse);
    expect(const PomodoroSettings(focusesBeforeLongBreak: 9).isValid, isFalse);
  });
}
