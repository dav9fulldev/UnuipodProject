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
  final bool isLoading;
  final String? error;

  BudgetState({
    this.budgets = const [],
    this.isLoading = false,
    this.error,
  });

  BudgetState copyWith({
    List<BudgetModel>? budgets,
    bool? isLoading,
    String? error,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
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

      state = state.copyWith(
        budgets: budgets,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de chargement: $e',
      );
    }
  }

  Future<void> createBudget({
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de création: $e',
      );
    }
  }
}
