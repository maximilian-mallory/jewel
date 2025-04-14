import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;
import 'package:jewel/google/calendar/calendar_logic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import 'package:shared_preferences/shared_preferences.dart';

// Global plugin instance for use across the app
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Initialize notification settings and request permissions
Future<void> initializeNotifications() async {
  try {
    // First check notification permission
    PermissionStatus status = await Permission.notification.status;
    if (!status.isGranted) {
      status = await Permission.notification.request();
      if (!status.isGranted) {
        print("NOTIFICATION ERROR: Permission denied after request");
        return;
      }
    }
    print("NOTIFICATION: Permission granted");

    // Define notification channels
    const AndroidNotificationChannel debugChannel = AndroidNotificationChannel(
      'debug_channel',
      'Debug Notifications',
      description: 'Channel for debug notifications',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      // Make sure notifications are shown when app is in background
      showBadge: true,
    );

    const AndroidNotificationChannel calendarChannel =
        AndroidNotificationChannel(
      'calendar_reminders',
      'Calendar Reminders',
      description: 'Channel for calendar reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      // Make sure notifications are shown when app is in background
      showBadge: true,
    );

    // Create notification channels
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      print("NOTIFICATION: Creating notification channels");
      await androidImplementation.createNotificationChannel(debugChannel);
      await androidImplementation.createNotificationChannel(calendarChannel);

      // Verify channels were created
      final areEnabled = await androidImplementation.areNotificationsEnabled();
      print("NOTIFICATION: Channels enabled check: $areEnabled");
    } else {
      print("NOTIFICATION ERROR: Could not get Android implementation");
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (details) {
      print("Notification clicked: ${details.id}");
    });

    print("NOTIFICATION: Initialization complete");
  } catch (e) {
    print("NOTIFICATION ERROR: Failed to initialize: $e");
  }
}

// Send a notification for calendar events
Future<void> sendNotification(String id, String title, String body) async {
  try {
    print("NOTIFICATION: Sending event notification: $title | $body | ID: $id");

    // These settings are critical for reliable background notifications
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'calendar_reminders',
      'Calendar Reminders',
      channelDescription: 'Channel for calendar reminders',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      ticker: 'calendar event',
      showWhen: true,
      enableVibration: true,
      playSound: true,
      ongoing: false, // Not persistent
      autoCancel: true,
      category:
          AndroidNotificationCategory.reminder, // Key for background delivery
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    int notificationId = id.hashCode.abs() % 100000;
    print(
        "Sending event notification with ID: $notificationId, title: $title, body: $body");

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: 'event_notification',
    );

    print(
        "NOTIFICATION: Event notification sent successfully with ID: $notificationId");
  } catch (e) {
    print("NOTIFICATION ERROR: Failed to send event notification: $e");
  }
}

// Send a basic notification for debugging
Future<void> sendBasicNotification(String title, String body) async {
  try {
    print("NOTIFICATION: Sending basic notification: $title | $body");

    // Enhanced settings for reliable background notifications
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'debug_channel',
      'Debug Notifications',
      channelDescription: 'Channel for debug notifications',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      ticker: 'debug',
      showWhen: true,
      enableVibration: true,
      playSound: true,
      category:
          AndroidNotificationCategory.message, // Key for background delivery
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Generate a unique ID for each notification
    final notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: 'basic_notification',
    );

    print("NOTIFICATION: Successfully sent notification ID: $notificationId");
  } catch (e) {
    print("NOTIFICATION ERROR: Failed to send basic notification: $e");
  }
}

// Send a test notification to verify functionality
Future<void> sendTestNotification() async {
  try {
    await sendBasicNotification("Notification Test",
        "Notifications are working at ${DateTime.now().toString().substring(0, 19)}");
    print("NOTIFICATION: Test notification sent successfully");
  } catch (e) {
    print("NOTIFICATION ERROR: Failed to send test notification: $e");
  }
}

