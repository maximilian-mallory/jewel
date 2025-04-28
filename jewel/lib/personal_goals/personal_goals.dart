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
class PersonalGoals {
  late String? ownerEmail; //holds the user email
  String title = ""; //title of the goal the user sets
  String description = ""; //description of the goal the user sets
  int duration =
      0; //time the goal took (building for tracking purposes and analytics later)
  bool completed =
      false; //determines if the goal has been completed -> eventually used to determine if it should be showed in current goals or archive
  String category =
      ""; //Categorizes goals, will have options on goal creation form

  //constructor(s)
  PersonalGoals(this.title, this.description, this.category, this.completed,
      this.duration);

  factory PersonalGoals.fromJson(Map<String, dynamic> json) =>
      _$PersonalGoalsFromJson(json);
  Map<String, dynamic> toJson() => _$PersonalGoalsToJson(this);
  //Puts Map<String, dynamic> into firebase
  Future<void> storeGoal() async {
    ownerEmail = FirebaseAuth.instance.currentUser?.email;
    await FirebaseFirestore.instance
        .collection('goals')
        .doc(category)
        .collection(ownerEmail!)
        .doc()
        .set(toJson());
  }

  // Updates an existing goal in Firebase
  Future<void> updateGoal(String docId) async {
    ownerEmail = FirebaseAuth.instance.currentUser?.email;
    if (ownerEmail == null) {
      throw Exception("User is not logged in.");
    }

    await FirebaseFirestore.instance
        .collection('goals')
        .doc(category)
        .collection(ownerEmail!)
        .doc(docId)
        .update(toJson());
  }

  // Add points for completing goal
  Future<void> addPoints() async {
    ownerEmail = FirebaseAuth.instance.currentUser?.email;
    if (ownerEmail == null) {
      throw Exception("User is not logged in.");
    }

    final docRef =
        FirebaseFirestore.instance.collection('goals_data').doc(ownerEmail!);

    // Check if the document exists
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) {
      // Create the document if it doesn't exist
      await docRef.set({'points': 0});
    }

    // Increment points by 10
    await docRef.update({
      'points': FieldValue.increment(10),
    });
  }

  // Subtract points for marking goal as incomplete
  Future<void> subtractPoints() async {
    ownerEmail = FirebaseAuth.instance.currentUser?.email;
    if (ownerEmail == null) {
      throw Exception("User is not logged in.");
    }

    final docRef =
        FirebaseFirestore.instance.collection('goals_data').doc(ownerEmail!);

    // Check if the document exists
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) {
      // Create the document if it doesn't exist
      await docRef.set({'points': 0});
    }

    // Decrement points by 10
    await docRef.update({
      'points': FieldValue.increment(-10),
    });
  }
}
