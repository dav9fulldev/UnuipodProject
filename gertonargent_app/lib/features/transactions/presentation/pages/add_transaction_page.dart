import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_button.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  TransactionCategory _category = TransactionCategory.alimentation;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addTransaction() {
    if (_formKey.currentState!.validate()) {
      final transaction = TransactionModel(
        amount: double.parse(_amountController.text),
        type: _type,
        category: _category,
        description: _descriptionController.text,
        date: _selectedDate,
      );

      ref.read(transactionProvider.notifier).addTransaction(transaction);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaction ajoutée avec succès !'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Nouvelle transaction',
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
                // Type de transaction
                Center(
                  child: SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment<TransactionType>(
                        value: TransactionType.expense,
                        label: Text('Dépense'),
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                      ButtonSegment<TransactionType>(
                        value: TransactionType.income,
                        label: Text('Revenu'),
                        icon: Icon(Icons.add_circle_outline),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (Set<TransactionType> newSelection) {
                      setState(() {
                        _type = newSelection.first;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) {
                            return _type == TransactionType.expense 
                                ? colorScheme.errorContainer 
                                : colorScheme.primaryContainer;
                          }
                          return colorScheme.surface;
                        },
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) {
                            return _type == TransactionType.expense 
                                ? colorScheme.onErrorContainer 
                                : colorScheme.onPrimaryContainer;
                          }
                          return colorScheme.onSurface;
                        },
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // Montant
                CustomTextField(
                  controller: _amountController,
                  label: 'Montant',
                  hint: '0',
                  prefixIcon: Icons.attach_money,
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

                // Catégorie
                DropdownButtonFormField<TransactionCategory>(
                  value: _category,
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  items: TransactionCategory.values.map((category) {
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
                        _category = value;
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 24),

                // Date
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                    child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: textTheme.bodyLarge,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Description
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Ex: Achat de provisions',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Entrez une description';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 40),

                // Bouton d'ajout
                CustomButton(
                  text: 'Ajouter la transaction',
                  onPressed: _addTransaction,
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
