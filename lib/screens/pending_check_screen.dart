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

  // Load transactions that are 90 days old and not checked for cashback yet
  Future<void> _loadPendingTransactions() async {
    final pendingTransactions = await DBHelper().getPendingCashbackChecks();

    setState(() {
      _pendingTransactions = pendingTransactions;
    });
  }

  // Mark transaction as checked for cashback
  Future<void> _markAsChecked(TransactionModel txn) async {
    await DBHelper().markCashbackChecked(txn.id!);
    _loadPendingTransactions(); // Reload the pending transactions
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Cashback Check')),
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
                      child: ListTile(
                        title: Text(txn.category),
                        subtitle: Text(
                          'Amount: ₹${txn.amount.toStringAsFixed(2)}\n'
                          'Date: ${DateFormat.yMd().format(txn.date)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle),
                          onPressed: () {
                            _markAsChecked(txn);
                          },
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
