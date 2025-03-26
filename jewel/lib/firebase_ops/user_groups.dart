import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewel/user_groups/user_group.dart';

Future<List<UserGroup>> getAllGroupsFromFireBase() async {
  List<UserGroup> groups = [];
  await FirebaseFirestore.instance
      .collection('user_group')
      .get()
      .then((groupSnapshot) {
    for (var docSnapshot in groupSnapshot.docs) {
      groups.add(UserGroup.fromJson(docSnapshot.data()));
    }
  });
  return groups;
}

void addGroupToFireBase(UserGroup group) {
  var gname = group.getName;
  FirebaseFirestore.instance
      .collection('user_group')
      .doc(gname) // Use group name as document ID
      .set(group.toJson())
      .then((docRef) {
    print('Group added successfully with ID: $gname');
  }).catchError((error) {
    print('Error adding group: $error');
  });
}

Future<void> updateGroupInFireBase(UserGroup group) async {
  await FirebaseFirestore.instance
      .collection('user_group')
      .doc(group.getName) // Use group name as document ID
      .update({
    'name': group.getName,
    'description': group.getDescription,
    'private': group.isPrivate,
    'password': group.getPassword,
    'members': group.getMembers,
  }).then((_) {
    print('Group updated successfully');
  }).catchError((error) {
    print('Error updating group: $error');
  });
}

Future<void> updateGroupMembersInFireBase(UserGroup group) async {
  await FirebaseFirestore.instance
      .collection('user_group')
      .doc(group.getName)
      .update({
    'members': group.getMembers,
  }).then((_) {
    print('Group members updated successfully');
  }).catchError((error) {
    print('Error updating group members: $error');
  });
}
