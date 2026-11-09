import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_storage.dart';
import '../data/pomodoro_storage.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/profile_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/timer/pomodoro_controller.dart';
import '../features/timer/timer_screen.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

/// Aplikasi Pomodoro dengan akun dan data timer lokal per pengguna.
class PomodoroApp extends StatefulWidget {
  const PomodoroApp({super.key});

  @override
  State<PomodoroApp> createState() => _PomodoroAppState();
}

class _PomodoroAppState extends State<PomodoroApp> {
  late final Future<AuthController> _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = _initializeAuth();
  }

  Future<AuthController> _initializeAuth() async {
    final preferences = await SharedPreferences.getInstance();
    final auth = AuthController(storage: AuthStorage(preferences));
    await auth.initialize();
    return auth;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AuthController>(
    future: _authFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MaterialApp(
          title: 'Pomodoro Belajar',
          theme: AppTheme.light(),
          home: _LoadFailure(error: snapshot.error!),
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
      return _AuthenticatedApp(auth: snapshot.requireData);
    },
  );
}

class _AuthenticatedApp extends StatefulWidget {
  const _AuthenticatedApp({required this.auth});

  final AuthController auth;

  @override
  State<_AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<_AuthenticatedApp> {
  String? _timerAccountId;
  PomodoroController? _timerController;
  Future<PomodoroController>? _timerFuture;

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  void _onAuthChanged() {
    final sessionId = widget.auth.currentSessionId;
    if (sessionId == _timerAccountId) return;
    _timerController?.dispose();
    _timerController = null;
    _timerAccountId = sessionId;
    if (sessionId == null) {
      _timerFuture = null;
    } else {
      _timerFuture = _createTimerController(sessionId);
    }
    if (mounted) setState(() {});
  }

  Future<PomodoroController> _createTimerController(String accountId) async {
    final preferences = await SharedPreferences.getInstance();
    final controller = PomodoroController(
      storage: PomodoroStorage(preferences, accountId: accountId),
    );
    await controller.restore();
    if (!mounted || widget.auth.currentSessionId != accountId) {
      controller.dispose();
      return controller;
    }
    _timerController = controller;
    return controller;
  }

  Route<dynamic> _route(RouteSettings settings) {
    final name = settings.name;
    final route = switch (name) {
      AppRoutes.register => MaterialPageRoute<String>(
        builder: (_) => RegisterScreen(auth: widget.auth),
        settings: settings,
      ),
      AppRoutes.forgotPassword => MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordScreen(auth: widget.auth),
        settings: settings,
      ),
      AppRoutes.profile => MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(auth: widget.auth),
        settings: settings,
      ),
      AppRoutes.login => MaterialPageRoute<void>(
        builder: (_) => LoginScreen(auth: widget.auth),
        settings: settings,
      ),
      _ => MaterialPageRoute<void>(builder: (_) => _home(), settings: settings),
    };
    return route;
  }

  Widget _home() {
    if (!widget.auth.onboardingDone) {
      return OnboardingScreen(auth: widget.auth);
    }
    final account = widget.auth.currentAccount;
    if (account == null && !widget.auth.isGuest) {
      return LoginScreen(auth: widget.auth);
    }
    final future = _timerFuture;
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<PomodoroController>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LoadFailure(error: snapshot.error!);
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return TimerScreen(
          controller: snapshot.requireData,
          accountName: account?.nama ?? 'Pengguna tamu',
          onProfile: account == null
              ? null
              : () => Navigator.of(context).pushNamed(AppRoutes.profile),
          onLogout: widget.auth.logout,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.auth,
    builder: (context, _) => MaterialApp(
      title: 'Pomodoro Belajar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      onGenerateRoute: _route,
      home: _home(),
    ),
  );

  @override
  void dispose() {
    widget.auth.removeListener(_onAuthChanged);
    _timerController?.dispose();
    unawaited(
      _timerFuture?.then<void>((controller) {
        if (!identical(controller, _timerController)) controller.dispose();
      }),
    );
    widget.auth.dispose();
    super.dispose();
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Aplikasi gagal memuat penyimpanan lokal.\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
