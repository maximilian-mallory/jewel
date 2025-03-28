import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;
import 'package:jewel/google/calendar/calendar_logic.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/google/maps/google_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("BACKGROUND TASK: Starting $task");
    
    try {
      switch (task) {
        case "Calendar scheduler task":
          print("BACKGROUND TASK: About to send start notification");
          await sendBasicNotification("Task started", "Checking for events");
          print("BACKGROUND TASK: About to check events");
          await checkUpcomingEvents();
          print("BACKGROUND TASK: Finished checking events");
          break;
      }
      print("BACKGROUND TASK: Successfully completed");
      return Future.value(true);
    } catch (e) {
      print("BACKGROUND TASK ERROR: $e");
      await sendBasicNotification("Task Error", "Error: ${e.toString().substring(0, 50)}");
      return Future.value(false);
    }
  });
}

void registerBackgroundTasks() {
  // Initialize notifications first
  initializeNotifications();
  print("registerBackgroundTasks tasks called");
  // Then register the background tasks
  Workmanager().initialize(callbackDispatcher);

  Workmanager().registerPeriodicTask(
    "calendar_reminder_task",
    "Calendar scheduler task",
    frequency: Duration(minutes: 15), 
    initialDelay: Duration(seconds: 10),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    backoffPolicy: BackoffPolicy.linear,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
}

Future<void> initializeNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  const AndroidNotificationChannel debugChannel = AndroidNotificationChannel(
    'debug_channel',
    'Debug Notifications',
    description: 'Channel for debug notifications',
    importance: Importance.max,
  );
  
  const AndroidNotificationChannel calendarChannel = AndroidNotificationChannel(
    'calendar_reminders',
    'Calendar Reminders',
    description: 'Channel for calendar reminders',
    importance: Importance.max,
  );

  // Create notification channels
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(debugChannel);
      
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(calendarChannel);
      
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );
}

Future<void> checkUpcomingEvents() async {
  try {
    // Log that we're starting the event check
    await sendBasicNotification(
      "Background Check",
      "Checking calendar events"
    );
    
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('calendar_access_token');
    
    if (accessToken != null) {
      try {
        // Create HTTP client with the token
        final httpClient = GoogleHttpClient(accessToken);
        final calendarApi = gcal.CalendarApi(httpClient);
        
        // Get the current date at midnight local time for query
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(Duration(days: 1));
        
        // Fetch events for today
        final calEvents = await calendarApi.events.list(
          'primary',
          timeMin: startOfDay.toUtc(),
          timeMax: endOfDay.toUtc(),
          singleEvents: true,
          orderBy: 'startTime',
        );
        
        // Create a calendar logic instance and populate with events
        final calendarLogic = CalendarLogic()..calendarApi = calendarApi;
        calendarLogic.events = calEvents.items ?? [];
        
        // Now we can use your helper method to get arrival times
        final arrivalTimes = getArrivalTime(calendarLogic);
        
        await sendBasicNotification(
          "Events Found",
          "Found ${arrivalTimes.length} events for today"
        );
        
        // Check which events are starting in about an hour
        // In your checkUpcomingEvents function:

// Check which events are starting soon
for (final arrival in arrivalTimes) {
  final diff = arrival.difference(now);
  final minutesToEvent = diff.inMinutes;
  
  // Skip past events or events more than 60 minutes away
  if (minutesToEvent < 0 || minutesToEvent > 60) {
    continue;
  }
  
  final hour = arrival.hour.toString().padLeft(2, '0');
  final minute = arrival.minute.toString().padLeft(2, '0');
  
  // IMPROVED TIME RANGES: This is the key fix
  // We use "falling through" ranges to ensure events don't get missed
  String message;
  String notificationId;
  
  // Event is about 1 hour away
  if (minutesToEvent > 45 && minutesToEvent <= 60) {
    message = "Your event starts in about 1 hour at $hour:$minute";
    notificationId = "upcoming-60min-${arrival.millisecondsSinceEpoch}";
    await sendNotification(notificationId, "Upcoming Event", message);
  } 
  // Event is about 45 minutes away
  else if (minutesToEvent > 30 && minutesToEvent <= 45) {
    message = "Your event starts in about 45 minutes at $hour:$minute";
    notificationId = "upcoming-45min-${arrival.millisecondsSinceEpoch}";
    await sendNotification(notificationId, "Upcoming Event", message);
  }
  // Event is about 30 minutes away
  else if (minutesToEvent > 15 && minutesToEvent <= 30) {
    message = "Your event starts in about 30 minutes at $hour:$minute";
    notificationId = "upcoming-30min-${arrival.millisecondsSinceEpoch}";
    await sendNotification(notificationId, "Upcoming Event", message);
  }
  // Event is about 15 minutes away
  else if (minutesToEvent <= 15) {
    message = "Your event starts in about 15 minutes at $hour:$minute";
    notificationId = "upcoming-15min-${arrival.millisecondsSinceEpoch}";
    await sendNotification(notificationId, "Upcoming Event", message);
  }

  // Add explicit logging
  print("Event at $hour:$minute, $minutesToEvent minutes from now, notification sent");
}
      } catch (e) {
        print('Calendar API error: $e');
        await sendBasicNotification(
          "API Error", 
          "Error with Calendar API: ${e.toString().substring(0, 50)}..."
        );
      }
    } else {
      await sendBasicNotification(
        "No Token",
        "Access token not found"
      );
    }
  } catch (e) {
    print('Error in task: $e');
    await sendBasicNotification(
      "Task Error", 
      "Background task error: ${e.toString().substring(0, 50)}..."
    );
  }
}


Future<void> sendNotification(String id, String title, String body) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'calendar_reminders',
    'Calendar Reminders',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    autoCancel: true,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  int notificationId = id.hashCode.abs() % 100000;
  print("Sending event notification with ID: $notificationId, title: $title, body: $body");

  await flutterLocalNotificationsPlugin.show(
    notificationId,
    title,
    body,
    platformChannelSpecifics,
  );
}
Future<void> sendBasicNotification(String title, String body) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'debug_channel',
    'Debug Notifications',
    importance: Importance.max,
     priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    title.hashCode,
    title,
    body,
    platformChannelSpecifics,
  );
}

class GoogleHttpClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }
}