// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_goals.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalGoals _$PersonalGoalsFromJson(Map<String, dynamic> json) =>
    PersonalGoals(
      json['title'] as String,
      json['description'] as String,
      json['category'] as String,
      json['completed'] as bool,
      (json['duration'] as num).toInt(),
    )..ownerEmail = json['owner'] as String?;

Map<String, dynamic> _$PersonalGoalsToJson(PersonalGoals instance) =>
    <String, dynamic>{
      'owner': instance.ownerEmail,
      'title': instance.title,
      'description': instance.description,
      'duration': instance.duration,
      'completed': instance.completed,
      'category': instance.category,
    };
