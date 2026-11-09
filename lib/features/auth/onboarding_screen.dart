import 'package:flutter/material.dart';

import '../../shared/widgets/pill_button.dart';
import 'auth_controller.dart';

/// Perkenalan singkat yang hanya tampil sebelum penggunaan pertama.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.auth, super.key});

  final AuthController auth;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _continue() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.completeOnboarding();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Pengaturan awal gagal disimpan: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(28),
              children: [
                const SizedBox(height: 32),
                Image.asset(
                  'assets/images/tomato.png',
                  height: 190,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.timer_outlined,
                    size: 150,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Fokus satu sesi demi satu sesi.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Atur waktu belajar dan istirahatmu dengan Pomodoro. '
                  'Progres disimpan secara lokal di perangkat ini.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 28),
                PillButton(
                  label: 'Mulai',
                  icon: Icons.arrow_forward_rounded,
                  busy: _busy,
                  onPressed: _continue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
