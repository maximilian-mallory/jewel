import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jewel/user_groups/create_user_group_form.dart';
import 'package:jewel/user_groups/user_group_provider.dart';

class UserGroupScreen extends StatefulWidget {
  const UserGroupScreen({Key? key}) : super(key: key);

  @override
  _UserGroupScreenState createState() => _UserGroupScreenState();
}

class _UserGroupScreenState extends State<UserGroupScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final userGroupProvider = Provider.of<UserGroupProvider>(context);
    final searchResults = userGroupProvider.searchUserGroups(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Groups'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for existing groups',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final group = searchResults[index];
                  return ListTile(
                    title: Text(group.getName),
                    subtitle: Text(group.getDescription),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateUserGroupForm(),
                  ),
                );
              },
              child: const Text('New Group'),
            ),
          ],
        ),
      ),
    );
  }
}
