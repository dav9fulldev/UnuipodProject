import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';
import '../../../../data/local/registration_cache.dart';

class GoalsStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const GoalsStep({super.key, required this.onNext});

  @override
  ConsumerState<GoalsStep> createState() => _GoalsStepState();
}

class _GoalsStepState extends ConsumerState<GoalsStep> {
  final Set<String> _selectedGoals = {};

  final List<Map<String, dynamic>> _goals = [
    {'icon': '🏠', 'label': 'Acheter un terrain', 'value': 'terrain'},
    {'icon': '🚗', 'label': 'Acheter une voiture', 'value': 'voiture'},
    {'icon': '💍', 'label': 'Préparer un mariage', 'value': 'mariage'},
    {'icon': '🎓', 'label': 'Financer des études', 'value': 'etudes'},
    {'icon': '✈️', 'label': 'Voyager', 'value': 'voyage'},
    {'icon': '💼', 'label': 'Créer une entreprise', 'value': 'entreprise'},
    {'icon': '💰', 'label': 'Constituer une épargne', 'value': 'epargne'},
    {'icon': '📈', 'label': 'Investir en bourse (BRVM)', 'value': 'brvm'},
    {'icon': '🎯', 'label': 'Mieux gérer mon budget', 'value': 'gestion'},
    {'icon': '📊', 'label': 'Suivre mes dépenses', 'value': 'suivi'},
  ];

  void _toggleGoal(String value) {
    setState(() {
      if (_selectedGoals.contains(value)) {
        _selectedGoals.remove(value);
        RegistrationCache.saveStep('goals', _selectedGoals.toList());
      } else {
        _selectedGoals.add(value);
        RegistrationCache.saveStep('goals', _selectedGoals.toList());
      }
    });
  }

  void _submit() {
    if (_selectedGoals.isNotEmpty) {
      ref
          .read(onboardingProvider.notifier)
          .updateGoals(_selectedGoals.toList());
      widget.onNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionne au moins un objectif'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // prefill
    final cached = RegistrationCache.getStep<List>('goals');
    if (cached != null && _selectedGoals.isEmpty)
      _selectedGoals.addAll(cached.cast<String>());
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Titre
          const Text(
            'Pourquoi utilises-tu GèrTonArgent ?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisis un ou plusieurs objectifs (tu peux en sélectionner plusieurs)',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 24),

          // Compteur de sélection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00A86B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_selectedGoals.length} objectif${_selectedGoals.length > 1 ? 's' : ''} sélectionné${_selectedGoals.length > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Color(0xFF00A86B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Grille de choix
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio:
                    1.0, // CHANGÉ de 1.1 à 1.0 pour plus de hauteur
              ),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final isSelected = _selectedGoals.contains(goal['value']);

                return InkWell(
                  onTap: () => _toggleGoal(goal['value']),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12), // RÉDUIT de 16 à 12
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00A86B).withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00A86B)
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          goal['icon'],
                          style: const TextStyle(
                              fontSize: 36), // RÉDUIT de 40 à 36
                        ),
                        const SizedBox(height: 6), // RÉDUIT de 8 à 6
                        Flexible(
                          // AJOUTÉ Flexible pour éviter débordement
                          child: Text(
                            goal['label'],
                            style: TextStyle(
                              fontSize: 11, // RÉDUIT de 13 à 11
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF00A86B)
                                  : Colors.black87,
                              height: 1.2, // AJOUTÉ pour espacement lignes
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3, // CHANGÉ de 2 à 3
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 2), // RÉDUIT de 4 à 2
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF00A86B),
                            size: 18, // RÉDUIT de 20 à 18
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

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
              child: Text(
                _selectedGoals.isEmpty
                    ? 'Sélectionne au moins un objectif'
                    : 'Suivant',
                style: const TextStyle(
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
