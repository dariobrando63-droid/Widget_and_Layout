import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodoro_belajar/app/app.dart';
import 'package:pomodoro_belajar/data/auth_storage.dart';
import 'package:pomodoro_belajar/data/models/pomodoro_models.dart';
import 'package:pomodoro_belajar/data/pomodoro_storage.dart';
import 'package:pomodoro_belajar/features/auth/auth_controller.dart';
import 'package:pomodoro_belajar/features/auth/login_screen.dart';
import 'package:pomodoro_belajar/features/auth/register_screen.dart';
import 'package:pomodoro_belajar/features/timer/pomodoro_controller.dart';
import 'package:pomodoro_belajar/features/timer/timer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch can continue without an account', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const PomodoroApp());
    await tester.pumpAndSettle();

    expect(find.text('Fokus satu sesi demi satu sesi.'), findsOneWidget);
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang kembali'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Masuk tanpa akun'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Masuk tanpa akun'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Keluar'), findsOneWidget);
    expect(find.text('Selamat datang kembali'), findsNothing);

    await tester.pumpWidget(const PomodoroApp());
    await tester.pumpAndSettle();
    expect(find.byTooltip('Keluar'), findsOneWidget);
  });

  testWidgets('login validates fields and signs into a local account', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final auth = AuthController(storage: AuthStorage(preferences));
    await auth.initialize();
    await auth.register(
      nama: 'Pelajar',
      email: 'pelajar@example.com',
      kataSandi: 'belajar123',
      pertanyaan: pertanyaanKeamanan.first,
      jawaban: 'Kucing',
    );
    await tester.pumpWidget(MaterialApp(home: LoginScreen(auth: auth)));

    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
    expect(auth.currentAccount, isNull);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'pelajar@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'belajar123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(auth.currentAccount?.email, 'pelajar@example.com');
    auth.dispose();
  });

  testWidgets('registration creates a local account with recovery question', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final auth = AuthController(storage: AuthStorage(preferences));
    await auth.initialize();
    await tester.pumpWidget(MaterialApp(home: RegisterScreen(auth: auth)));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Nama Pelajar');
    await tester.enterText(fields.at(1), 'baru@example.com');
    await tester.enterText(fields.at(2), 'belajar123');
    await tester.enterText(fields.at(3), 'belajar123');
    await tester.ensureVisible(fields.at(4));
    await tester.enterText(fields.at(4), 'Kucing');
    await tester.ensureVisible(find.text('Buat akun'));
    await tester.tap(find.text('Buat akun'));
    await tester.pumpAndSettle();

    expect(auth.securityQuestionFor('baru@example.com'), isNotNull);
    auth.dispose();
  });

  testWidgets('timer page offers controls and settings', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = PomodoroController(
      storage: PomodoroStorage(preferences),
    );
    await controller.restore();

    await tester.pumpWidget(
      MaterialApp(home: TimerScreen(controller: controller)),
    );
    await tester.pump();

    expect(find.text('Pomodoro Belajar'), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);
    expect(find.text('Sesi fokus hari ini'), findsOneWidget);
    expect(find.byTooltip('Pengaturan'), findsOneWidget);

    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan sesi'), findsOneWidget);
    expect(find.text('Simpan pengaturan'), findsOneWidget);

    await tester.ensureVisible(find.text('Simpan pengaturan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan sesi'), findsNothing);

    controller.dispose();
  });

  testWidgets('completed sessions offer the next cycle mode', (tester) async {
    var alertSoundCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemSound.play') alertSoundCount++;
          return null;
        });
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    var now = DateTime(2026, 11, 2, 9);
    final controller = PomodoroController(
      storage: PomodoroStorage(preferences),
      clock: () => now,
    );
    await controller.restore();
    await controller.updateSettings(
      const PomodoroSettings(
        focusMinutes: 1,
        shortBreakMinutes: 1,
        longBreakMinutes: 1,
        focusesBeforeLongBreak: 2,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: TimerScreen(controller: controller)),
    );

    Future<void> completeAndChoose(
      String buttonLabel,
      PomodoroMode nextMode,
    ) async {
      await controller.startOrResume();
      now = now.add(const Duration(minutes: 1));
      await controller.refreshAfterResume();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(buttonLabel), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1400));
      expect(alertSoundCount, greaterThan(1));
      await tester.tap(find.text(buttonLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.timer.mode, nextMode);
      expect(controller.timer.status, TimerStatus.running);
      final soundCountAfterResponse = alertSoundCount;
      await tester.pump(const Duration(milliseconds: 1400));
      expect(alertSoundCount, soundCountAfterResponse);
    }

    await completeAndChoose('Mulai Istirahat Pendek', PomodoroMode.shortBreak);
    await completeAndChoose('Lanjut Sesi Fokus', PomodoroMode.focus);
    await completeAndChoose('Mulai Istirahat Panjang', PomodoroMode.longBreak);
    await completeAndChoose('Lanjut Sesi Fokus', PomodoroMode.focus);

    now = now.add(const Duration(minutes: 1));
    await controller.refreshAfterResume();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Nanti'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.tap(find.text('Nanti'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.timer.mode, PomodoroMode.shortBreak);
    expect(controller.timer.status, TimerStatus.ready);

    controller.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
}
