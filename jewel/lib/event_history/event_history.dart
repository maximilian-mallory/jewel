class EventHistory {
  String _eventId;
  String get getEventId => _eventId;

  String _Id;
  String get getId => _Id;

  List<String> _changelog;
  List<String> get getChangelog => _changelog;

  EventHistory({
    required String eventId,
    required String Id,
    required List<String> changelog,
  })  : _eventId = eventId,
        _Id = Id,
        _changelog = changelog;

  set setEventId(String eventId) {
    _eventId = eventId;
  }

  set setId(String Id) {
    _Id = Id;
  }

  set setChangelog(List<String> changelog) {
    _changelog = changelog;
  }

  void addChangelog(String changelog) {
    _changelog.add(changelog);
  }

  factory EventHistory.fromJson(Map<String, dynamic> json) {
    return EventHistory(
      eventId: json['eventId'],
      Id: json['Id'],
      changelog: List<String>.from(json['changelog']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': _eventId,
      'Id': _Id,
      'changelog': _changelog,
    };
  }
}
