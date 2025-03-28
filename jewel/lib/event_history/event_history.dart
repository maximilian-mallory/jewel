class EventHistory {
  String _eventId;
  String get getEventId => _eventId;

  List<String> _changelog;
  List<String> get getChangelog => _changelog;

  EventHistory({
    required String eventId,
    required List<String> changelog,
  })  : _eventId = eventId,
        _changelog = changelog;

  set setEventId(String eventId) {
    _eventId = eventId;
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
      changelog: List<String>.from(json['changelog']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': _eventId,
      'changelog': _changelog,
    };
  }
}
