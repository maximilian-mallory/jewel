// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_snap.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JewelEvent _$JewelEventFromJson(Map<String, dynamic> json) => JewelEvent(
      event: Event.fromJson(json['event'] as Map<String, dynamic>),
      customProp: json['customProp'] as String?,
    );

Map<String, dynamic> _$JewelEventToJson(JewelEvent instance) =>
    <String, dynamic>{
      'event': instance.event,
      'customProp': instance.customProp,
    };
