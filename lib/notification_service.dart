import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// 📌 Initialize Notifications
  static void initialize() {
    var androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosSettings = DarwinInitializationSettings();
    var settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    _notificationsPlugin.initialize(settings, onDidReceiveNotificationResponse: (response) {
      if (response.payload == "history") {
        // Open history page (Handled in Main UI)
      }
    });
  }

  /// 📌 Show Notification
  static Future<void> showNotification(String title, [String? body, String? payload]) async {
    var androidDetails = AndroidNotificationDetails("channelId", "channelName",
        importance: Importance.max, priority: Priority.high);
    var iOSDetails = DarwinNotificationDetails();
    var notificationDetails = NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await _notificationsPlugin.show(0, title, body, notificationDetails, payload: payload);
  }
}
