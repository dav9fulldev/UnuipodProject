import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_provider.dart';
import 'create_budget_page.dart';

class BudgetListPage extends ConsumerStatefulWidget {
  const BudgetListPage({super.key});

  @override
  ConsumerState<BudgetListPage> createState() => _BudgetListPageState();
}

class _BudgetListPageState extends ConsumerState<BudgetListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(budgetProvider.notifier).loadBudgets());
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Budgets'),
      ),
      body: budgetState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : budgetState.budgets.isEmpty
              ? const Center(
                  child: Text('Aucun budget. Créez-en un !'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: budgetState.budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgetState.budgets[index];
                    final percentage = budget.percentageUsed;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  budget.category.name.toUpperCase(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: percentage > 80
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${budget.currentSpent.toStringAsFixed(0)} FCFA / ${budget.monthlyLimit.toStringAsFixed(0)} FCFA',
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentage > 80 ? Colors.red : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reste: ${budget.remainingBudget.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
