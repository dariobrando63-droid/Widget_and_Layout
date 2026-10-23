import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodoro_belajar/data/pomodoro_storage.dart';
import 'package:pomodoro_belajar/features/auth/login_screen.dart';
import 'package:pomodoro_belajar/features/timer/pomodoro_controller.dart';
import 'package:pomodoro_belajar/features/timer/timer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login validates fields and submits valid demo credentials', (
    tester,
  ) async {
    var loggedIn = false;
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onLogin: () => loggedIn = true)),
    );

    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi minimal 6 karakter.'), findsOneWidget);
    expect(loggedIn, isFalse);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'pelajar@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'belajar123');
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(loggedIn, isTrue);
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
}
