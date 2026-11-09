import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.AudioContext? _audioContext;
Timer? _alarmTimer;
web.OscillatorNode? _activeOscillator;
var _alarmToneIndex = 0;

bool get isSecureContext => web.window.isSecureContext;
bool get notificationGranted =>
    isSecureContext && web.Notification.permission == 'granted';
bool get notificationDenied =>
    isSecureContext && web.Notification.permission == 'denied';
bool get isReady => notificationGranted && _audioContext?.state == 'running';

Future<bool> enable() async {
  if (!isSecureContext) return false;

  final permissionRequest = web.Notification.requestPermission().toDart;
  final audioContext = _audioContext ??= web.AudioContext();
  final audioResume = audioContext.resume().toDart;
  final permission = await permissionRequest;
  await audioResume;
  return permission.toDart == 'granted';
}

void notifySessionComplete({required String title, required String body}) {
  if (!notificationGranted) return;
  web.Notification(
    title,
    web.NotificationOptions(body: body, tag: 'pomodoro-session'),
  );
}

Future<void> startAlarm() async {
  final audioContext = _audioContext;
  if (audioContext == null) return;
  if (audioContext.state != 'running') {
    await audioContext.resume().toDart;
  }

  if (_alarmTimer != null) return;
  _playAlarmTone(audioContext);
  _alarmTimer = Timer.periodic(
    const Duration(milliseconds: 300),
    (_) => _playAlarmTone(audioContext),
  );
}

void stopAlarm() {
  _alarmTimer?.cancel();
  _alarmTimer = null;
  _activeOscillator?.stop();
  _activeOscillator = null;
}

void _playAlarmTone(web.AudioContext audioContext) {
  final startAt = audioContext.currentTime;
  final oscillator = audioContext.createOscillator();
  final gain = audioContext.createGain();
  _activeOscillator = oscillator;
  oscillator.type = 'square';
  oscillator.frequency.value = _alarmToneIndex.isEven ? 880 : 660;
  _alarmToneIndex++;
  gain.gain
    ..setValueAtTime(0, startAt)
    ..setValueAtTime(0.12, startAt + 0.02)
    ..setValueAtTime(0, startAt + 0.24);
  oscillator.connect(gain);
  gain.connect(audioContext.destination);
  oscillator
    ..start(startAt)
    ..stop(startAt + 0.26);
  Timer(const Duration(milliseconds: 300), () {
    if (identical(_activeOscillator, oscillator)) {
      _activeOscillator = null;
    }
  });
}
