import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/budget_model.dart';
import '../../providers/budget_provider.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_button.dart';

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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Budget créé avec succès !'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Créer un budget',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Illustration
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 64,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Catégorie
                DropdownButtonFormField<BudgetCategory>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  items: BudgetCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        category.name.toUpperCase(),
                        style: textTheme.bodyMedium,
                      ),
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
                
                const SizedBox(height: 24),

                // Montant
                CustomTextField(
                  controller: _amountController,
                  label: 'Montant mensuel',
                  hint: 'Ex: 50000',
                  prefixIcon: Icons.attach_money,
                  suffixText: 'FCFA',
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
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),

                // Bouton Créer
                CustomButton(
                  text: 'Créer le budget',
                  onPressed: budgetState.isLoading ? null : _createBudget,
                  isLoading: budgetState.isLoading,
                  icon: Icons.check,
                  type: ButtonType.filled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
