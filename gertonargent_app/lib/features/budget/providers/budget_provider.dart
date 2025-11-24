import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/budget_model.dart';
import '../../auth/providers/auth_provider.dart';

final budgetProvider =
    StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  return BudgetNotifier(ref.read(apiServiceProvider));
});

class BudgetState {
  final List<BudgetModel> budgets;
  final BudgetSummary? summary;
  final bool isLoading;
  final String? error;

  BudgetState({
    this.budgets = const [],
    this.summary,
    this.isLoading = false,
    this.error,
  });

  double get totalBudget => budgets.fold(0, (sum, b) => sum + b.monthlyLimit);
  double get totalSpent => budgets.fold(0, (sum, b) => sum + b.currentSpent);
  double get totalRemaining => totalBudget - totalSpent;

  BudgetState copyWith({
    List<BudgetModel>? budgets,
    BudgetSummary? summary,
    bool? isLoading,
    String? error,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  final ApiService _apiService;

  BudgetNotifier(this._apiService) : super(BudgetState());

  Future<void> loadBudgets() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getBudgets();
      final budgets =
          response.map((json) => BudgetModel.fromJson(json)).toList();

      // Charger aussi le résumé
      final summaryResponse = await _apiService.getBudgetsSummary();
      final summary = BudgetSummary.fromJson(summaryResponse);

      state = state.copyWith(
        budgets: budgets,
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

  Future<bool> createBudget({
    required BudgetCategory category,
    required double monthlyLimit,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.createBudget(
        category: category.name,
        monthlyLimit: monthlyLimit,
      );

      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateBudget({
    required int budgetId,
    double? monthlyLimit,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.updateBudget(
        budgetId: budgetId,
        monthlyLimit: monthlyLimit,
      );

      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteBudget(int budgetId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.deleteBudget(budgetId);
      await loadBudgets();
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
