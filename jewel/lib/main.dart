import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:jewel/auth/auth_gate.dart';
import 'package:jewel/firebase_options.dart';
import 'package:go_router/go_router.dart';
import 'app_structure.dart';
import 'auth/app.dart';

Future<void> main() async {
   WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp(
   options: DefaultFirebaseOptions.currentPlatform,
 );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter _router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MainLayout(), // Use MainLayout
        ),
        GoRoute(
          path: '/second',
          builder: (context, state) => MainLayout(), // Use MainLayout
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false, //turns off the "dubug" banner in the top right corner
      title: 'Jewel',
      routerDelegate: _router.routerDelegate,
      routeInformationParser: _router.routeInformationParser,
      //home: const AuthGate() //commented out for the time being because it was throwing an error
    );
  }
}
