import 'package:flutter/material.dart';

class GoalData {
  final String category;
  final bool completed;
  final String description;
  final int duration;
  final String ownerEmail;
  final String title;

  GoalData(this.category, this.completed, this.description, this.duration,
      this.ownerEmail, this.title);
}

class GoalStatusData {
  final String status;
  final int count;
  final Color color;

  GoalStatusData(this.status, this.count, this.color);
}

class CategoryData {
  final String category;
  final int count;

  CategoryData(this.category, this.count);
}

class DurationData {
  final String label;
  final double duration;

  DurationData(this.label, this.duration);
}