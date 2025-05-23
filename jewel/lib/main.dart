import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jewel/google/auth/auth_gate.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:jewel/screens/firebase_login_screen.dart';
import 'package:jewel/screens/graph_login.dart';
import 'package:jewel/screens/intermediary.dart';
import 'package:jewel/screens/mslogin.dart';
import 'package:jewel/screens/oauth_redirect_screen.dart';
import 'package:jewel/screens/test_screen1.dart';
import 'package:jewel/utils/platform/background_deployer.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:jewel/utils/platform/notifications.dart';
import 'package:flutter/foundation.dart';
import '/utils/fake_ui.dart' if (dart.library.html) '/utils/real_ui.dart' as ui;
import "package:universal_html/html.dart" as html;
import 'package:jewel/google/maps/google_maps_calculate_distance.dart';
import 'package:jewel/google/calendar/g_g_merge.dart';
import 'package:jewel/google/calendar/mode_toggle.dart';
import 'package:jewel/utils/app_themes.dart';
import 'package:jewel/google/calendar/calendar_logic.dart';
import 'package:jewel/utils/text_style_notifier.dart';
import 'package:jewel/screens/join_groups.dart';
import 'package:jewel/user_groups/user_group.dart';
import 'package:jewel/user_groups/user_group_provider.dart';
import 'package:jewel/widgets/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables, web app needs to have an assets folder
  if (kIsWeb) {
    await dotenv.load(fileName: "assets/.env");
  } else {
    await dotenv.load(fileName: ".env");
  }

  if (!kIsWeb) {
    // Request permissions first
      PermissionStatus status = await Permission.notification.request();
    
      // Check if permission was granted
      if (status.isGranted) {
        // Use try-catch to prevent crashes during registration
        try {
          await registerBackgroundTasks();
        } catch (e) {
          print("Failed to register background tasks: $e");
        }
      } else {
        print("Notification permission denied. Background tasks may not work properly.");
      }
    
  }
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  /*await NotificationController.initializeLocalNotifications();
  NotificationController.createNewNotification();*/

  // Register the view type for the map
  if (kIsWeb) {
    ui.platformViewRegistry.registerViewFactory('map', (int viewId) {
      return html.DivElement()..id = 'map';
    });
  }

  runApp(
    MultiProvider(
      // providers allow us to have app level access to objects
      providers: [
        ChangeNotifierProvider(
          // for the auth object
          create: (_) => JewelUser(),
        ),
        ChangeNotifierProvider(
          // keeps track of what screen the user is on
          create: (_) => SelectedIndexNotifier(1), // default index
        ),
        ChangeNotifierProvider(
          // keeps track of what calendar mode the user is in
          create: (context) => ModeToggle(),
        ),
        ChangeNotifierProvider(
          // provides the selected text style for the app
          create: (_) => ThemeStyleNotifier(),
        ),
        ChangeNotifierProvider(
          // Keeps track of what calendar mode the user is in
          create: (context) => ModeToggle(),
        ),
        ChangeNotifierProvider(
          // Provides access to user groups
          create: (_) => UserGroupProvider(),
        ),
        ChangeNotifierProvider(
          // Add the SettingsProvider here
          create: (_) => SettingsProvider(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final List<CalendarLogic> calendarLogicList = []; // listener for API calls
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // _checkAndLogout();
    return Consumer<ThemeStyleNotifier>(
      builder: (context, textStyleNotifier, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Jewel',
          theme: AppThemes.lightThemeWithTextStyle(textStyleNotifier.textStyle),
          darkTheme:
              AppThemes.darkThemeWithTextStyle(textStyleNotifier.textStyle),
          themeMode: ThemeMode.system,
          home: AuthGate(),
        );
      },
    );
  }
}

Future<void> _checkAndLogout() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuth.instance.signOut();  // Log out if signed in
      // Optionally, clear secure storage if needed
      final storage = FlutterSecureStorage();
      await storage.deleteAll();
      // Navigate to login screen if needed
      // This can be done in a different place depending on your flow
    }
  }