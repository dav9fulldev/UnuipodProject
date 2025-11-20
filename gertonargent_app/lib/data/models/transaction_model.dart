enum TransactionType { income, expense }

enum TransactionCategory {
  alimentation,
  transport,
  logement,
  sante,
  education,
  loisirs,
  shopping,
  autre,
}

class TransactionModel {
  final String? id;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String description;
  final DateTime date;
  final String? userId;

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.userId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString(),
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TransactionCategory.autre,
      ),
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
      userId: json['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  String getCategoryIcon() {
    switch (category) {
      case TransactionCategory.alimentation:
        return '🍽️';
      case TransactionCategory.transport:
        return '🚗';
      case TransactionCategory.logement:
        return '🏠';
      case TransactionCategory.sante:
        return '⚕️';
      case TransactionCategory.education:
        return '📚';
      case TransactionCategory.loisirs:
        return '🎮';
      case TransactionCategory.shopping:
        return '🛍️';
      case TransactionCategory.autre:
        return '📌';
    }
  }
}
