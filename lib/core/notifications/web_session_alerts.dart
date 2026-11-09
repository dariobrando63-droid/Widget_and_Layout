import 'web_session_alerts_stub.dart'
    if (dart.library.js_interop) 'web_session_alerts_web.dart'
    as platform;

abstract final class WebSessionAlerts {
  static bool get isSecureContext => platform.isSecureContext;
  static bool get notificationGranted => platform.notificationGranted;
  static bool get notificationDenied => platform.notificationDenied;
  static bool get isReady => platform.isReady;

  static Future<bool> enable() => platform.enable();

  static void notifySessionComplete({
    required String title,
    required String body,
  }) => platform.notifySessionComplete(title: title, body: body);

  static Future<void> startAlarm() => platform.startAlarm();

  static void stopAlarm() => platform.stopAlarm();
}
