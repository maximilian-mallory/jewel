import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:jewel/notifications.dart';
import 'package:workmanager/workmanager.dart';

// Add this background port name
const String BACKGROUND_PORT_NAME = "background_task_port";

@pragma('vm:entry-point')
void callbackDispatcher() {
  // Ensure the callback runs as soon as possible
  final receivePort = ReceivePort();
  IsolateNameServer.registerPortWithName(receivePort.sendPort, BACKGROUND_PORT_NAME);
  
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
        await sendBasicNotification("Task Error", "Error: ${e.toString().substring(0, 50)}");
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
    
    print("registerBackgroundTasks called");
    
    // Then register the background tasks
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false  // Enable this for better debugging
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
    print("Registered periodic background task");
    
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
    print("Registered one-time background task");
    
    // Show a notification to confirm tasks were registered
    /*await sendBasicNotification(
      "Background Tasks", 
      "Calendar reminders registered successfully"
    );*/
  } catch (e) {
    print("ERROR registering background tasks: $e");
    await sendBasicNotification(
      "Registration Error", 
      "Failed to register tasks: ${e.toString().substring(0, 50)}"
    );
  }
}