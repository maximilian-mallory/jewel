import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_snap.g.dart';

@JsonSerializable()
class JewelEvent {
  final Event event;
  final String? customProp;

  JewelEvent( {required this.event, this.customProp});

  /// Factory method to create an instance from a Google Calendar event
  factory JewelEvent.fromGoogleEvent(Event googleEvent) {
    return JewelEvent(
      event: googleEvent,
      customProp: "this is a test"
    );
  }

  factory JewelEvent.fromJson(Map<String, dynamic> json) =>
      _$JewelEventFromJson(json);

  Map<String, dynamic> toJson() {
    return {
      'event': event.toJson(),
      'customProp': customProp
    };
  }

  Future<void> store() async {
    await FirebaseFirestore.instance.collection('jewelevents').doc(event.id).set(toJson());
  }

  @override
  String toString() => 'JewelEvent(event: $event)';
}