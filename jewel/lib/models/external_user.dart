import 'package:firebase_auth/firebase_auth.dart';

class ExternalUser {
  User _firebaseUser;
  User get firebaseUser => _firebaseUser;

  String _userType;
  String get userType => _userType;

  String _companyName;
  String get companyName => _companyName;

  List<Map<String, dynamic>> _openHours;
  List<Map<String, dynamic>> get openHours => _openHours;

  String _title;
  String get title => _title;

  String _cause;
  String get cause => _cause;

  ExternalUser({
    required User firebaseUser,
    required String userType,
    required String companyName,
    required List<Map<String, dynamic>> openHours,
    required String title,
    required String cause,
  })  : _firebaseUser = firebaseUser,
        _userType = userType,
        _companyName = companyName,
        _openHours = openHours,
        _title = title,
        _cause = cause;

  set userType(String value) {
    if (value.isNotEmpty) {
      _userType = value;
    }
  }

  set firebaseUser(User? value) {
    if (value != null) {
      _firebaseUser = value;
    }
  }

  set companyName(String value) {
    if (value.isNotEmpty) {
      _companyName = value;
    }
  }

  set openHours(List<Map<String, dynamic>> value) {
    if (value.isNotEmpty) {
      _openHours = value;
    }
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

  // Factory method to create an ExternalUser instance
  factory ExternalUser.create({
    required User firebaseUser,
    required String userType,
    required String companyName,
    required List<Map<String, dynamic>> openHours,
    required String title,
    required String cause,
  }) {
    return ExternalUser(
      firebaseUser: firebaseUser,
      userType: userType,
      companyName: companyName,
      openHours: openHours,
      title: title,
      cause: cause,
    );
  }
}



// TODO take google/auth/home.dart lines 14-29 and create a method that takes a firebase authenticated user and returns the uid

// user logs in -> auth_gate returns the firebase user to a buffer / loading wheel widget where the getUID(user) method is called
// -> after we have the fireBase User
// getUID( user )