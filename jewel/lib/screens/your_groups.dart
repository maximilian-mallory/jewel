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
  const YourGroups({super.key});

  @override
  Widget build(BuildContext context) {
    final userGroupProvider = Provider.of<UserGroupProvider>(context);
    final yourGroups =
        userGroupProvider.yourGroups; // Replace with your actual logic
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Members of ${group.getName}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              children: [
                // List of group members
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: group.getMembers.length,
                    itemBuilder: (context, index) {
                      final member = group.getMembers[index];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(member),
                      );
                    },
                  ),
                ),
                const Divider(), // Divider between members and calendar
                // Group calendar
                Expanded(
                  flex: 2,
                  child: UserGroupCalendar(userGroup: group),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final shouldLeave =
                    await _showConfirmationDialog(context, group.getName);
                if (shouldLeave == true) {
                  try {
                    group.removeMember(
                        FirebaseAuth.instance.currentUser!.email!);
                    await updateGroupMembersInFireBase(group);
                    await Provider.of<UserGroupProvider>(context, listen: false)
                        .refreshYourGroups();
                    Navigator.of(context)
                        .pop(); // Close the dialog after leaving
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'You have left the group "${group.getName}".')),
                    );
                  } catch (e) {
                    print('Error leaving group: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error leaving group: $e')),
                    );
                  }
                }
              },
              child: const Text('Leave Group',
                  style: TextStyle(color: Colors.red)),
            ),
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
  }

  Map<DateTime, List<String>> _getGroupEvents(UserGroup group) {
    // Mock implementation: Replace this with actual logic to fetch events
    final Map<DateTime, List<String>> events = {};

    for (final member in group.getMembers) {
      // Example: Add mock events for each member
      final today = DateTime.now();
      events[today] = (events[today] ?? [])..add('$member\'s Event 1');
      events[today.add(const Duration(days: 1))] =
          (events[today.add(const Duration(days: 1))] ?? [])
            ..add('$member\'s Event 2');
    }
    return events;
  }

  Widget _buildCustomGroupCalendar(
      BuildContext context,
      Map<DateTime, List<String>> groupEvents,
      DateTime selectedDate,
      List<String> members) {
    final Map<String, Map<int, List<String>>> memberHourlyEvents = {};
    for (final member in members) {
      memberHourlyEvents[member] = {};
      final eventsForSelectedDate = groupEvents[selectedDate] ?? [];
      for (final event in eventsForSelectedDate) {
        // Mock logic: Assign events to random hours (replace with actual logic)
        final randomHour =
            DateTime.now().hour; // Replace with actual event start hour
        memberHourlyEvents[member]![randomHour] =
            (memberHourlyEvents[member]![randomHour] ?? [])
              ..add('$member\'s Event');
      }
    }

    return ListView.builder(
      itemCount: 24, // 24 hours in a day
      itemBuilder: (context, hour) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column
            Container(
              width: 60,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: Colors.grey[200],
              ),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Event columns for each member
            ...members.map((member) {
              final events = memberHourlyEvents[member]![hour] ?? [];
              return Expanded(
                child: Container(
                  height: 60.0,
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    color:
                        events.isNotEmpty ? Colors.blue[50] : Colors.grey[100],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: events.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: events.map((event) {
                              return Text(
                                event,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              );
                            }).toList(),
                          )
                        : const Center(
                            child: Text(
                              'No events',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
