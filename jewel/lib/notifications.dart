/*import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationController {
  /// Initialize local notifications
  static Future<void> initializeLocalNotifications() async {
    await AwesomeNotifications().initialize(
        null, // Use your app icon here if needed
        [
          NotificationChannel(
              channelKey: 'alerts',
              channelName: 'Alerts',
              channelDescription: 'Notification alerts',
              playSound: true,
              importance: NotificationImportance.High,
              defaultPrivacy: NotificationPrivacy.Private,
              defaultColor: Colors.deepPurple,
              ledColor: Colors.deepPurple),
        ],
        debug: true);
        startListeningNotificationEvents();
  }

  /// Request notification permission from the user
  static Future<bool> requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return isAllowed;
  }

  /// Create a new notification
  static Future<void> createNewNotification() async {
    bool isAllowed = await requestNotificationPermission();
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: createUniqueId(), // Automatically generates an ID
        channelKey: 'alerts',
        title: 'Test Notification',
        body: 'This is a simple notification body',
        notificationLayout: NotificationLayout.Default,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'SNOOZE',
          label: 'Snooze for 5 minutes',
        )
      ]
    );
  }

  static void startListeningNotificationEvents() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceived,
    );
  }

@pragma('vm:entry-point')
  static Future<void> onActionReceived(ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'SNOOZE') {
      //print('Snooze button pressed');
      // Schedule a new notification after 5 minutes (300 seconds)
      await scheduleSnoozedNotification();
    }
  }

  static Future<void> scheduleSnoozedNotification() async {
    print('Scheduling snoozed notification');
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: -1, // Automatically generates an ID
      channelKey: 'alerts',
      title: 'Snoozed Notification',
      body: 'This is your snoozed notification after 5 seconds.',
      notificationLayout: NotificationLayout.Default,
    ),
    schedule: NotificationCalendar.fromDate(
        date: DateTime.now().add(Duration(seconds: 5)), // Schedule after 5 seconds
        preciseAlarm: true,
        allowWhileIdle: true,
      ),

  );
  //print('Snoozed notification scheduled');
}
static int createUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }


}*/