import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/db_helper.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

String _selectedFilter = 'This Month';
final List<String> _filters = ['This Month', 'Last 3 Months', 'All Time'];

String selectedCategory = 'All';
List<String> categories = [
  'All',
  'Online Shopping',
  'Bill Payments',
  'Offline Spends',
];

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<TransactionModel> _transactions = [];
  Map<String, double> _spendingCategories = {};
  double _totalCashback = 0.0;
  double _cappedCashback = 0.0;
  bool _isLoading = true; // Add a loading state

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final allTransactions = await DBHelper().getAllTransactions();
    final now = DateTime.now();
    DateTime? startDate;

    if (_selectedFilter == 'This Month') {
      startDate = DateTime(now.year, now.month, 1);
    } else if (_selectedFilter == 'Last 3 Months') {
      startDate = DateTime(now.year, now.month - 2, 1);
    }

    final filteredTransactions =
        startDate != null
            ? allTransactions
                .where(
                  (txn) =>
                      txn.date.isAfter(startDate!) ||
                      txn.date.isAtSameMomentAs(startDate),
                )
                .toList()
            : allTransactions;

    final categoryData = <String, double>{};
    double totalCashback = 0.0;
    double cappedCashback = 0.0;
    Map<String, double> monthlyCashback = {};

    for (var txn in filteredTransactions) {
      totalCashback += txn.cashback;

      final key = '${txn.date.year}-${txn.date.month}';
      monthlyCashback[key] = (monthlyCashback[key] ?? 0.0) + txn.cashback;

      categoryData[txn.category] =
          (categoryData[txn.category] ?? 0) + txn.amount;
    }

    for (var monthly in monthlyCashback.values) {
      cappedCashback += monthly > 400 ? 400 : monthly;
    }

    setState(() {
      _transactions = filteredTransactions;
      _spendingCategories = categoryData;
      _totalCashback = totalCashback;
      _cappedCashback = cappedCashback;
      _isLoading = false; // Set loading to false when data is fetched
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Analytics',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items:
                      _filters.map((filter) {
                        return DropdownMenuItem<String>(
                          value: filter,
                          child: Text(filter),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFilter = value;
                      });
                      _loadTransactions();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total Cashback: ₹${_totalCashback.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Display capped cashback
            Text(
              'Capped Cashback: ₹${_cappedCashback.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            const Text(
              'Spending by Category:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSpendingChart(),
            const SizedBox(height: 30),
            const Text(
              'Cashback Progress:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildCashbackProgressChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingChart() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      ); // Show loading indicator while data is being fetched
    }

    if (_spendingCategories.isEmpty) {
      return const Center(
        child: Text(
          'No data found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections:
            _spendingCategories.entries.map((entry) {
              final category = entry.key;
              final amount = entry.value;
              return PieChartSectionData(
                value: amount,
                title: category,
                color:
                    Colors.primaries[_spendingCategories.keys.toList().indexOf(
                          category,
                        ) %
                        Colors.primaries.length],
                radius: 50,
              );
            }).toList(),
        borderData: FlBorderData(show: false),
        sectionsSpace: 0,
      ),
    );
  }

  Widget _buildCashbackProgressChart() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      ); // Show loading indicator while data is being fetched
    }

    if (_transactions.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final monthNames = List.generate(
      12,
      (index) => DateFormat.MMMM().format(DateTime(2023, index + 1)),
    );

    final cashbackData = List.generate(
      12,
      (index) => _transactions
          .where((txn) => txn.date.month == index + 1)
          .fold(0.0, (sum, txn) => sum + txn.cashback),
    );

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('₹${value.toStringAsFixed(0)}');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(monthNames[value.toInt()]);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(12, (index) {
          return BarChartGroupData(
            x: index,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: cashbackData[index],
                color: Colors.blue,
                width: 16,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          );
        }),
      ),
    );
  }
}
