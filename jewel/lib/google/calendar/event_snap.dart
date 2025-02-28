import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_snap.g.dart';

@JsonSerializable()
class JewelEvent {
  final Event event;
  final String? customProp;
  final String? arrivalTime;

  JewelEvent( {required this.event, this.customProp, this.arrivalTime});

  /// Factory method to create an instance from a Google Calendar event
  factory JewelEvent.fromGoogleEvent(Event googleEvent) {
    return JewelEvent(
      event: googleEvent,
      customProp: "this is a test",
      arrivalTime: googleEvent.start?.dateTime?.toIso8601String()
    );
  }

  factory JewelEvent.fromJson(Map<String, dynamic> json) =>
      _$JewelEventFromJson(json);

  Map<String, dynamic> toJson() {
    return {
      'event': event.toJson(),
      'customProp': customProp,
      'arrivalTime': arrivalTime
    };
  }

  Future<void> store() async {
    await FirebaseFirestore.instance.collection('jewelevents').doc(event.id).set(toJson());
  }

  @override
  String toString() => 'JewelEvent(event: $event, arrivalTime: $arrivalTime, customProp: $customProp)';
}