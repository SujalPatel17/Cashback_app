class TransactionModel {
  final int? id;
  final String category;
  final double amount;
  final DateTime date;
  final double cashback;
  final bool cashbackChecked;

  TransactionModel({
    this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.cashback,
    this.cashbackChecked = false,
  }) {
    // Optional: Add validation to ensure positive amount
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero');
    }
  }

  // Convert to Map for DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'cashback': cashback,
      'cashbackChecked': cashbackChecked ? 1 : 0,
    };
  }

  // Convert from DB to Model
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      cashback: map['cashback'],
      cashbackChecked: map['cashbackChecked'] == 1,
    );
  }
}
