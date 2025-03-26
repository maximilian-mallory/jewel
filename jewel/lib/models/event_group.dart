import 'package:flutter/material.dart';

class EventGroup {
  String _title;
  String get title => _title;

  Color _color;
  Color get color => _color;

  set title(String value) {
    if (value.isNotEmpty) {
      _title = value;
    }
  }

  set color(Color value) {
    _color = value;
  }

  EventGroup({
    required String title,
    required Color color,
  })  : _title = title,
        _color = color;

  Map<String, dynamic> toJson() {
    return {
      'title': _title,
      'color': _color,
    };
  }

  static EventGroup fromJson(Map<String, dynamic> json) {
    return EventGroup(
      title: json['title'],
      color: Color(int.parse(json['color'], radix: 16)),
    );
  }
}
