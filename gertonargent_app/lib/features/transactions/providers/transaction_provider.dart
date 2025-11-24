import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/budget_model.dart';
import '../../auth/providers/auth_provider.dart';

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref.read(apiServiceProvider));
});

class TransactionState {
  final List<TransactionModel> transactions;
  final TransactionSummary? summary;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? lastAnalysis;
  final double monthlyIncome;
  final double monthlyExpenses;

  TransactionState({
    this.transactions = const [],
    this.summary,
    this.isLoading = false,
    this.error,
    this.lastAnalysis,
    this.monthlyIncome = 0,
    this.monthlyExpenses = 0,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    TransactionSummary? summary,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? lastAnalysis,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastAnalysis: lastAnalysis ?? this.lastAnalysis,
    );
  }

  double get totalExpenses =>
      summary?.totalExpenses ??
      transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0, (sum, t) => sum + t.amount);

  double get totalIncome =>
      summary?.totalIncome ??
      transactions
          .where((t) => t.type == TransactionType.income)
          .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpenses;

  List<TransactionModel> get recentTransactions {
    final sorted = [...transactions];
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(10).toList();
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final ApiService _apiService;

  TransactionNotifier(this._apiService) : super(TransactionState());

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getTransactions();
      final transactions =
          response.map((json) => TransactionModel.fromJson(json)).toList();

      // Charger le résumé
      final summaryResponse = await _apiService.getTransactionsSummary();
      final summary = TransactionSummary.fromJson(summaryResponse);

      state = state.copyWith(
        transactions: transactions,
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

  Future<Map<String, dynamic>?> analyzeTransaction({
    required double amount,
    required BudgetCategory category,
    String? description,
  }) async {
    try {
      final analysis = await _apiService.analyzeTransaction(
        amount: amount,
        category: category.name,
        description: description,
      );
      state = state.copyWith(lastAnalysis: analysis);
      return analysis;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createTransaction({
    required double amount,
    required BudgetCategory category,
    String? description,
    TransactionType type = TransactionType.expense,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.createTransaction(
        amount: amount,
        category: category.name,
        description: description,
        transactionType: type.name,
      );

      await loadTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteTransaction(int transactionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.deleteTransaction(transactionId);
      await loadTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearAnalysis() {
    state = state.copyWith(lastAnalysis: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
