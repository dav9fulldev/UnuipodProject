import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/goal_model.dart';

final goalProvider = StateNotifierProvider<GoalNotifier, GoalState>((ref) {
  return GoalNotifier();
});

class GoalState {
  final List<GoalModel> goals;
  final bool isLoading;
  final String? error;

  GoalState({
    this.goals = const [],
    this.isLoading = false,
    this.error,
  });

  GoalState copyWith({
    List<GoalModel>? goals,
    bool? isLoading,
    String? error,
  }) {
    return GoalState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Objectifs actifs
  List<GoalModel> get activeGoals {
    return goals.where((g) => g.status == GoalStatus.inProgress).toList();
  }

  // Objectifs complétés
  List<GoalModel> get completedGoals {
    return goals.where((g) => g.status == GoalStatus.completed).toList();
  }

  // Total des objectifs
  double get totalTargetAmount {
    return activeGoals.fold(0, (sum, g) => sum + g.targetAmount);
  }

  // Total économisé
  double get totalSavedAmount {
    return activeGoals.fold(0, (sum, g) => sum + g.currentAmount);
  }
}

class GoalNotifier extends StateNotifier<GoalState> {
  GoalNotifier() : super(GoalState());

  void addGoal(GoalModel goal) {
    state = state.copyWith(
      goals: [...state.goals, goal],
    );
  }

  void updateGoalProgress(String goalId, double amount) {
    final updatedGoals = state.goals.map((goal) {
      if (goal.id == goalId) {
        final newAmount = goal.currentAmount + amount;
        final newStatus = newAmount >= goal.targetAmount
            ? GoalStatus.completed
            : GoalStatus.inProgress;

        return GoalModel(
          id: goal.id,
          title: goal.title,
          targetAmount: goal.targetAmount,
          currentAmount: newAmount,
          deadline: goal.deadline,
          status: newStatus,
          userId: goal.userId,
        );
      }
      return goal;
    }).toList();

    state = state.copyWith(goals: updatedGoals);
  }

  void deleteGoal(String goalId) {
    state = state.copyWith(
      goals: state.goals.where((g) => g.id != goalId).toList(),
    );
  }

  void loadGoals() {
    // TODO: Charger depuis le backend
    state = state.copyWith(isLoading: true);

    Future.delayed(const Duration(seconds: 1), () {
      state = state.copyWith(
        isLoading: false,
        goals: [],
      );
    });
  }
}
