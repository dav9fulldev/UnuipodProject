enum GoalStatus { inProgress, completed, cancelled }

class GoalModel {
  final String? id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final GoalStatus status;
  final String? userId;

  GoalModel({
    this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.deadline,
    this.status = GoalStatus.inProgress,
    this.userId,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id']?.toString(),
      title: json['title'],
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      deadline: DateTime.parse(json['deadline']),
      status: GoalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GoalStatus.inProgress,
      ),
      userId: json['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'status': status.name,
    };
  }

  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount * 100).clamp(0, 100);
  }

  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0, targetAmount);
  }

  int get daysRemaining {
    return deadline.difference(DateTime.now()).inDays;
  }

  bool get isCompleted => currentAmount >= targetAmount;

  String getStatusIcon() {
    switch (status) {
      case GoalStatus.completed:
        return '✅';
      case GoalStatus.cancelled:
        return '❌';
      case GoalStatus.inProgress:
        return '🎯';
    }
  }
}
