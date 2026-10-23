import 'dart:js_interop';

import 'package:web/web.dart' as web;

class WebNotificationService {
  static bool get isPermissionGranted =>
      web.Notification.permission == 'granted';

  static Future<bool> requestPermission() async {
    final permission = await web.Notification.requestPermission().toDart;
    return permission.toDart == 'granted';
  }

  static void showNotification({required String title, required String body}) {
    if (!isPermissionGranted) return;
    web.Notification(title, web.NotificationOptions(body: body));
  }
}
