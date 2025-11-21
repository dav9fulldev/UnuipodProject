import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';

class IncomeStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const IncomeStep({super.key, required this.onNext});

  @override
  ConsumerState<IncomeStep> createState() => _IncomeStepState();
}

class _IncomeStepState extends ConsumerState<IncomeStep> {
  String? _selectedIncome;

  final List<Map<String, dynamic>> _incomeRanges = [
    {
      'label': 'Moins de 50,000 FCFA',
      'value': '0-50000',
      'color': const Color(0xFF9C27B0)
    },
    {
      'label': '50,000 - 100,000 FCFA',
      'value': '50000-100000',
      'color': const Color(0xFF2196F3)
    },
    {
      'label': '100,000 - 250,000 FCFA',
      'value': '100000-250000',
      'color': const Color(0xFF00A86B)
    },
    {
      'label': '250,000 - 500,000 FCFA',
      'value': '250000-500000',
      'color': const Color(0xFFFF9800)
    },
    {
      'label': '500,000+ FCFA',
      'value': '500000+',
      'color': const Color(0xFFFF6B00)
    },
  ];

  void _selectIncome(String value) {
    setState(() {
      _selectedIncome = value;
    });
  }

  void _submit() {
    if (_selectedIncome != null) {
      ref.read(onboardingProvider.notifier).updateIncome(_selectedIncome!);
      widget.onNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionne une tranche de revenu'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Titre
          const Text(
            'Quel est ton revenu mensuel moyen ?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confidentiel - pour mieux adapter nos conseils',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 32),

          // Liste de choix
          Expanded(
            child: ListView.builder(
              itemCount: _incomeRanges.length,
              itemBuilder: (context, index) {
                final income = _incomeRanges[index];
                final isSelected = _selectedIncome == income['value'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _selectIncome(income['value']),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (income['color'] as Color).withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? (income['color'] as Color)
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  (income['color'] as Color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: income['color'] as Color,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              income['label'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? (income['color'] as Color)
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: income['color'] as Color,
                              size: 28,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Info confidentialité
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00A86B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock,
                  color: Color(0xFF00A86B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tes informations sont 100% confidentielles',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bouton suivant
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Suivant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
