enum TransactionType { income, outgoing }

class Transaction {
  final int? id;
  final int profileId;
  final TransactionType type;
  final double amount;
  final String description;
  final int categoryId;
  final String? categoryName; // For display purposes
  final int quantity;
  final DateTime timestamp;
  final bool isRecurrent;
  final String? recurrenceType; // 'daily', 'weekly', 'monthly'
  final DateTime? recurrenceEndDate;
  final DateTime? lastAppliedDate;

  Transaction({
    this.id,
    required this.profileId,
    required this.type,
    required this.amount,
    required this.description,
    required this.categoryId,
    this.categoryName,
    required this.quantity,
    required this.timestamp,
    this.isRecurrent = false,
    this.recurrenceType,
    this.recurrenceEndDate,
    this.lastAppliedDate,
  });

  // This map is for writing to the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'description': description,
      'categoryId': categoryId,
      'quantity': quantity,
      'timestamp': timestamp.toIso8601String(),
      'isRecurrent': isRecurrent ? 1 : 0,
      'recurrenceType': recurrenceType,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'lastAppliedDate': lastAppliedDate?.toIso8601String(),
    };
  }

  // This factory is for reading from the database
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      profileId: map['profileId'],
      type: TransactionType.values.firstWhere(
              (e) => e.toString().split('.').last == map['type']),
      amount: map['amount'],
      description: map['description'],
      categoryId: map['categoryId'],
      categoryName: map['categoryName'], // From JOIN query
      quantity: map['quantity'],
      timestamp: DateTime.parse(map['timestamp']),
      isRecurrent: map['isRecurrent'] == 1,
      recurrenceType: map['recurrenceType'],
      recurrenceEndDate: map['recurrenceEndDate'] != null
          ? DateTime.parse(map['recurrenceEndDate'])
          : null,
      lastAppliedDate: map['lastAppliedDate'] != null
          ? DateTime.parse(map['lastAppliedDate'])
          : null,
    );
  }
}