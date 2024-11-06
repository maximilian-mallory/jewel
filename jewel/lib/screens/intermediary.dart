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
  final user =FirebaseAuth.instance.currentUser;
  var name;
  var email;



 @override
  void initState() {
    super.initState();
  }

  void createExternalUser(){
    if (user != null){
    for (final providerProfile in user!.providerData){
      name = providerProfile.displayName;
      email = providerProfile.email;
    }
    new ExternalUser(firebaseUser: user, userType: "contractor", companyName: "Null Contracting", openHours: , title: "contractor", cause: "external contractor", calendars: null)
  }
  }


  void createInternalUser(){
    if (user != null){
    for (final providerProfile in user!.providerData){
      name = providerProfile.displayName;
      email = providerProfile.email;
    }
    List<StoreOpeningHoursPeriod> hoursList = List<>();
    StoreOpeningHoursPeriod dailyHours = new StoreOpeningHoursPeriod();

    dailyHours.start = "8:00";
    dailyHours.end = "17:00";
    dailyHours.allDay = false;
    
    for (int i =0; i< 7; i++){
      hoursList.add(dailyHours);
    }
    StoreWeeklyOpeningHoursPeriod weeklyHours;
    weeklyHours.hours = hoursList; 
    new InternalUser(firebaseUser: user, userType: "internal", internalID: "12345678", openHours: "", title: "employee", calendars: "")
  }
  }


}