import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodoro_belajar/core/constants/app_constants.dart';
import 'package:pomodoro_belajar/core/utils/pesan_semangat.dart';
import 'package:pomodoro_belajar/core/utils/pomodoro_cycle_utils.dart';
import 'package:pomodoro_belajar/core/utils/tanggal_utils.dart';
import 'package:pomodoro_belajar/data/models/pomodoro_models.dart';
import 'package:pomodoro_belajar/data/pomodoro_storage.dart';
import 'package:pomodoro_belajar/features/timer/pomodoro_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('storage safely defaults malformed JSON and invalid settings', () async {
    SharedPreferences.setMockInitialValues({
      kunciPenyimpananPomodoro: '{bad json',
    });
    final preferences = await SharedPreferences.getInstance();
    final storage = PomodoroStorage(preferences);
    final loaded = storage.load(now: DateTime(2026, 10, 23));

    expect(loaded.settings, pengaturanDefault);
    expect(loaded.timer.mode, PomodoroMode.focus);
    expect(loaded.completedFocusToday, 0);
    expect(loaded.localDateKey, '2026-10-23');

    await storage.save(
      const PomodoroData(
        settings: PomodoroSettings(focusMinutes: 0),
        completedFocusToday: 7,
      ),
    );
    expect(
      storage.load(now: DateTime(2026, 10, 23)).settings,
      pengaturanDefault,
    );
  });

  test(
    'expired pause finalizes focus exactly once and cycle advances',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final storage = PomodoroStorage(preferences);
      var now = DateTime(2026, 10, 23, 9);
      final controller = PomodoroController(storage: storage, clock: () => now);
      await controller.restore();
      await controller.updateSettings(
        const PomodoroSettings(
          focusMinutes: 1,
          shortBreakMinutes: 2,
          longBreakMinutes: 3,
          focusesBeforeLongBreak: 2,
        ),
      );

      await controller.startOrResume();
      expect(controller.timer.status, TimerStatus.running);
      now = now.add(const Duration(minutes: 1));
      await controller.pause();
      expect(controller.completedFocusToday, 1);
      expect(controller.timer.mode, PomodoroMode.shortBreak);
      expect(controller.timer.cyclePosition, 1);
      expect(controller.timer.status, TimerStatus.ready);
      expect(controller.sessionCompletionEvents, 1);
      expect(controller.lastCompletedMode, PomodoroMode.focus);

      controller.dispose();
      final restored = PomodoroController(storage: storage, clock: () => now);
      await restored.restore();
      expect(restored.completedFocusToday, 1);
      expect(restored.timer.mode, PomodoroMode.shortBreak);
      expect(restored.sessionCompletionEvents, 0);

      await restored.skip();
      expect(restored.timer.mode, PomodoroMode.focus);
      expect(restored.completedFocusToday, 1);
      await restored.startOrResume();
      now = now.add(const Duration(minutes: 1));
      await restored.pause();
      expect(restored.completedFocusToday, 2);
      expect(restored.timer.mode, PomodoroMode.longBreak);
      expect(restored.timer.cyclePosition, 0);
      restored.dispose();
    },
  );

  test('date, messages, and cycle preview are deterministic', () {
    expect(kunciTanggalLokal(DateTime(2026, 1, 2)), '2026-01-02');
    expect(adaHariBerbeda(DateTime(2026, 1, 2), DateTime(2026, 1, 3)), isTrue);
    expect(pesanSemangat(0), 'Yuk mulai sesi pertamamu');
    expect(
      teksPratinjauSiklus(const PomodoroSettings(focusesBeforeLongBreak: 2)),
      'Fokus 25 → Istirahat Pendek 5 → Fokus 25 → Istirahat Panjang 15',
    );
    expect(
      totalMenitSiklus(const PomodoroSettings(focusesBeforeLongBreak: 2)),
      70,
    );
    expect(
      totalMenitFokus(const PomodoroSettings(focusesBeforeLongBreak: 2)),
      50,
    );
  });
}
