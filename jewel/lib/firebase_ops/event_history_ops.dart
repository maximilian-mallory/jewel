import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewel/event_history/event_history.dart';

Future<List<EventHistory>> getAllHistoriesFromFireBase() async {
  List<EventHistory> history = [];
  await FirebaseFirestore.instance
      .collection('event_history')
      .get()
      .then((groupSnapshot) {
    for (var docSnapshot in groupSnapshot.docs) {
      history.add(EventHistory.fromJson(docSnapshot.data()));
    }
  });
  return history;
}

void addHistoryToFireBase(EventHistory history) {
  String docName = history.getEventId;
  FirebaseFirestore.instance
      .collection('event_history')
      .doc(docName) // Use group name as document ID
      .set(history.toJson())
      .then((docRef) {
    print('History added successfully with ID: $docName');
  }).catchError((error) {
    print('Error adding group: $error');
  });
}

Future<void> updateChangeLogInFireBase(
    EventHistory history, String change) async {
  await FirebaseFirestore.instance
      .collection('event_history')
      .doc(history.getEventId)
      .update({
    'changelog': history.getChangelog..add(change),
  }).then((_) {
    print('History change log updated successfully');
  }).catchError((error) {
    print('Error updating change log: $error');
  });
}

Future<EventHistory> getHistoryFromFireBase(String eventId) async {
  DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
      .collection('event_history')
      .doc(eventId)
      .get();

  if (docSnapshot.exists) {
    return EventHistory.fromJson(docSnapshot.data() as Map<String, dynamic>);
  } else {
    print('No history found for eventId: $eventId');
    return EventHistory(
      eventId: eventId,
      Id: '',
      changelog: [],
    );
  }
}
