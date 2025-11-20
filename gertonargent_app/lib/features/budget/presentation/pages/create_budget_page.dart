import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/budget_model.dart';
import '../../providers/budget_provider.dart';

class CreateBudgetPage extends ConsumerStatefulWidget {
  const CreateBudgetPage({super.key});

  @override
  ConsumerState<CreateBudgetPage> createState() => _CreateBudgetPageState();
}

class _CreateBudgetPageState extends ConsumerState<CreateBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  BudgetCategory _selectedCategory = BudgetCategory.alimentation;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _createBudget() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(budgetProvider.notifier).createBudget(
            category: _selectedCategory,
            monthlyLimit: double.parse(_amountController.text),
          );

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un budget'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<BudgetCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: BudgetCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant mensuel (FCFA)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Entrez un montant';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (budgetState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    budgetState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: budgetState.isLoading ? null : _createBudget,
                  child: budgetState.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Créer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
