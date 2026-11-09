import 'dart:async';

import 'package:flutter/services.dart';

Timer? _alarmTimer;

bool get isSecureContext => false;
bool get notificationGranted => false;
bool get notificationDenied => false;
bool get isReady => false;

Future<bool> enable() async => false;

void notifySessionComplete({required String title, required String body}) {}

Future<void> startAlarm() async {
  if (_alarmTimer != null) return;
  await SystemSound.play(SystemSoundType.alert);
  _alarmTimer = Timer.periodic(
    const Duration(milliseconds: 700),
    (_) => unawaited(SystemSound.play(SystemSoundType.alert)),
  );
}

void stopAlarm() {
  _alarmTimer?.cancel();
  _alarmTimer = null;
}
