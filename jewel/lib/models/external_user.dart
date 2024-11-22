import 'package:firebase_auth/firebase_auth.dart';
import 'package:woosmap_flutter/woosmap_flutter.dart';

class ExternalUser {
  String _email;
  String get email => _email;

  String _userType;
  String get userType => _userType;

  String _companyName;
  String get companyName => _companyName;

  StoreWeeklyOpeningHoursPeriod _openHours;
  StoreWeeklyOpeningHoursPeriod get openHours => _openHours;

  String _title;
  String get title => _title;

  String _cause;
  String get cause => _cause;

  List<Map<String, dynamic>> _calendars;
  List<Map<String, dynamic>> get calendars => _calendars;

  ExternalUser({
    required String email,
    required String userType,
    required String companyName,
    required StoreWeeklyOpeningHoursPeriod openHours,
    required String title,
    required String cause,
    required List<Map<String, dynamic>> calendars,
  })  : _email = email,
        _userType = userType,
        _companyName = companyName,
        _openHours = openHours,
        _title = title,
        _cause = cause,
        _calendars = calendars;

  set userType(String value) {
    if (value.isNotEmpty) {
      _userType = value;
    }
  }

  set email(String value) {
    if (value.isNotEmpty) {
      _email = value;
    }
  }

  set companyName(String value) {
    if (value.isNotEmpty) {
      _companyName = value;
    }
  }

  set openHours(StoreWeeklyOpeningHoursPeriod value) {
    _openHours = value;
    
  }

  set title(String value) {
    if (value.isNotEmpty) {
      _title = value;
    }
  }

  set cause(String value) {
    if (value.isNotEmpty) {
      _cause = value;
    }
  }

  set calendars(List<Map<String, dynamic>> value){
    if (value.isNotEmpty){
      _calendars = value;
    }
  }

  // Factory method to create an ExternalUser instance
  factory ExternalUser.create({
    required String email,
    required String userType,
    required String companyName,
    required StoreWeeklyOpeningHoursPeriod openHours,
    required String title,
    required String cause,
    required List<Map<String, dynamic>> calendars,
  }) {
    return ExternalUser(
      email: email,
      userType: userType,
      companyName: companyName,
      openHours: openHours,
      title: title,
      cause: cause,
      calendars: calendars,
    );
  }

  // create a function to return a widget that holds all calendar events

  // create a function that serializes the user

  Map<String, dynamic> toJson() => {
    'email': email,
    'userType': userType,
    'companyName': companyName,
    'openHours': openHours,
    'title': title,
    'cause': cause,
    'calendars': calendars,  
  };
}



// TODO take google/auth/home.dart lines 14-29 and create a method that takes a firebase authenticated user and returns the uid

// user logs in -> auth_gate returns the firebase user to a buffer / loading wheel widget where the getUID(user) method is called
// -> after we have the fireBase User
// getUID( user )