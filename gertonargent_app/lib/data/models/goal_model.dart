class GoalModel {
  final int? id;
  final int userId;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String icon;
  final String color;
  final bool isCompleted;
  final DateTime createdAt;
  final double progressPercentage;

  GoalModel({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0,
    this.targetDate,
    this.icon = 'flag',
    this.color = '#00A86B',
    this.isCompleted = false,
    required this.createdAt,
    this.progressPercentage = 0,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'],
      userId: json['user_id'] ?? 1,
      name: json['name'],
      description: json['description'],
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'])
          : null,
      icon: json['icon'] ?? 'flag',
      color: json['color'] ?? '#00A86B',
      isCompleted: json['is_completed'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toIso8601String(),
      'icon': icon,
      'color': color,
    };
  }

  double get progress {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount * 100).clamp(0, 100);
  }

  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0, targetAmount);
  }

  int? get daysRemaining {
    if (targetDate == null) return null;
    return targetDate!.difference(DateTime.now()).inDays;
  }

  String get statusText {
    if (isCompleted) return 'Atteint';
    if (daysRemaining != null && daysRemaining! < 0) return 'En retard';
    return 'En cours';
  }

  String get statusIcon {
    if (isCompleted) return '✅';
    if (daysRemaining != null && daysRemaining! < 0) return '⚠️';
    return '🎯';
  }

  String get formattedProgress {
    return '${currentAmount.toStringAsFixed(0)} / ${targetAmount.toStringAsFixed(0)} FCFA';
  }

  GoalModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? icon,
    String? color,
    bool? isCompleted,
    DateTime? createdAt,
    double? progressPercentage,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }
}

class GoalSummary {
  final int totalGoals;
  final int completed;
  final int inProgress;
  final double totalTargetAmount;
  final double totalSavedAmount;
  final double overallProgress;

  GoalSummary({
    required this.totalGoals,
    required this.completed,
    required this.inProgress,
    required this.totalTargetAmount,
    required this.totalSavedAmount,
    required this.overallProgress,
  });

  factory GoalSummary.fromJson(Map<String, dynamic> json) {
    return GoalSummary(
      totalGoals: json['total_goals'] ?? 0,
      completed: json['completed'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
      totalTargetAmount: (json['total_target_amount'] as num).toDouble(),
      totalSavedAmount: (json['total_saved_amount'] as num).toDouble(),
      overallProgress: (json['overall_progress'] as num).toDouble(),
    );
  }
}
