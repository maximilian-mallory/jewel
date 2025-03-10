import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jewel/user_groups/create_user_group_form.dart';
import 'package:jewel/user_groups/user_group_provider.dart';
import 'package:jewel/user_groups/user_group.dart';

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
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.getName,
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(group.getDescription),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            if (group.isPrivate) {
                              _showPasswordDialog(context, group);
                            } else {
                              print('Joined group: ${group.getName}');
                            }
                          },
                          child: const Text('Join'),
                        ),
                      ],
                    ),
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

  void _showPasswordDialog(BuildContext context, UserGroup group) {
    final TextEditingController _passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Password'),
          content: TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: 'Password',
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_passwordController.text == group.getPassword) {
                  print('Joined group: ${group.getName}');
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Incorrect password')),
                  );
                }
              },
              child: Text('Join'),
            ),
          ],
        );
      },
    );
  }
}
