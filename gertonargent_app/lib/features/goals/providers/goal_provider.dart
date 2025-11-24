import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/goal_model.dart';
import '../../auth/providers/auth_provider.dart';

final goalProvider = StateNotifierProvider<GoalNotifier, GoalState>((ref) {
  return GoalNotifier(ref.read(apiServiceProvider));
});

class GoalState {
  final List<GoalModel> goals;
  final GoalSummary? summary;
  final bool isLoading;
  final String? error;

  GoalState({
    this.goals = const [],
    this.summary,
    this.isLoading = false,
    this.error,
  });

  GoalState copyWith({
    List<GoalModel>? goals,
    GoalSummary? summary,
    bool? isLoading,
    String? error,
  }) {
    return GoalState(
      goals: goals ?? this.goals,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<GoalModel> get activeGoals {
    return goals.where((g) => !g.isCompleted).toList();
  }

  List<GoalModel> get completedGoals {
    return goals.where((g) => g.isCompleted).toList();
  }

  double get totalTargetAmount {
    return activeGoals.fold(0, (sum, g) => sum + g.targetAmount);
  }

  double get totalSavedAmount {
    return activeGoals.fold(0, (sum, g) => sum + g.currentAmount);
  }

  double get overallProgress {
    if (totalTargetAmount == 0) return 0;
    return (totalSavedAmount / totalTargetAmount * 100).clamp(0, 100);
  }
}

class GoalNotifier extends StateNotifier<GoalState> {
  final ApiService _apiService;

  GoalNotifier(this._apiService) : super(GoalState());

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getGoals();
      final goals = response.map((json) => GoalModel.fromJson(json)).toList();

      // Charger le résumé
      final summaryResponse = await _apiService.getGoalsSummary();
      final summary = GoalSummary.fromJson(summaryResponse);

      state = state.copyWith(
        goals: goals,
        summary: summary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createGoal({
    required String name,
    String? description,
    required double targetAmount,
    DateTime? targetDate,
    String icon = 'flag',
    String color = '#00A86B',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.createGoal(
        name: name,
        description: description,
        targetAmount: targetAmount,
        targetDate: targetDate,
        icon: icon,
        color: color,
      );

      await loadGoals();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> addToGoal({
    required int goalId,
    required double amount,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.addToGoal(
        goalId: goalId,
        amount: amount,
      );

      await loadGoals();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateGoal({
    required int goalId,
    String? name,
    String? description,
    double? targetAmount,
    DateTime? targetDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.updateGoal(
        goalId: goalId,
        name: name,
        description: description,
        targetAmount: targetAmount,
        targetDate: targetDate,
      );

      await loadGoals();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteGoal(int goalId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.deleteGoal(goalId);
      await loadGoals();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
