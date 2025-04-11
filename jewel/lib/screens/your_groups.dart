import 'package:flutter/material.dart';
import 'package:jewel/firebase_ops/user_groups.dart';
import 'package:provider/provider.dart';
import 'package:jewel/user_groups/user_group_provider.dart';
import 'package:jewel/user_groups/user_group.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  void _showGroupMembersDialog(BuildContext context, UserGroup group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Members of ${group.getName}'),
          content: SizedBox(
            width: double.maxFinite,
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
}
