import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/transaction_model.dart';

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier();
});

class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? error;

  TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Calculer le solde total
  double get balance {
    double total = 0;
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        total += transaction.amount;
      } else {
        total -= transaction.amount;
      }
    }
    return total;
  }

  // Dépenses du mois en cours
  double get monthlyExpenses {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Revenus du mois en cours
  double get monthlyIncome {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0, (sum, t) => sum + t.amount);
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  TransactionNotifier() : super(TransactionState());

  void addTransaction(TransactionModel transaction) {
    state = state.copyWith(
      transactions: [...state.transactions, transaction],
    );
  }

  void loadTransactions() {
    // TODO: Charger depuis le backend
    state = state.copyWith(isLoading: true);

    // Simuler des données pour le moment
    Future.delayed(const Duration(seconds: 1), () {
      state = state.copyWith(
        isLoading: false,
        transactions: [],
      );
    });
  }

  void deleteTransaction(String id) {
    state = state.copyWith(
      transactions: state.transactions.where((t) => t.id != id).toList(),
    );
  }
}
