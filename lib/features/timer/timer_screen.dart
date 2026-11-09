import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/format_waktu.dart';
import '../../core/utils/pesan_semangat.dart';
import '../../core/utils/pomodoro_cycle_utils.dart';
import '../../core/notifications/web_session_alerts.dart';
import '../../data/models/pomodoro_models.dart';
import 'pomodoro_controller.dart';
import 'settings_sheet.dart';

/// Layar tunggal untuk timer, hitungan fokus, dan pengaturan sesi.
class TimerScreen extends StatefulWidget {
  const TimerScreen({
    required this.controller,
    this.accountName,
    this.onProfile,
    this.onLogout,
    super.key,
  });

  final PomodoroController controller;
  final String? accountName;
  final VoidCallback? onProfile;
  final VoidCallback? onLogout;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  int _lastSessionCompletionEvents = 0;
  bool _completionDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastSessionCompletionEvents = widget.controller.sessionCompletionEvents;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant TimerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
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
    final sessionCompleted =
        widget.controller.sessionCompletionEvents >
        _lastSessionCompletionEvents;
    _lastSessionCompletionEvents = widget.controller.sessionCompletionEvents;
    final finishedMode = widget.controller.lastCompletedMode;
    if (!mounted ||
        !sessionCompleted ||
        finishedMode == null ||
        _completionDialogOpen) {
      return;
    }
    _completionDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _presentSessionCompletion(finishedMode);
    });
  }

  Future<void> _presentSessionCompletion(PomodoroMode finishedMode) async {
    final nextMode = widget.controller.timer.mode;
    final finishedLabel = detailMode(finishedMode).label;
    final nextLabel = detailMode(nextMode).label;
    final isFocus = finishedMode == PomodoroMode.focus;
    final title = '$finishedLabel selesai';
    final body = isFocus
        ? 'Waktunya ${nextLabel.toLowerCase()}. Mulai sekarang?'
        : 'Jeda selesai. Siap kembali ke sesi fokus?';

    try {
      HapticFeedback.mediumImpact();
      if (kIsWeb) {
        try {
          WebSessionAlerts.notifySessionComplete(title: title, body: body);
        } catch (error) {
          _showMessage('Notifikasi browser gagal ditampilkan: $error');
        }
      }
      try {
        await WebSessionAlerts.startAlarm();
      } catch (error) {
        _showMessage('Suara alarm gagal diputar: $error');
      }

      if (!mounted) return;
      final startNext = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(
            isFocus ? Icons.coffee_outlined : Icons.center_focus_strong,
          ),
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(isFocus ? 'Mulai $nextLabel' : 'Lanjut Sesi Fokus'),
            ),
          ],
        ),
      );
      if (startNext == true &&
          mounted &&
          widget.controller.timer.mode == nextMode) {
        await widget.controller.startOrResume();
      }
    } finally {
      WebSessionAlerts.stopAlarm();
      _completionDialogOpen = false;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _enableWebAlerts() async {
    try {
      final granted = await WebSessionAlerts.enable();
      if (!mounted) return;
      setState(() {});
      _showMessage(
        granted
            ? 'Notifikasi dan suara alarm berhasil diaktifkan.'
            : WebSessionAlerts.isSecureContext
            ? 'Izin notifikasi belum diberikan. Periksa izin situs di browser.'
            : 'Notifikasi browser memerlukan koneksi HTTPS atau localhost.',
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Pengingat web gagal diaktifkan: $error');
      }
    }
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
              if (widget.onProfile != null)
                IconButton(
                  onPressed: widget.onProfile,
                  tooltip: widget.accountName ?? 'Profil',
                  icon: const Icon(Icons.account_circle_outlined),
                ),
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
                    if (kIsWeb && !WebSessionAlerts.isReady) ...[
                      const SizedBox(height: 12),
                      _WebAlertsCard(
                        secureContext: WebSessionAlerts.isSecureContext,
                        permissionDenied: WebSessionAlerts.notificationDenied,
                        onEnable: _enableWebAlerts,
                      ),
                    ],
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
    WebSessionAlerts.stopAlarm();
    super.dispose();
  }
}

class _WebAlertsCard extends StatelessWidget {
  const _WebAlertsCard({
    required this.secureContext,
    required this.permissionDenied,
    required this.onEnable,
  });

  final bool secureContext;
  final bool permissionDenied;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final message = !secureContext
        ? 'Notifikasi web memerlukan HTTPS atau localhost.'
        : permissionDenied
        ? 'Izin notifikasi diblokir. Ubah izin situs ini melalui pengaturan browser.'
        : 'Aktifkan notifikasi dan suara alarm agar tidak melewatkan pergantian sesi. Timer harus tetap terbuka.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengingat sesi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: Theme.of(context).textTheme.bodySmall),
                  if (secureContext && !permissionDenied) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onEnable,
                      child: Text(
                        WebSessionAlerts.notificationGranted
                            ? 'Aktifkan suara alarm'
                            : 'Aktifkan notifikasi & suara',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
