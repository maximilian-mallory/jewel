import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService{

  signInWithGoogle() async {
    try{

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '',
        scopes: <String> [],
      );
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount!.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
    }
    catch (e) {
      print('Error with google_signin: $e');
      return null;
    }
    
    
  }
}