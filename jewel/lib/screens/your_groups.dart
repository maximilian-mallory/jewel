import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/material.dart';
import 'package:jewel/firebase_ops/user_groups.dart';
import 'package:provider/provider.dart';
import 'package:jewel/user_groups/user_group_provider.dart';
import 'package:jewel/user_groups/user_group.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewel/user_groups/user_group_calendar.dart';

class YourGroups extends StatelessWidget {
  final Map<String, Color> memberColors;
  YourGroups({super.key, Map<String, Color>? initialMemberColors})
      : memberColors = initialMemberColors ?? {};

  @override
  Widget build(BuildContext context) {
    final userGroupProvider = Provider.of<UserGroupProvider>(context);
    final yourGroups = userGroupProvider.yourGroups;
    return ListView.builder(
      itemCount: yourGroups.length,
      itemBuilder: (context, index) {
        final group = yourGroups[index];
        return ListTile(
          title: Text(group.getName),
          subtitle: Text(group.getDescription ?? 'No description'),
          onTap: () {
            _showGroupMembersDialog(context, group);
          },
          trailing: IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            onPressed: () async {
              // Add logic to leave the group
              final shouldLeave =
                  await _showConfirmationDialog(context, group.getName);
              if (shouldLeave == true) {
                try {
                  group.removeMember(FirebaseAuth.instance.currentUser!.email!);
                  await updateGroupMembersInFireBase(group);
                  await userGroupProvider.refreshYourGroups();
                } catch (e) {
                  print('Error leaving group: $e');
                }
              }
            },
          ),
        );
      },
    );
  }

  Future<bool?> _showConfirmationDialog(
      BuildContext context, String groupName) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Leave'),
          content:
              Text('Are you sure you want to leave the group "$groupName"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirms
              },
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }

  void _showGroupMembersDialog(BuildContext context, UserGroup group) async {
    final firestore = FirebaseFirestore.instance;

    // Initialize colors for members if not already set
    for (final member in group.getMembers) {
      memberColors[member] ??= Colors.primaries[
          group.getMembers.indexOf(member) % Colors.primaries.length];
    }

    // Check if the group calendar exists
    final groupDoc = firestore.collection('group_calendar').doc(group.getName);
    final calendarSnapshot = await groupDoc.get();

    if (!calendarSnapshot.exists) {
      // Create a new calendar for the group
      await groupDoc.set({
        'groupName': group.getName,
        'createdAt': FieldValue.serverTimestamp(),
        'members': group.getMembers,
      });

      print('New calendar created for group: ${group.getName}');
    } else {
      print('Calendar already exists for group: ${group.getName}');
    }

    // Show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Members of ${group.getName}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  children: [
                    // List of group members with color pickers
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: group.getMembers.length,
                        itemBuilder: (context, index) {
                          final member = group.getMembers[index];
                          return ListTile(
                            leading: GestureDetector(
                              onTap: () async {
                                final newColor = await showDialog<Color>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Pick a Color'),
                                    content: SingleChildScrollView(
                                      child: BlockPicker(
                                        pickerColor: memberColors[member]!,
                                        onColorChanged: (color) {
                                          setState(() {
                                            memberColors[member] = color;
                                          });
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(memberColors[member]);
                                        },
                                        child: const Text('Select'),
                                      ),
                                    ],
                                  ),
                                );
                                if (newColor != null) {
                                  setState(() {
                                    memberColors[member] = newColor;
                                  });
                                }
                              },
                              child: CircleAvatar(
                                backgroundColor: memberColors[member],
                              ),
                            ),
                            title: Text(member),
                          );
                        },
                      ),
                    ),
                    const Divider(), // Divider between members and calendar
                    // Group calendar
                    Expanded(
                      flex: 2,
                      child: UserGroupCalendar(
                        userGroup: group,
                        memberColors:
                            memberColors, // Pass updated member colors
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