//function for calling events before they start
//This function is called in the background task
Future<void> checkUpcomingEvents() async {
  try {
    // Log that we're starting the event check
    /*await sendBasicNotification(
      "Background Check",
      "Checking calendar events now"
    );*/

    final prefs = SharedPreferencesAsync();
    final accessToken = await prefs.getString('calendar_access_token');

    if (accessToken != null) {
      try {
        // Create HTTP client with the token and a 15-second timeout
        final httpClient = GoogleHttpClient(accessToken, timeout: 15);
        final calendarApi = gcal.CalendarApi(httpClient);

        // Get the current date at midnight local time for query
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(Duration(days: 1));

        // Fetch events for today with a timeout
        final calEvents = await httpClient.withTimeout(
            15,
            () => calendarApi.events.list(
                  'primary',
                  timeMin: startOfDay.toUtc(),
                  timeMax: endOfDay.toUtc(),
                  singleEvents: true,
                  orderBy: 'startTime',
                ));

        // Create a calendar logic instance and populate with events
        final calendarLogic = CalendarLogic()..calendarApi = calendarApi;
        calendarLogic.events = calEvents.items ?? [];

        // Skip creating a notification if no events found
        if (calendarLogic.events.isEmpty) {
          print("No events found for today");
          await sendBasicNotification(
              "No Events", "No calendar events found for today");
          return;
        }

        // Process each event directly instead of using arrival times
        for (final event in calendarLogic.events) {
          // Skip events without start times
          if (event.start?.dateTime == null) continue;

          // Get the event's start time and convert to local time if needed
          final eventStartTime = event.start!.dateTime!.toLocal();

          List<int> reminderMinutes = [60, 30, 15]; // Default reminder times

          if (event.extendedProperties?.private?['notificationTimes'] != null) {
            final reminderTimesStr =
                event.extendedProperties!.private!['notificationTimes']!;
            reminderMinutes =
                reminderTimesStr.split(',').map((s) => int.parse(s)).toList();
            reminderMinutes
                .sort(); // Sort ascending (smaller times are closer to event)
            print("DEBUG: Reminder times for event: $reminderMinutes");
          }
          // Calculate difference from now
          final diff = eventStartTime.difference(now);

          final minutesToEvent = diff.inMinutes;
          print("DEBUG: Minutes to event: $minutesToEvent");
          // Skip past events
          if (minutesToEvent < 0) {
            continue;
          }

          for (final reminderTime in reminderMinutes) {
            // Needs a 15 minute buffer because the background deployer triggers every 15 minutes or so
            // up to 5 minutes after the event starts and 10 minutes before the event starts
            if (minutesToEvent >= reminderTime - 5 &&
                minutesToEvent <= reminderTime + 10) {
              String eventName = event.summary ?? "Untitled event";
              final hour = eventStartTime.hour.toString().padLeft(2, '0');
              final minute = eventStartTime.minute.toString().padLeft(2, '0');

              String message =
                  "$eventName starts in about $minutesToEvent minutes at $hour:$minute";
              String notificationId =
                  "upcoming-${reminderTime}min-${eventStartTime.millisecondsSinceEpoch}";
              print("DEBUG: Sending notification: $message");
              await sendNotification(notificationId, "Upcoming Event", message);
              break; // Only send one notification at a time
            }
          }
        }
      } catch (e) {
        print('Calendar API error: $e');
        await sendBasicNotification("API Error",
            "Calendar API error: ${e.toString().substring(0, 50)}...");
      }
    }
  } catch (e) {
    print('Error in background task: $e');
    await sendBasicNotification("Task Error",
        "Calendar background task error: ${e.toString().substring(0, 50)}...");
  }
}

// Enhanced HttpClient with timeout capability
class GoogleHttpClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();
  final int timeout; // Timeout in seconds

  GoogleHttpClient(this._accessToken, {this.timeout = 30});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }

  // Helper to add timeouts to any Future
  Future<T> withTimeout<T>(int seconds, Future<T> Function() operation) async {
    return operation().timeout(Duration(seconds: seconds), onTimeout: () {
      throw TimeoutException('The operation timed out after $seconds seconds');
    });
  }

  // Close the client when done
  @override
  void close() {
    _client.close();
    super.close();
  }
}

Future<bool> checkNotificationPermission() async {
  try {
    // Check if the notification permission is granted
    PermissionStatus status = await Permission.notification.status;
    if (status == PermissionStatus.denied && !kIsWeb) {
      handler.openAppSettings();
    }
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  } catch (e) {
    print("Error checking notification permission: $e");
    return false;
  }
}
