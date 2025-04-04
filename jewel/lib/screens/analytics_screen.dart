import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales Data',
              ),
              const SizedBox(height: 10),
              SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                title: ChartTitle(text: 'Monthly Sales'),
                legend: Legend(isVisible: true),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries>[
                  ColumnSeries<SalesData, String>(
                    dataSource: [
                      SalesData('Jan', 35),
                      SalesData('Feb', 28),
                      SalesData('Mar', 34),
                      SalesData('Apr', 32),
                      SalesData('May', 40),
                    ],
                    xValueMapper: (SalesData sales, _) => sales.month,
                    yValueMapper: (SalesData sales, _) => sales.sales,
                    name: 'Sales',
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Expense Breakdown',
              ),
              const SizedBox(height: 10),
              SfCircularChart(
                title: ChartTitle(text: 'Expense Categories'),
                legend: Legend(isVisible: true),
                series: <CircularSeries>[
                  PieSeries<ExpenseData, String>(
                    dataSource: [
                      ExpenseData('Rent', 40),
                      ExpenseData('Food', 30),
                      ExpenseData('Transport', 15),
                      ExpenseData('Others', 15),
                    ],
                    xValueMapper: (ExpenseData data, _) => data.category,
                    yValueMapper: (ExpenseData data, _) => data.amount,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
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

class SalesData {
  final String month;
  final double sales;

  SalesData(this.month, this.sales);
}

class ExpenseData {
  final String category;
  final double amount;

  ExpenseData(this.category, this.amount);
}