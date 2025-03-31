import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:jewel/firebase_ops/user_groups.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/models/external_user.dart';
import 'package:jewel/models/internal_user.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:jewel/utils/background_deployer.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:woosmap_flutter/woosmap_flutter.dart';
import 'package:jewel/google/calendar/calendar_logic.dart';
import 'package:jewel/google/calendar/google_sign_in.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
/*
  This widget class returns the loading screen. The loading screen opens when the app launches, forcing the user to log in
*/
class Intermediary extends StatefulWidget{
  const Intermediary({super.key,});

  @override
  _IntermediaryScreenState createState() => _IntermediaryScreenState();  
}
class _IntermediaryScreenState extends State<Intermediary> {
  
bool isLoading = true; // To show loading indicator

 @override
  void initState() {
    super.initState();
    // googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async { // Auth State listener
    //   setState(() {
    //     widget.calendarLogic.currentUser = account;
    //     widget.calendarLogic.isAuthorized = account != null;
    //   });
    // });
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    print('[Firebase Auth] Firebase user successfully signed in: ${firebaseUser!.email}');
    signIn(); //force signin
  }

  Future<void> signIn() async {
    JewelUser jewelUser = Provider.of<JewelUser>(context, listen: false);
    CalendarLogic calendarLogic = CalendarLogic();
    calendarLogic.currentUser = await handleSignIn(jewelUser); // googleapi.dart
    calendarLogic.calendarApi = await createCalendarApiInstance(calendarLogic); // create api instance associated with the account

    if (calendarLogic.currentUser != null) {
    final auth = await calendarLogic.currentUser!.authentication;
    final accessToken = auth.accessToken;
    if (accessToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('calendar_access_token', accessToken);
      print("Access token saved for background tasks: ${accessToken.substring(0, 10)}...");
    }
  }

    jewelUser.addCalendarLogic(calendarLogic);
    jewelUser.updateUserGroups(await getUsersGroups(jewelUser.email!));
    print('[CHANGE PROVIDER] Jewel User updated: ${jewelUser.email}');
    // After signing in, navigate to the next screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomeScreen(initialIndex: 1)),
      (Route<dynamic> route) => false, // Removes all previous routes
    );
  }

  Future<JewelUser> getCurrentJewelUser() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    return JewelUser.fromFirebaseUser(
      firebaseUser!,
    );
 // User is not logged in
  }

  Future<void> createExternalUser() async {
    User? user =FirebaseAuth.instance.currentUser;
    
    StoreOpeningHoursPeriod dailyHours = StoreOpeningHoursPeriod();

    dailyHours.start = "9:00";
    dailyHours.end = "17:00";
    dailyHours.allDay = false;
    
    List<StoreOpeningHoursPeriod> hoursList = List<StoreOpeningHoursPeriod>.filled(7, dailyHours);

   
    StoreWeeklyOpeningHoursPeriod weeklyHours = StoreWeeklyOpeningHoursPeriod(hours: hoursList,isSpecial: false);
    
    if (user != null){
      ExternalUser storeInDatabase = ExternalUser(firebaseUser: user, userType: "contractor", companyName: "Null Contracting", openHours: weeklyHours, title: "contractor", cause: "external contractor", calendars: [{}]);
      print(storeInDatabase.toJson());
      await FirebaseFirestore.instance
          .collection('people') // Collection name
          .doc('external') // Document name
          .set(storeInDatabase.toJson());
    }
  }
  
  Future<void> createInternalUser() async {
    final user =FirebaseAuth.instance.currentUser;
    
    StoreOpeningHoursPeriod dailyHours = StoreOpeningHoursPeriod();

    dailyHours.start = "9:00";
    dailyHours.end = "17:00";
    dailyHours.allDay = false;
    
    List<StoreOpeningHoursPeriod> hoursList = List<StoreOpeningHoursPeriod>.filled(7, dailyHours);

    StoreWeeklyOpeningHoursPeriod weeklyHours = StoreWeeklyOpeningHoursPeriod(hours: hoursList,isSpecial: false);
    
    if (user != null){
      InternalUser storeInDatabase = InternalUser(firebaseUser: user, userType: "internal", internalID: "12345678", openHours: weeklyHours, title: "employee", calendars: [{}]);
      print(storeInDatabase.toJson());
      await FirebaseFirestore.instance
          .collection('people') // Collection name
          .doc('internal') // Document name
          .set(storeInDatabase.toJson());

    }

  }

  Future<bool> searchForUser() async{
    final user =FirebaseAuth.instance.currentUser;
    final databaseSearch = FirebaseFirestore.instance;
    final externalRef = databaseSearch.collection("people");
    final internalRef = databaseSearch.collection("people");

    final queryInternal = internalRef.where("firebaseUser", isEqualTo: user);

    return true;
  
  }
  
  @override
  Widget build(BuildContext context)  { // logo
  return Scaffold(
    body: Center(
      child: Image.asset(
         'assets/images/jewel205.png', 
        fit: BoxFit.contain,
      ),
    ),
  );
}
}