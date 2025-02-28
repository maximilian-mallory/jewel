class UserGroup {
  String _name;
  String get getName => _name;
  String _description;
  String get getDescription => _description;

  UserGroup({required String name, required String description})
      : _name = name,
        _description = description;

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

  factory UserGroup.fromJson(Map<String, dynamic> json) {
    return UserGroup(name: json['name'], description: json['description']);
  }
}
