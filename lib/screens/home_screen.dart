import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isLoading = true;
  double _maxCashback = 400.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _checkAndRequestPermission();
  }

  Future<void> _checkAndRequestPermission() async {
    // Get SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();
    // Check if the notification permission has been requested before
    bool isPermissionRequested =
        prefs.getBool('isPermissionRequested') ?? false;

    if (!isPermissionRequested) {
      // Request permission
      final status = await Permission.notification.request();

      if (status.isGranted) {
        // Store that permission has been requested
        await prefs.setBool('isPermissionRequested', true);
      } else {
        // Handle the case when permission is denied
        print("Permission not granted");
      }
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    final transactions = await DBHelper().getAllTransactions();
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0);

    double totalSpent = 0;
    double totalCashback = 0;

    for (var txn in transactions) {
      if (txn.date.isAfter(currentMonthStart) &&
          txn.date.isBefore(currentMonthEnd.add(const Duration(days: 1)))) {
        totalSpent += txn.amount;
        totalCashback += txn.cashback;
      }
    }

    setState(() {
      _totalSpent = totalSpent;
      _totalCashback = totalCashback;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text("Cashback Dashboard")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
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
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add');
          if (result == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Transaction added successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _loadDashboardData(); // Refresh data after new transaction
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Transaction"),
      ),
    );
  }
}
