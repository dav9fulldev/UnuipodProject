enum BudgetCategory {
  alimentation,
  transport,
  logement,
  sante,
  education,
  loisirs,
  epargne,
  autre
}

class BudgetModel {
  final int id;
  final BudgetCategory category;
  final double monthlyLimit;
  final double currentSpent;

  BudgetModel({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.currentSpent,
  });

  double get remainingBudget => monthlyLimit - currentSpent;
  double get percentageUsed => (currentSpent / monthlyLimit) * 100;

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      category: BudgetCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      monthlyLimit: json['monthly_limit'].toDouble(),
      currentSpent: json['current_spent'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'monthly_limit': monthlyLimit,
      'current_spent': currentSpent,
    };
  }
}
