import 'package:firebase_auth/firebase_auth.dart';

class ExternalUser 
{

  final User firebaseUser;
  final String userType;

  ExternalUser({
      required this.firebaseUser,
      required this.userType,
  });


}


// TODO take google/auth/home.dart lines 14-29 and create a method that takes a firebase authenticated user and returns the uid

// user logs in -> auth_gate returns the firebase user to a buffer / loading wheel widget where the getUID(user) method is called
// -> after we have the fireBase User
// getUID( user )