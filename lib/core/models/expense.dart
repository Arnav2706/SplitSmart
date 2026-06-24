class ExpenseSplit {
  final String userId;
  final int share; // amount in paise for EXACT/EQUAL, percentage for PERCENTAGE, or parts for SHARES

  const ExpenseSplit({
    required this.userId,
    required this.share,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      userId: json['userId'] as String,
      share: json['share'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'share': share,
    };
  }
}

enum SplitType { equal, percentage, exact, shares }

class Expense {
  final String id;
  final String groupId;
  final String description;
  final int amount; // in paise
  final String category;
  final String paidBy;
  final SplitType splitType;
  final List<ExpenseSplit> splits;
  final DateTime date;
  final bool isRecurring;
  final String? recurInterval;

  const Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.category,
    required this.paidBy,
    required this.splitType,
    required this.splits,
    required this.date,
    this.isRecurring = false,
    this.recurInterval,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      description: json['description'] as String,
      amount: json['amount'] as int,
      category: json['category'] as String,
      paidBy: json['paidBy'] as String,
      splitType: SplitType.values.firstWhere(
        (e) => e.name == json['splitType'],
        orElse: () => SplitType.equal,
      ),
      splits: (json['splits'] as List<dynamic>?)
              ?.map((e) => ExpenseSplit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      date: json['date'] != null 
          ? DateTime.parse(json['date'] as String) 
          : DateTime.now(),
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurInterval: json['recurInterval'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'category': category,
      'paidBy': paidBy,
      'splitType': splitType.name,
      'splits': splits.map((e) => e.toJson()).toList(),
      'date': date.toIso8601String(),
      'isRecurring': isRecurring,
      'recurInterval': recurInterval,
    };
  }
}
