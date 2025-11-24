enum BudgetCategory {
  alimentation,
  transport,
  logement,
  sante,
  education,
  loisirs,
  epargne,
  vetements,
  communication,
  autre;

  String get displayName {
    switch (this) {
      case BudgetCategory.alimentation:
        return 'Alimentation';
      case BudgetCategory.transport:
        return 'Transport';
      case BudgetCategory.logement:
        return 'Logement';
      case BudgetCategory.sante:
        return 'Santé';
      case BudgetCategory.education:
        return 'Éducation';
      case BudgetCategory.loisirs:
        return 'Loisirs';
      case BudgetCategory.epargne:
        return 'Épargne';
      case BudgetCategory.vetements:
        return 'Vêtements';
      case BudgetCategory.communication:
        return 'Communication';
      case BudgetCategory.autre:
        return 'Autre';
    }
  }

  String get icon {
    switch (this) {
      case BudgetCategory.alimentation:
        return '🍽️';
      case BudgetCategory.transport:
        return '🚗';
      case BudgetCategory.logement:
        return '🏠';
      case BudgetCategory.sante:
        return '⚕️';
      case BudgetCategory.education:
        return '📚';
      case BudgetCategory.loisirs:
        return '🎮';
      case BudgetCategory.epargne:
        return '💰';
      case BudgetCategory.vetements:
        return '👕';
      case BudgetCategory.communication:
        return '📱';
      case BudgetCategory.autre:
        return '📌';
    }
  }
}

class BudgetModel {
  final int id;
  final int userId;
  final BudgetCategory category;
  final double monthlyLimit;
  final double currentSpent;
  final double remaining;
  final double usagePercentage;
  final DateTime? periodStart;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.monthlyLimit,
    required this.currentSpent,
    this.remaining = 0,
    this.usagePercentage = 0,
    this.periodStart,
  });

  double get remainingBudget => monthlyLimit - currentSpent;
  double get percentageUsed => monthlyLimit > 0 ? (currentSpent / monthlyLimit) * 100 : 0;

  String get statusColor {
    if (percentageUsed >= 90) return 'red';
    if (percentageUsed >= 70) return 'orange';
    return 'green';
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      userId: json['user_id'] ?? 1,
      category: BudgetCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => BudgetCategory.autre,
      ),
      monthlyLimit: (json['monthly_limit'] as num).toDouble(),
      currentSpent: (json['current_spent'] as num).toDouble(),
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
      usagePercentage: (json['usage_percentage'] as num?)?.toDouble() ?? 0,
      periodStart: json['period_start'] != null
          ? DateTime.parse(json['period_start'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category.name,
      'monthly_limit': monthlyLimit,
      'current_spent': currentSpent,
    };
  }

  BudgetModel copyWith({
    int? id,
    int? userId,
    BudgetCategory? category,
    double? monthlyLimit,
    double? currentSpent,
    double? remaining,
    double? usagePercentage,
    DateTime? periodStart,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentSpent: currentSpent ?? this.currentSpent,
      remaining: remaining ?? this.remaining,
      usagePercentage: usagePercentage ?? this.usagePercentage,
      periodStart: periodStart ?? this.periodStart,
    );
  }
}

class BudgetSummary {
  final double totalMonthlyLimit;
  final double totalSpent;
  final double totalRemaining;
  final double overallUsagePercentage;
  final int budgetCount;

  BudgetSummary({
    required this.totalMonthlyLimit,
    required this.totalSpent,
    required this.totalRemaining,
    required this.overallUsagePercentage,
    required this.budgetCount,
  });

  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    return BudgetSummary(
      totalMonthlyLimit: (json['total_monthly_limit'] as num).toDouble(),
      totalSpent: (json['total_spent'] as num).toDouble(),
      totalRemaining: (json['total_remaining'] as num).toDouble(),
      overallUsagePercentage: (json['overall_usage_percentage'] as num).toDouble(),
      budgetCount: json['budget_count'] ?? 0,
    );
  }
}
