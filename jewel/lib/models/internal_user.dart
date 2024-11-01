import 'package:firebase_auth/firebase_auth.dart';

class InternalUser 
{

  User _firebaseUser;
  User get firebaseUser => _firebaseUser;

  String _userType;
  String get userType => _userType;

  String _internalID;
  String get internalID => _internalID;

  List<Map<String, dynamic>> _openHours;
  List<Map<String, dynamic>> get openHours => _openHours;

  String _title;
  String get title => _title;

    InternalUser({
      required User firebaseUser,
      required String userType,
      required String internalID,
      required List<Map<String, dynamic>> openHours,
      required String title,
  })  : _firebaseUser = firebaseUser,
        _userType = userType,
        _internalID = internalID,
        _openHours = openHours,
        _title = title;
        
  
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

  set openHours(List<Map<String, dynamic>> value){
    if (value.isNotEmpty){
      _openHours = value;
    }
    
  }

  set title(String value){
    if (value.isNotEmpty){
      _title = value;
    }
    
  }

}