import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jewel/user_groups/user_group_provider.dart';
import 'package:jewel/user_groups/user_group.dart';

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
          trailing: IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Add logic to leave the group
              print('Leaving group: ${group.getName}');
            },
          ),
        );
      },
    );
  }
}
