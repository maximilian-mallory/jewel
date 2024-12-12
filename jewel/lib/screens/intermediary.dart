import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
// new
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;

import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/models/external_user.dart';
import 'package:jewel/models/internal_user.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:woosmap_flutter/woosmap_flutter.dart';

class Intermediary extends StatefulWidget{
  final CalendarLogic calendarLogic;
  const Intermediary({super.key, required this.calendarLogic});

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
    signIn();
  }

  Future<void> signIn() async {
  widget.calendarLogic.currentUser = await handleSignIn();
  widget.calendarLogic.calendarApi = await createCalendarApiInstance(widget.calendarLogic);
  // After signing in, navigate to the next screen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => HomeScreen(calendarLogic: widget.calendarLogic, initialIndex: 1,), // Use named parameter
    ),
  );
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
  Widget build(BuildContext context)  {
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