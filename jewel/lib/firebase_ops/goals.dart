import "package:jewel/personal_goals/personal_goals.dart";
import 'package:cloud_firestore/cloud_firestore.dart';


//for getting personal goals by category
//this method takes the category you are looking for and the email of the user and returns a list of PersonalGoals of the category
Future<List<PersonalGoals>> getGoalsFromFireBase(String category, String ownerEmail) async{
  List<PersonalGoals> categoryGoals = [];
  await FirebaseFirestore.instance.collection('goals').doc(category).collection(ownerEmail).get().then(
    (goalSnapshot){
      for(var docSnapshot in goalSnapshot.docs){
        categoryGoals.add(PersonalGoals.fromJson(docSnapshot.data()));
      }
    }
  );
  return categoryGoals;
}