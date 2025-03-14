import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jewel/google/auth/auth_gate.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:jewel/screens/firebase_login_screen.dart';
import 'package:jewel/screens/intermediary.dart';
import 'package:jewel/screens/test_screen1.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:jewel/notifications.dart';
import 'package:flutter/foundation.dart';
import '/utils/fake_ui.dart' if (dart.library.html) '/utils/real_ui.dart' as ui;
import "package:universal_html/html.dart" as html;
import 'package:jewel/google/maps/google_maps_calculate_distance.dart';
import 'package:jewel/google/calendar/g_g_merge.dart';
import 'package:jewel/google/calendar/mode_toggle.dart';
import 'package:jewel/utils/app_themes.dart';
import 'package:jewel/utils/text_style_notifier.dart';
import 'package:jewel/screens/user_group_screen.dart';
import 'package:jewel/user_groups/user_group.dart';
import 'package:jewel/user_groups/user_group_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables, web app needs to have an assets folder
  if (kIsWeb) {
    await dotenv.load(fileName: "assets/.env");
  } else {
    await dotenv.load(fileName: ".env");
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
          create: (_) => TextStyleNotifier(),
        ),
        ChangeNotifierProvider(
          // Keeps track of what calendar mode the user is in
          create: (context) => ModeToggle(),
        ),
        ChangeNotifierProvider(
          // Provides access to user groups
          create: (_) => UserGroupProvider(),
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
    return Consumer<TextStyleNotifier>(
      builder: (context, textStyleNotifier, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Jewel',
          theme: MyAppThemes.lightThemeWithTextStyle(textStyleNotifier.textStyle),
          darkTheme: MyAppThemes.darkThemeWithTextStyle(textStyleNotifier.textStyle),
          themeMode: ThemeMode.system,
          home: AuthGate(),
        );
      },
    );
  }
}