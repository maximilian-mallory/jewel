import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart'; // new
import 'package:flutter/material.dart';
import 'package:jewel/widgets/home_screen.dart';

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
  }
  }


  void createInternalUser(){
    if (user != null){
    for (final providerProfile in user!.providerData){
      name = providerProfile.displayName;
      email = providerProfile.email;
    }
  }
  }


}