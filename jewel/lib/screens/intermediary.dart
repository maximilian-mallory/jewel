import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart'; // new
import 'package:flutter/material.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:jewel/models/external_user.dart';
import 'package:jewel/models/internal_user.dart';
import 'package:woosmap_flutter/woosmap_flutter.dart';

class Intermediary extends StatefulWidget{
  @override
  _IntermediaryScreenState createState() => _IntermediaryScreenState();  
}

class _IntermediaryScreenState extends State<Intermediary> {
  




 @override
  void initState() {
    super.initState();
  }

  void createExternalUser(){
    final user =FirebaseAuth.instance.currentUser;
    if (user != null){
    for (final providerProfile in user!.providerData){
      name = providerProfile.displayName;
      email = providerProfile.email;
    }
    StoreOpeningHoursPeriod dailyHours = new StoreOpeningHoursPeriod();

    dailyHours.start = "9:00";
    dailyHours.end = "17:00";
    dailyHours.allDay = false;
    
    List<StoreOpeningHoursPeriod> hoursList = new List<StoreOpeningHoursPeriod>.filled(7, dailyHours);

   
    StoreWeeklyOpeningHoursPeriod weeklyHours = new StoreWeeklyOpeningHoursPeriod(hours: hoursList,isSpecial: false);
   
    new ExternalUser(firebaseUser: user, userType: "contractor", companyName: "Null Contracting", openHours: weeklyHours, title: "contractor", cause: "external contractor", calendars: [{}]);
  }
  }


  void createInternalUser(){
    final user =FirebaseAuth.instance.currentUser;
    if (user != null){
    for (final providerProfile in user!.providerData){
      name = providerProfile.displayName;
      email = providerProfile.email;
    }
    
    StoreOpeningHoursPeriod dailyHours = new StoreOpeningHoursPeriod();

    dailyHours.start = "9:00";
    dailyHours.end = "17:00";
    dailyHours.allDay = false;
    
    List<StoreOpeningHoursPeriod> hoursList = new List<StoreOpeningHoursPeriod>.filled(7, dailyHours);

   
    StoreWeeklyOpeningHoursPeriod weeklyHours = new StoreWeeklyOpeningHoursPeriod(hours: hoursList,isSpecial: false);
   
    
    InternalUser storeInDatabase = new InternalUser(firebaseUser: user, userType: "internal", internalID: "12345678", openHours: weeklyHours, title: "employee", calendars: [{}]);
  }
  }


}