import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
// new
import 'package:flutter/material.dart';
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
    final user =FirebaseAuth.instance.currentUser;
    final databaseSearch = FirebaseFirestore.instance;
    final externalRef = databaseSearch.collection("people");
    final internalRef = databaseSearch.collection("people");

    final queryInternal = internalRef.where("firebaseUser", isEqualTo: user);

    return true;
  
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