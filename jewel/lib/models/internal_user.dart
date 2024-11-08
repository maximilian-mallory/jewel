import 'package:firebase_auth/firebase_auth.dart';
import 'package:woosmap_flutter/woosmap_flutter.dart';

class InternalUser 
{

  User _firebaseUser;
  User get firebaseUser => _firebaseUser;

  String _userType;
  String get userType => _userType;

  String _internalID;
  String get internalID => _internalID;

  StoreWeeklyOpeningHoursPeriod _openHours;
  StoreWeeklyOpeningHoursPeriod get openHours => _openHours;

  String _title;
  String get title => _title;

  List<Map<String, dynamic>> _calendars;
  List<Map<String, dynamic>> get calendars => _calendars;

    InternalUser({
      required User firebaseUser,
      required String userType,
      required String internalID,
      required StoreWeeklyOpeningHoursPeriod openHours,
      required String title,
      required List<Map<String, dynamic>> calendars,
  })  : _firebaseUser = firebaseUser,
        _userType = userType,
        _internalID = internalID,
        _openHours = openHours,
        _title = title,
        _calendars = calendars;
        
  
  set userType(String value){
    if (value.isNotEmpty){
      _userType = value;
    }
    
  }

  set firebaseUser(User? value){
    if (value != null){
      _firebaseUser = value;
    }
    
  }

  set internalId(String value){
    if (value.isNotEmpty){
      _internalID = value;
    }
    
  }

  set openHours(StoreWeeklyOpeningHoursPeriod value){
    
    _openHours = value;
    
  }

  set title(String value){
    if (value.isNotEmpty){
      _title = value;
    }
    
  }

  set calendars(List<Map<String, dynamic>> value){
    if (value.isNotEmpty){
      _calendars = value;
    }
  }

  factory InternalUser.create({
    required User firebaseUser,
    required String userType,
    required String internalID,
    required StoreWeeklyOpeningHoursPeriod openHours,
    required String title,
    required List<Map<String, dynamic>> calendars,
  }) {
    return InternalUser(
      firebaseUser: firebaseUser,
      userType: userType,
      internalID: internalID,
      openHours: openHours,
      title: title,
      calendars: calendars,
    );
  }

// create a function to return a widget that holds all calendar events



}