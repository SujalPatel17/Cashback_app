import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class PendingCheckScreen extends StatefulWidget {
  const PendingCheckScreen({super.key});

  @override
  _PendingCheckScreenState createState() => _PendingCheckScreenState();
}

class _PendingCheckScreenState extends State<PendingCheckScreen> {
  List<TransactionModel> _pendingTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadPendingTransactions();
  }

  Future<void> _loadPendingTransactions() async {
    final pendingTransactions = await DBHelper().getPendingCashbackChecks();
    setState(() {
      _pendingTransactions = pendingTransactions;
    });
  }

  Future<void> _markAsChecked(TransactionModel txn) async {
    await DBHelper().markCashbackChecked(txn.id!);
    _loadPendingTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Cashback Checks')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _pendingTransactions.isEmpty
                ? const Center(child: Text('No pending cashback transactions.'))
                : ListView.builder(
                  itemCount: _pendingTransactions.length,
                  itemBuilder: (context, index) {
                    final txn = _pendingTransactions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    txn.category,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${txn.amount.toStringAsFixed(2)} on ${DateFormat.yMMMd().format(txn.date)}',
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade50,
                                foregroundColor: Colors.teal.shade800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                _markAsChecked(txn);
                              },
                              child: const Text('Mark as Checked'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
