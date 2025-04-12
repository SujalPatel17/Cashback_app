import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/transaction_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _totalSpent = 0;
  double _totalCashback = 0;
  List<TransactionModel> _pendingCashbacks = [];
  bool _isLoading = true;
  double _maxCashback = 400.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true; // Show loading indicator while fetching data
    });

    final transactions = await DBHelper().getAllTransactions();
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0);

    double totalSpent = 0;
    double totalCashback = 0;

    for (var txn in transactions) {
      if (txn.date.isAfter(currentMonthStart) &&
          txn.date.isBefore(currentMonthEnd.add(Duration(days: 1)))) {
        totalSpent += txn.amount;
        totalCashback += txn.cashback;
      }
    }

    final pending = await DBHelper().getPendingCashbackChecks();

    // Calculate the remaining cashback for the month
    double remainingCashback = _maxCashback - totalCashback;

    setState(() {
      _totalSpent = totalSpent;
      _totalCashback = totalCashback;
      _pendingCashbacks = pending;
      _isLoading = false; // Hide loading indicator once data is fetched
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text("Cashback Dashboard")),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(),
              ) // Show loading spinner while data is loading
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: const Text("Total Spending (This Month)"),
                        subtitle: Text(formatter.format(_totalSpent)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: const Text("Total Cashback Earned"),
                        subtitle: Text(formatter.format(_totalCashback)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Cashback progress card
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: const Text("Cashback Status (₹400 Cap)"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cashback Earned: ₹${_totalCashback.toStringAsFixed(2)}",
                            ),
                            Text(
                              "Remaining Cashback: ₹${(_maxCashback - _totalCashback).toStringAsFixed(2)}",
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Pending Cashback Checks",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_pendingCashbacks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("🎉 No pending cashback checks"),
                      )
                    else
                      ..._pendingCashbacks.map(
                        (txn) => Card(
                          child: ListTile(
                            title: Text(txn.category),
                            subtitle: Text(
                              "₹${txn.amount} on ${DateFormat.yMMMd().format(txn.date)}",
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                await DBHelper().markCashbackChecked(txn.id!);
                                _loadDashboardData(); // Reload dashboard data after marking as checked
                              },
                              child: const Text("Mark as Checked"),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/add');
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Transaction"),
      ),
    );
  }
}
