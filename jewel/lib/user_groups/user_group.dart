class UserGroup {
  String _name; //Name of the group
  String get getName => _name;
  String _description; //Description of the group
  String get getDescription => _description;
  bool _private = false; //Determines if the group is private or public
  bool get isPrivate => _private;
  String
      _password; //Password for the group -- only used if the group is private
  String get getPassword => _password;

  UserGroup(
      {required String name,
      required String description,
      required bool private,
      required String password})
      : _name = name,
        _description = description,
        _private = private,
        _password = password;

  set setName(String value) {
    if (value.isNotEmpty) {
      _name = value;
    }
  }

  set setDescription(String value) {
    if (value.isNotEmpty) {
      _description = value;
    }
  }

  set setPrivate(bool value) {
    _private = value;
  }

  set setPassword(String value) {
    if (value.isNotEmpty) {
      _password = value;
    }
  }

  factory UserGroup.fromJson(Map<String, dynamic> json) {
    return UserGroup(
      name: json['name'],
      description: json['description'],
      private: json['private'],
      password: json['password'],
    );
  }
}
