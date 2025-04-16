import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jewel/google/maps/google_routes.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:jewel/utils/platform/notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

// Add this background port name
const String BACKGROUND_PORT_NAME = "background_task_port";

@pragma('vm:entry-point')
void callbackDispatcher() {
  // Ensure the callback runs as soon as possible
  final receivePort = ReceivePort();
  IsolateNameServer.registerPortWithName(
      receivePort.sendPort, BACKGROUND_PORT_NAME);

  // Execute tasks with proper handling for background execution
  Workmanager().executeTask((task, inputData) async {
    print("BACKGROUND TASK: Starting $task at ${DateTime.now()}");

    // Use a completer to manage task completion
    Completer<bool> completer = Completer<bool>();

    // Set a timeout in case the task hangs
    Timer(Duration(minutes: 3), () {
      if (!completer.isCompleted) {
        print("BACKGROUND TASK: Task timed out");
        completer.complete(true); // Complete with success to avoid retries
      }
    });
    try {
      //switch statement used to determine which task to run
      // This is where you can add more tasks in the future
      switch (task) {
        case "Calendar scheduler task":
          //print("BACKGROUND TASK: About to send start notification");
          //await sendBasicNotification("Background Task", "Checking for upcoming events");
          //print("BACKGROUND TASK: About to check events");
          await checkUpcomingEvents();
          //print("BACKGROUND TASK: Finished checking events");
          break;
        case "Time checker task":
          //print("BACKGROUND TASK: About to check times between events");
          try {
           List<Marker> markerCoordinates = await _decodeData();
            // Step-by-step debugging
            //print("BACKGROUND TASK: Calling checkUserHasEnoughTime()");
            List<Map<String, dynamic>> eventStatus;
            try {
              eventStatus = await checkUserHasEnoughTime(markerCoordinates, inputData?['apiKey']);
              //print("BACKGROUND TASK: checkUserHasEnoughTime returned: $eventStatus");
            } catch (e) {
              print("BACKGROUND TASK: Error in checkUserHasEnoughTime(): $e");
              await sendBasicNotification("Time Check Error",
                  "Failed to check time between events: $e");
              // Continue execution without failing the task
              eventStatus = [];
            }

            if (eventStatus.isEmpty) {
              //print("BACKGROUND TASK: No events to check or empty result");
              await sendBasicNotification("Background Task",
                  "No events to check or no results returned");
            } else {
              for (int i = 0; i < eventStatus.length; i++) {
                if (eventStatus[i]["status"]==false) {
                  //print("BACKGROUND TASK: Not enough time between events ${i + 1} and ${i + 2}");
                  await sendBasicNotification("Time Warning",
                      "Not enough time between events: ${eventStatus[i]['eventName']} and ${eventStatus[i]['nextEventName']}");
                } else {
                  //print("BACKGROUND TASK: Enough time between events ${i + 1} and ${i + 2}");
                  // do nothing
                }
              }
            }
          } catch (e) {
            //print("BACKGROUND TASK: Critical error in time checker: $e");
            await sendBasicNotification("Background Task Error",
                "Critical error checking time between events: $e");
          }
          break;
        default:
          print("BACKGROUND TASK: Unknown task $task");
          break;
      }

      if (!completer.isCompleted) {
        print("BACKGROUND TASK: Successfully completed");
        completer.complete(true);
      }
    } catch (e) {
      print("BACKGROUND TASK ERROR: $e");
      try {
        await sendBasicNotification(
            "Task Error", "Error: ${e.toString().substring(0, 50)}");
      } catch (_) {
        // Ignore errors from the error notification
      }

      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  });
}

Future<void> registerBackgroundTasks() async {
  try {
    // Initialize notifications first with retry logic
    bool notificationsInitialized = false;
    int retryCount = 0;
    String? apiKey = dotenv.env['GOOGLE_MAPS_KEY'];
    while (!notificationsInitialized && retryCount < 3) {
      try {
        await initializeNotifications();
        notificationsInitialized = true;
        print("Notifications initialized successfully");
      } catch (e) {
        retryCount++;
        print("Failed to initialize notifications (attempt $retryCount): $e");
        await Future.delayed(Duration(seconds: 1));
      }
    }

    if (!notificationsInitialized) {
      print("WARNING: Failed to initialize notifications after multiple attempts");
    }

    //print("registerBackgroundTasks called");

    // Then register the background tasks
    await Workmanager().initialize(callbackDispatcher,
        isInDebugMode: false // Enable this for better debugging
        );

    // Cancel any existing tasks to avoid conflicts
    await Workmanager().cancelAll();
    print("Cancelled existing background tasks");

    // Register periodic task with improved settings
    await Workmanager().registerPeriodicTask(
      "calendar_reminder_task",
      "Calendar scheduler task",
      frequency: Duration(minutes: 15),
      initialDelay: Duration(seconds: 30),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
    //print("Registered periodic background task for pre event reminders");
    await Workmanager().registerPeriodicTask(
      "time_checker_task",
      "Time checker task",
      frequency: Duration(minutes: 15),
      initialDelay: Duration(seconds: 30),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'apiKey': apiKey,
      }
    );
    //print("Registered periodic background task for checking times between events");

    // Add a one-time task for immediate testing
    await Workmanager().registerOneOffTask(
      "calendar_check_immediate",
      "Calendar scheduler task",
      initialDelay: Duration(seconds: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
      ),
    );
    //print("Registered one-time background task for pre event reminders");
    await Workmanager().registerOneOffTask(
      "Timer_check_immediate",
      "Time checker task",
      initialDelay: Duration(seconds: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
      ),
      inputData: {
        'apiKey': apiKey,
      }
    );
  } catch (e) {
    print("ERROR registering background tasks: $e");
    await sendBasicNotification("Registration Error",
        "Failed to register tasks: ${e.toString().substring(0, 50)}");
  }
}

Future<List<Marker>> _decodeData () async  {
  List<Marker> markerCoordinates = [];
  final prefs = await SharedPreferencesAsync();
  final markersEncoded = await prefs.getString('marker_list');
  if (markersEncoded != null) {
    //print("Markers loaded from SharedPreferences: $markersEncoded");
    final List<dynamic> decodedData = jsonDecode(markersEncoded);
    //print("DEBUG: Decoded data: $decodedData");
    List<Marker> markerData = decodedData
      .map((data) => Marker(
        markerId: MarkerId(data['id']),
        position: LatLng(data['lat'], data['lng']),
      ))
      .toList();
     markerCoordinates = markerData;
     print("Debug: Marker coordinates loaded: $markerCoordinates");
  } 
  else {
      print("No markers found in SharedPreferences");
  } 
      //print("Loaded marker coordinates for background task: $markerCoordinates");
      return markerCoordinates;
}