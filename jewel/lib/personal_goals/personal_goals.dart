import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/*
Personal Goals Class:
-Creates the information needed for the personal goals
-Stores data in FireBase bassed off the current user
*/
part 'personal_goals.g.dart';
@JsonSerializable()
class PersonalGoals{

  late String? ownerEmail; //holds the user email
  String title = ""; //title of the goal the user sets
  String description = ""; //description of the goal the user sets
  int duration = 0; //time the goal took (building for tracking purposes and analytics later)
  bool completed = false; //determines if the goal has been completed -> eventually used to determine if it should be showed in current goals or archive
  String category = ""; //Categorizes goals, will have options on goal creation form

  //constructor(s)
  PersonalGoals(this.title,this.description,this.category,this.completed,this.duration);

  factory PersonalGoals.fromJson(Map<String, dynamic> json) => _$PersonalGoalsFromJson(json);
  Map<String, dynamic> toJson() => _$PersonalGoalsToJson(this);
  //Puts Map<String, dynamic> into firebase
  Future<void> storeGoal() async{
    ownerEmail = FirebaseAuth.instance.currentUser?.email;
    await FirebaseFirestore.instance.collection('goals').doc(category).collection(ownerEmail!).doc().set(toJson());
  }
}