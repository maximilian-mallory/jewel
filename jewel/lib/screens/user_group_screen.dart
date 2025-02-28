import 'package:flutter/material.dart';
import 'package:jewel/user_groups/user_group.dart';

class UserGroupScreen extends StatelessWidget {
  const UserGroupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Groups'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for existing groups',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onSubmitted: (query) {
                    // Handle search logic here
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchResultsScreen(query: query),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // Navigate to the create group screen or handle create group logic
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CreateGroupScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JoinGroupScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a Group'),
      ),
      body: Center(
        child: const Text('Join Group Screen'),
      ),
    );
  }
}

class CreateGroupScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a New Group'),
      ),
      body: Center(
        child: const Text('Create Group Screen'),
      ),
    );
  }
}

class SearchResultsScreen extends StatelessWidget {
  final String query;

  const SearchResultsScreen({Key? key, required this.query}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
      ),
      body: Center(
        child: Text('Results for "$query"'),
      ),
    );
  }
}
