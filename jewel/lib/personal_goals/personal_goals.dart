
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
  late String? ownerEmail; // Holds the user email
  String title = "";
  String description = "";
  int duration = 0;
  bool completed = false;
  String category = "";

  /// Track when a goal was marked as complete (null if not complete)
  DateTime? completedAt;

  // Constructor(s)
  PersonalGoals(
    this.title,
    this.description,
    this.category,
    this.completed,
    this.duration, {
    this.completedAt,
  });

  /// Factory for converting from Firestore and JSON (supports Firebase Timestamp)
  factory PersonalGoals.fromJson(Map<String, dynamic> json) {
    final goal = _$PersonalGoalsFromJson(json);
    if (json.containsKey('completedAt')) {
      final ts = json['completedAt'];
      if (ts is Timestamp) {
        goal.completedAt = ts.toDate();
      } else if (ts is int) {
        goal.completedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      } else if (ts is String) {
        // Try to parse ISO string date
        goal.completedAt = DateTime.tryParse(ts);
      } else {
        goal.completedAt = null;
      }
    } else {
      goal.completedAt = null;
    }
    return goal;
  }

  /// Converts to JSON for Firebase/serialization
  Map<String, dynamic> toJson() {
    final json = _$PersonalGoalsToJson(this);
    // Store as native DateTime (for Firestore) or null
    json['completedAt'] = completedAt;
    return json;
  }

  /// Adds a new goal to Firestore
  Future<void> storeGoal() async {
    ownerEmail = FirebaseAuth.instance.currentUser?.email;
    await FirebaseFirestore.instance
        .collection('goals')
        .doc(category)
        .collection(ownerEmail!)
        .doc()
        .set(toJson());
  }

  // Updates an existing goal in Firestore with current data
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
