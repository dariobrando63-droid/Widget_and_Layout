import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../app/theme/app_theme.dart';
import '../../core/notifications/web_notification_service.dart';
import '../../core/utils/format_waktu.dart';
import '../../core/utils/pesan_semangat.dart';
import '../../core/utils/pomodoro_cycle_utils.dart';
import '../../data/models/pomodoro_models.dart';
import 'pomodoro_controller.dart';
import 'settings_sheet.dart';

/// Layar tunggal untuk timer, hitungan fokus, dan pengaturan sesi.
class TimerScreen extends StatefulWidget {
  const TimerScreen({required this.controller, this.onLogout, super.key});

  final PomodoroController controller;
  final VoidCallback? onLogout;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _lastCompleted = 0;
  int _lastSessionCompletionEvents = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastCompleted = widget.controller.completedFocusToday;
    _lastSessionCompletionEvents = widget.controller.sessionCompletionEvents;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant TimerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _lastCompleted = widget.controller.completedFocusToday;
      _lastSessionCompletionEvents = widget.controller.sessionCompletionEvents;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.refreshAfterResume();
    }
  }

  void _onControllerChanged() {
    final completed = widget.controller.completedFocusToday;
    final justCompleted = completed > _lastCompleted;
    final sessionCompleted =
        widget.controller.sessionCompletionEvents >
        _lastSessionCompletionEvents;
    _lastCompleted = completed;
    _lastSessionCompletionEvents = widget.controller.sessionCompletionEvents;
    if (!mounted) return;
    if (sessionCompleted) unawaited(_playCompletionSound());
    if (sessionCompleted && WebNotificationService.isPermissionGranted) {
      final mode = widget.controller.lastCompletedMode;
      try {
        WebNotificationService.showNotification(
          title: 'Timer selesai',
          body: mode == PomodoroMode.focus
              ? 'Sesi fokus selesai. Saatnya istirahat sejenak.'
              : 'Waktu istirahat selesai. Siap mulai fokus lagi?',
        );
      } catch (error) {
        _showMessage('Notifikasi gagal ditampilkan: $error');
      }
    }
    if (!justCompleted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _showMessage('Sesi fokus selesai. Istirahat sejenak, ya!');
    });
  }

  Future<void> _playCompletionSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/timer_done.mp3'));
    } catch (error) {
      if (mounted) _showMessage('Suara timer gagal diputar: $error');
    }
  }

  Future<void> _enableWebNotifications() async {
    try {
      final granted = await WebNotificationService.requestPermission();
      if (!mounted) return;
      _showMessage(
        granted
            ? 'Notifikasi berhasil diaktifkan.'
            : 'Izin notifikasi belum diberikan. Periksa izin situs di browser.',
      );
      setState(() {});
    } catch (error) {
      if (mounted) _showMessage('Gagal meminta izin notifikasi: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _openSettings() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SettingsSheet(controller: widget.controller),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Pengaturan berhasil disimpan.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final mode = controller.timer.mode;
        final details = detailMode(mode);
        final color = _colorForMode(mode);
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset(
                  'assets/images/tomato.png',
                  width: 34,
                  height: 34,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.timer_outlined, size: 30),
                ),
                const SizedBox(width: 10),
                const Text('Pomodoro Belajar'),
              ],
            ),
            actions: [
              if (widget.onLogout != null)
                IconButton(
                  onPressed: widget.onLogout,
                  tooltip: 'Keluar',
                  icon: const Icon(Icons.logout_rounded),
                ),
              IconButton(
                onPressed: _openSettings,
                tooltip: 'Pengaturan',
                icon: const Icon(Icons.tune_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _ModeSelector(
                      selected: mode,
                      onSelected: controller.selectMode,
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: _TimerDial(
                        color: color,
                        modeLabel: details.label,
                        durationSeconds: controller.timer.durationSeconds,
                        remainingSeconds: controller.remainingSecondsListenable,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      pesanSemangat(controller.completedFocusToday),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 22),
                    _CycleProgress(
                      completed: controller.timer.cyclePosition,
                      total: controller.settings.focusesBeforeLongBreak,
                      color: color,
                    ),
                    const SizedBox(height: 18),
                    _FocusCountCard(count: controller.completedFocusToday),
                    if (kIsWeb) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: WebNotificationService.isPermissionGranted
                            ? null
                            : _enableWebNotifications,
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: Text(
                          WebNotificationService.isPermissionGranted
                              ? 'Notifikasi aktif'
                              : 'Aktifkan notifikasi',
                        ),
                      ),
                    ],
                    if (controller.lastError != null) ...[
                      const SizedBox(height: 12),
                      const _StorageWarning(),
                    ],
                    const SizedBox(height: 24),
                    _TimerControls(
                      status: controller.timer.status,
                      color: color,
                      onStart: controller.startOrResume,
                      onPause: controller.pause,
                      onReset: controller.reset,
                      onSkip: controller.skip,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _colorForMode(PomodoroMode mode) {
    switch (mode) {
      case PomodoroMode.focus:
        return AppTheme.focus;
      case PomodoroMode.shortBreak:
        return AppTheme.shortBreak;
      case PomodoroMode.longBreak:
        return AppTheme.longBreak;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onControllerChanged);
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.selected, required this.onSelected});

  final PomodoroMode selected;
  final ValueChanged<PomodoroMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PomodoroMode>(
      segments: const [
        ButtonSegment(
          value: PomodoroMode.focus,
          label: Text('Fokus'),
          icon: Icon(Icons.center_focus_strong),
        ),
        ButtonSegment(
          value: PomodoroMode.shortBreak,
          label: Text('Jeda'),
          icon: Icon(Icons.coffee_outlined),
        ),
        ButtonSegment(
          value: PomodoroMode.longBreak,
          label: Text('Panjang'),
          icon: Icon(Icons.self_improvement),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (values) => onSelected(values.first),
      showSelectedIcon: false,
    );
  }
}

class _TimerDial extends StatelessWidget {
  const _TimerDial({
    required this.color,
    required this.modeLabel,
    required this.durationSeconds,
    required this.remainingSeconds,
  });

  final Color color;
  final String modeLabel;
  final int durationSeconds;
  final ValueListenable<int> remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: remainingSeconds,
      builder: (context, seconds, _) {
        return SizedBox.square(
          dimension: 270,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: persen(durationSeconds - seconds, durationSeconds),
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    modeLabel.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 2,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatMmSs(seconds),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Satu langkah kecil, satu sesi fokus'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CycleProgress extends StatelessWidget {
  const _CycleProgress({
    required this.completed,
    required this.total,
    required this.color,
  });

  final int completed;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Siklus fokus', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(width: 12),
        for (var index = 0; index < total; index++) ...[
          if (index > 0) const SizedBox(width: 7),
          Icon(
            Icons.circle,
            size: 12,
            color: index < completed
                ? color
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ],
        const SizedBox(width: 10),
        Text('$completed/$total'),
      ],
    );
  }
}

class _FocusCountCard extends StatelessWidget {
  const _FocusCountCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department_outlined),
            const SizedBox(width: 12),
            const Expanded(child: Text('Sesi fokus hari ini')),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerControls extends StatelessWidget {
  const _TimerControls({
    required this.status,
    required this.color,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onSkip,
  });

  final TimerStatus status;
  final Color color;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isRunning = status == TimerStatus.running;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: onReset,
          tooltip: 'Atur ulang',
          icon: const Icon(Icons.restart_alt),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          ),
          onPressed: isRunning ? onPause : onStart,
          icon: Icon(
            isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
          label: Text(isRunning ? 'Jeda' : 'Mulai'),
        ),
        const SizedBox(width: 16),
        IconButton.filledTonal(
          onPressed: onSkip,
          tooltip: 'Lewati sesi',
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }
}

class _StorageWarning extends StatelessWidget {
  const _StorageWarning();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          'Perubahan belum tersimpan. Periksa ruang penyimpanan perangkat.',
        ),
      ),
    );
  }
}
