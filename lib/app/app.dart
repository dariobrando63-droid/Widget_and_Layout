import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/pomodoro_storage.dart';
import '../features/auth/login_screen.dart';
import '../features/timer/pomodoro_controller.dart';
import '../features/timer/timer_screen.dart';
import 'theme/app_theme.dart';

/// Aplikasi Pomodoro satu layar dengan penyimpanan lokal lintas platform.
class PomodoroApp extends StatefulWidget {
  /// Membuat aplikasi tanpa kebutuhan konfigurasi global.
  const PomodoroApp({super.key});

  @override
  State<PomodoroApp> createState() => _PomodoroAppState();
}

class _PomodoroAppState extends State<PomodoroApp> {
  late final Future<PomodoroController> _controllerFuture;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _controllerFuture = _createController();
  }

  Future<PomodoroController> _createController() async {
    final preferences = await SharedPreferences.getInstance();
    final controller = PomodoroController(
      storage: PomodoroStorage(preferences),
    );
    await controller.restore();
    return controller;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PomodoroController>(
    future: _controllerFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MaterialApp(
          title: 'Pomodoro Belajar',
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aplikasi gagal memuat penyimpanan lokal.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return MaterialApp(
          title: 'Pomodoro Belajar',
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      return MaterialApp(
        title: 'Pomodoro Belajar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: _isLoggedIn
            ? TimerScreen(
                controller: snapshot.requireData,
                onLogout: () => setState(() => _isLoggedIn = false),
              )
            : LoginScreen(onLogin: () => setState(() => _isLoggedIn = true)),
      );
    },
  );

  @override
  void dispose() {
    unawaited(_controllerFuture.then((controller) => controller.dispose()));
    super.dispose();
  }
}
