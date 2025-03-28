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
  List<String> _members = []; //List of members in the group
  List<String> get getMembers => _members;

  UserGroup(
      {required String name,
      required String description,
      required bool private,
      required String password,
      required List<String> members})
      : _name = name,
        _description = description,
        _private = private,
        _password = password,
        _members = members;

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

  void addMember(String member) {
    if (member.isNotEmpty && !_members.contains(member)) {
      _members.add(member);
    } else {
      print("Member already exists or is empty");
    }
  }

  set setMembers(List<String> value) {
    if (value.isNotEmpty) {
      _members = value;
    }
  }

  factory UserGroup.fromJson(Map<String, dynamic> json) {
    return UserGroup(
      name: json['name'],
      description: json['description'],
      private: json['private'],
      password: json['password'],
      members: List<String>.from(json['members']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': _name,
      'description': _description,
      'private': _private,
      'password': _password,
      'members': _members,
    };
  }
}
