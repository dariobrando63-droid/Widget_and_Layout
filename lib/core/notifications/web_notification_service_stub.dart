class WebNotificationService {
  static bool get isPermissionGranted => false;

  static Future<bool> requestPermission() async => false;

  static void showNotification({required String title, required String body}) {}
}
