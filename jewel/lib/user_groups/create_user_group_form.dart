import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_group.dart';
import 'user_group_provider.dart';

class CreateUserGroupForm extends StatefulWidget {
  @override
  _CreateUserGroupFormState createState() => _CreateUserGroupFormState();
}

class _CreateUserGroupFormState extends State<CreateUserGroupForm> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _description = '';
  bool _private = false;
  String _password = '';

  @override
  Widget build(BuildContext context) {
    final userGroupProvider = Provider.of<UserGroupProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Create User Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Group Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
              ),
              CheckboxListTile(
                title: Text('Private'),
                value: _private,
                onChanged: (bool? value) {
                  setState(() {
                    _private = value!;
                  });
                },
              ),
              if (_private)
                TextFormField(
                  decoration: InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if (_private && (value == null || value.isEmpty)) {
                      return 'Please enter a password for private group';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _password = value!;
                  },
                  obscureText: true,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      UserGroup newUserGroup = UserGroup(
                        name: _name,
                        description: _description,
                        private: _private,
                        password: _password,
                      );
                      userGroupProvider.addUserGroup(newUserGroup);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User Group Created')),
                      );
                    }
                  },
                  child: Text('Create Group'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
