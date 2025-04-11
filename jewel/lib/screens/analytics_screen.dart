import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jewel/personal_goals/personal_goals.dart';
import 'package:jewel/firebase_ops/goals.dart';
import 'package:jewel/models/goal_models.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final List<String> goalCategories = [
    "Health",
    "Work",
    "Personal Growth",
    "Finance",
    "Education",
    "Hobby",
    "Other",
    "All"
  ];
  String? currentValue;
  Map<String, PersonalGoals> goals = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGoals();
  }

  Future<void> fetchGoals() async {
    setState(() {
      isLoading = true;
    });

    goals.clear();

    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    for (String category in goalCategories) {
      if (category != "All") {
        Map<String, PersonalGoals> categoryGoalsMap =
            await getGoalsFromFireBase(category, userEmail);
        goals.addAll(categoryGoalsMap);
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Processed data for charts
    final completedGoals = goals.values.where((goal) => goal.completed).length;
    final pendingGoals = goals.length - completedGoals;

    final categoryData = goals.values
        .fold<Map<String, int>>({}, (map, goal) {
          map[goal.category] = (map[goal.category] ?? 0) + 1;
          return map;
        })
        .entries
        .map((entry) => CategoryData(entry.key, entry.value))
        .toList();

    final averageDuration =
        goals.values.fold<int>(0, (sum, goal) => sum + goal.duration) / goals.length;

    final totalDurationByCategory = goals.values.fold<Map<String, int>>({}, (map, goal) {
      map[goal.category] = (map[goal.category] ?? 0) + goal.duration;
      return map;
    });

    final totalDurationData = totalDurationByCategory.entries
        .map((entry) => DurationData(entry.key, entry.value.toDouble()))
        .toList();

    final Map<String, Color> categoryColors = { 
      "Health": Colors.red, 
      "Work": Colors.blue, 
      "Personal Growth": Colors.green, 
      "Finance": Colors.orange, 
      "Education": Colors.indigo, 
      "Hobby": Colors.teal,
      "Other": Colors.purple,};

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
                      GoalStatusData('Completed', completedGoals, Colors.green),
                      GoalStatusData('Pending', pendingGoals, Colors.red),
                    ],
                    xValueMapper: (GoalStatusData data, _) => data.status,
                    yValueMapper: (GoalStatusData data, _) => data.count,
                    pointColorMapper: (GoalStatusData data, _) => data.color,
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
              const SizedBox(height: 20),
              // New Chart for Total Goal Duration by Category
              const Text(
                'Total Goal Duration',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                title: ChartTitle(text: 'Total Duration of Goals (Minutes) by Category'),
                legend: Legend(isVisible: false),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries>[
                  ColumnSeries<DurationData, String>(
                    dataSource: totalDurationData,
                    xValueMapper: (DurationData data, _) => data.label,
                    yValueMapper: (DurationData data, _) => data.duration,
                    name: 'Total Duration',
                    pointColorMapper: (DurationData data, _) => categoryColors[data.label] ?? Colors.blueGrey,
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