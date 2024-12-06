import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
// new
import 'package:flutter/material.dart';
import 'package:jewel/google/auth/home.dart';
import 'package:jewel/models/external_user.dart';
import 'package:jewel/models/internal_user.dart';
import 'package:woosmap_flutter/woosmap_flutter.dart';


class Intermediary extends StatefulWidget{
  const Intermediary({super.key});

  @override
  _IntermediaryScreenState createState() => _IntermediaryScreenState();  
}

class _IntermediaryScreenState extends State<Intermediary> {
  
bool isLoading = true; // To show loading indicator



 @override
  void initState() {
    super.initState();
  }

  Future<void> createExternalUserInDatabase() async {
    User? user =FirebaseAuth.instance.currentUser;
    
    var email_Address;
    if (user != null){
      for (final providerProfile in user.providerData) {
        email_Address = providerProfile.email;
      }
    }

    StoreOpeningHoursPeriod dailyHours = StoreOpeningHoursPeriod();

    dailyHours.start = "9:00";
    dailyHours.end = "17:00";
    dailyHours.allDay = false;
    
    List<StoreOpeningHoursPeriod> hoursList = List<StoreOpeningHoursPeriod>.filled(7, dailyHours);

   
    StoreWeeklyOpeningHoursPeriod weeklyHours = StoreWeeklyOpeningHoursPeriod(hours: hoursList,isSpecial: false);
    
    if (user != null){
      ExternalUser storeInDatabase = ExternalUser(email: email_Address, userType: "contractor", companyName: "Null Contracting", openHours: weeklyHours, title: "contractor", cause: "external contractor", calendars: [{}]);
      print(storeInDatabase.toJson());
      await FirebaseFirestore.instance
          .collection('people') // Collection name
          .doc('external') // Document name
          .set(storeInDatabase.toJson());
    }
  }
  


  Future<void> createInternalUserInDatabase() async {
    final user =FirebaseAuth.instance.currentUser;
    var email_Address;
    if (user != null){
      for (final providerProfile in user.providerData) {
        email_Address = providerProfile.email;
      }
    }
    
    StoreOpeningHoursPeriod dailyHours = StoreOpeningHoursPeriod();

    dailyHours.start = "9:00";
    dailyHours.end = "17:00";
    dailyHours.allDay = false;
    
    List<StoreOpeningHoursPeriod> hoursList = List<StoreOpeningHoursPeriod>.filled(7, dailyHours);

   
    StoreWeeklyOpeningHoursPeriod weeklyHours = StoreWeeklyOpeningHoursPeriod(hours: hoursList,isSpecial: false);
    
    if (user != null){
      InternalUser storeInDatabase = InternalUser(email: email_Address, userType: "internal", internalID: "12345678", openHours: weeklyHours, title: "employee", calendars: [{}]);
      print(storeInDatabase.toJson());
      await FirebaseFirestore.instance
          .collection('people') // Collection name
          .doc('internal') // Document name
          .set(storeInDatabase.toJson());

    }

  }

  Future<bool> searchForUser() async{
    final user = FirebaseAuth.instance.currentUser;
    var email;
    if (user != null){
      for (final providerProfile in user.providerData) {
        email = providerProfile.email;
      }
    }
    final databaseSearch = await FirebaseFirestore.instance;
    final externalRef = databaseSearch.collection("external_users");
    final internalRef = databaseSearch.collection("internal_users");
    bool userFound = true;
    
    int numUsers = 0;
    await internalRef.where("email", isEqualTo: email).get().then((QuerySnapshot queryInternal){
      print(queryInternal.size);
      numUsers = queryInternal.size;
    });


    if (numUsers == 0){
      userFound = false;
      print("user not found in internal_users");
    }
    
    else {
      userFound = true;
      print("user found in internal_users");
      
    }
    if (userFound == false){
      await externalRef.where("email", isEqualTo: email).get().then((QuerySnapshot queryInternal){
        print(queryInternal.size);
        numUsers = queryInternal.size;
      });
      if (numUsers == 0){
        userFound = false;
        print("user not found in external_users");
      }

      else{
        userFound = true;
        print("user found in internal_users");
      }
    }

    return userFound;
  }

  Future<void> methodProcess()async{
    Future<bool> foundUser = searchForUser();
    if(await foundUser){
      print("user found in database");
      pushToHomeScreen();
    }

    else{
      print("this user is not in the database and is not authorized to proceed");
    }
  
  }

  Future<void> pushToHomeScreen()async {
    Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
  }


  @override
  Widget build(BuildContext context) {
    methodProcess();
    return Scaffold(
      body: 
        Center(
          child: Column(
            children: [Image.asset("assets/Jewel_Logo.jpg",width: 200,height: 200,),
            Text("Searching for users"),
            ],
        ),
      ),
    );
  }
}


Future<Map<String, dynamic>> createCalendarsList() async {
  //get email address of current user
  final user =FirebaseAuth.instance.currentUser;
  var email_Address;
  if (user != null){
    for (final providerProfile in user.providerData) {
      email_Address = providerProfile.email;
    }    
  }

  //database search set up
  final databaseSearch = await FirebaseFirestore.instance;
  final calendarsRef = databaseSearch.collection("calendar_prm");
  Map<String, dynamic> storedCalendars = {};


  // search through the docs for the document with the name of the user and store
  // the data contained in the document
  await calendarsRef.doc(email_Address).get().then((DocumentSnapshot doc){
    storedCalendars = doc.data() as Map<String, dynamic>;
  },

  );

  // setup of the second database search
  final CollectionReference<Map<String, dynamic>> calendarsTwoRef = databaseSearch.collection("calendar");
  Map<String,dynamic> finalEvents = {};
  Map<String,dynamic> storedEvents = {};
  // for each map string dynamic search the "calendar" collection for files containing the correct id and email
  // given from the previous search
  storedCalendars.forEach(
    (calendarId, emailName) => calendarsTwoRef.where("id" ,isEqualTo: calendarId)
    .where("owner", isEqualTo:emailName).get().then((DocumentSnapshot doc){
      //store the data from the snapshot in StoredEvents and add them to final events
      storedEvents = doc.data() as Map<String,dynamic>;
      finalEvents.addAll(storedEvents);
    
  
    } as FutureOr Function(QuerySnapshot<Map<String, dynamic>> value)
    )


  );
  
  return finalEvents;
}