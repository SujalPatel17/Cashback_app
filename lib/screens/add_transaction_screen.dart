import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/transaction_model.dart';
import '../notifications/notification_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  double _cashback = 0.0;
  double _finalCashback = 0.0;
  double _monthlyCashback = 0.0;

  final List<String> _categories = [
    'Online Shopping',
    'Bill Payment',
    'Others',
  ];

  double _getCashbackPercentage(String category) {
    switch (category) {
      case 'Online Shopping':
        return 5.0;
      case 'Bill Payment':
        return 2.5;
      default:
        return 1.0;
    }
  }

  Future<void> _calculateCashback() async {
    if (_selectedCategory != null && _amountController.text.isNotEmpty) {
      final amount = double.tryParse(_amountController.text);
      if (amount != null) {
        final percent = _getCashbackPercentage(_selectedCategory!);
        final calculatedCashback = amount * (percent / 100);

        final currentMonthCashback = await DBHelper().getMonthlyCashback(
          _selectedDate,
        );

        const cap = 400.0;
        final remaining = cap - currentMonthCashback;

        setState(() {
          _cashback = calculatedCashback;
          _monthlyCashback = currentMonthCashback;
          _finalCashback =
              remaining > 0
                  ? (calculatedCashback <= remaining
                      ? calculatedCashback
                      : remaining)
                  : 0.0;
        });
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final txn = TransactionModel(
        category: _selectedCategory!,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        cashback: _finalCashback,
      );

      await DBHelper().insertTransaction(txn);

      // Schedule the 90-day reminder notification
      final notificationDate = txn.date.add(const Duration(days: 90));
      await NotificationService().scheduleNotification(
        txn.id!,
        'Cashback Reminder',
        'Check your cashback for the transaction on ${DateFormat.yMMMd().format(txn.date)}.',
        notificationDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved and reminder set')),
      );

      Navigator.pop(context); // Go back to dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Transaction")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  _calculateCashback();
                },
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items:
                    _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                  _calculateCashback();
                },
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) => value == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}",
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _calculateCashback(); // recalculate when date changes
                      }
                    },
                    child: const Text("Select Date"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  Text(
                    "Calculated Cashback: ₹${_cashback.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Monthly Cap Used: ₹${_monthlyCashback.toStringAsFixed(2)} / ₹400",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Cashback Credited: ₹${_finalCashback.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _saveTransaction,
                icon: const Icon(Icons.save),
                label: const Text("Save Transaction"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
