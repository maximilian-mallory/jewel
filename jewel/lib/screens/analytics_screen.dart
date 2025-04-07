import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample data
    final List<GoalData> goals = [
      GoalData('Health', true, 'Morning Run', 30, 'user1@example.com', 'Run 5km'),
      GoalData('Work', false, 'Project Deadline', 120, 'user2@example.com', 'Complete Project'),
      GoalData('Personal Growth', true, 'Read a Book', 15, 'user3@example.com', 'Read 50 pages'),
      GoalData('Finance', false, 'Save Money', 60, 'user4@example.com', 'Save \$500'),
      GoalData('Education', true, 'Online Course', 90, 'user5@example.com', 'Complete Module 1'),
      GoalData('Hobby', false, 'Painting', 45, 'user6@example.com', 'Finish Artwork'),
      GoalData('Other', true, 'Volunteer Work', 20, 'user7@example.com', 'Help at Shelter'),
    ];

    // Processed data for charts
    final completedGoals = goals.where((goal) => goal.completed).length;
    final pendingGoals = goals.length - completedGoals;

    final categoryData = goals.fold<Map<String, int>>({}, (map, goal) {
      map[goal.category] = (map[goal.category] ?? 0) + 1;
      return map;
    }).entries.map((entry) => CategoryData(entry.key, entry.value)).toList();

    final averageDuration = goals.fold<int>(0, (sum, goal) => sum + goal.duration) / goals.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Analytics'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Goal Completion Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                title: ChartTitle(text: 'Completed vs Pending Goals'),
                legend: Legend(isVisible: true),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries>[
                  ColumnSeries<GoalStatusData, String>(
                    dataSource: [
                      GoalStatusData('Completed', completedGoals),
                      GoalStatusData('Pending', pendingGoals),
                    ],
                    xValueMapper: (GoalStatusData data, _) => data.status,
                    yValueMapper: (GoalStatusData data, _) => data.count,
                    name: 'Goals',
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Goal Category Distribution',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SfCircularChart(
                title: ChartTitle(text: 'Goals by Category'),
                legend: Legend(isVisible: true),
                series: <CircularSeries>[
                  PieSeries<CategoryData, String>(
                    dataSource: categoryData,
                    xValueMapper: (CategoryData data, _) => data.category,
                    yValueMapper: (CategoryData data, _) => data.count,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Average Goal Duration',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                title: ChartTitle(text: 'Average Duration of Goals (Minutes)'),
                legend: Legend(isVisible: false),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries>[
                  ColumnSeries<DurationData, String>(
                    dataSource: [
                      DurationData('Average Duration', averageDuration),
                    ],
                    xValueMapper: (DurationData data, _) => data.label,
                    yValueMapper: (DurationData data, _) => data.duration,
                    name: 'Duration',
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoalData {
  final String category;
  final bool completed;
  final String description;
  final int duration;
  final String ownerEmail;
  final String title;

  GoalData(this.category, this.completed, this.description, this.duration, this.ownerEmail, this.title);
}

class GoalStatusData {
  final String status;
  final int count;

  GoalStatusData(this.status, this.count);
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