import 'package:flutter/material.dart';
import 'package:jewel/screens/your_groups.dart';
import 'package:jewel/screens/join_groups.dart'; // Rename your current functionality to join_groups.dart

class UserGroupScreen extends StatefulWidget {
  const UserGroupScreen({Key? key}) : super(key: key);

  @override
  _UserGroupScreenState createState() => _UserGroupScreenState();
}

class _UserGroupScreenState extends State<UserGroupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Your Groups'),
            Tab(text: 'Join Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          YourGroups(), // Your Groups tab
          JoinGroups(), // Join Groups tab
        ],
      ),
    );
  }
}
