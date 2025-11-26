import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';
import '../../../../data/local/registration_cache.dart';

class ProfessionStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const ProfessionStep({super.key, required this.onNext});

  @override
  ConsumerState<ProfessionStep> createState() => _ProfessionStepState();
}

class _ProfessionStepState extends ConsumerState<ProfessionStep> {
  String? _selectedProfession;

  final List<Map<String, dynamic>> _professions = [
    {'icon': '👨‍💼', 'label': 'Salarié', 'value': 'salarie'},
    {'icon': '👨‍💻', 'label': 'Entrepreneur', 'value': 'entrepreneur'},
    {'icon': '👨‍🎓', 'label': 'Étudiant', 'value': 'etudiant'},
    {'icon': '🏪', 'label': 'Commerçant', 'value': 'commercant'},
    {'icon': '🚕', 'label': 'Chauffeur', 'value': 'chauffeur'},
    {'icon': '✋', 'label': 'Autre', 'value': 'autre'},
  ];

  void _selectProfession(String value) {
    setState(() {
      _selectedProfession = value;
    });
    RegistrationCache.saveStep('profession', value);
  }

  void _submit() {
    if (_selectedProfession != null) {
      ref
          .read(onboardingProvider.notifier)
          .updateProfession(_selectedProfession!);
      widget.onNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionne une profession'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // prefill
    final cached = RegistrationCache.getStepAs<String>('profession');
    if (cached != null && _selectedProfession == null)
      _selectedProfession = cached;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Titre
          const Text(
            'Quelle est ta profession ?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cela nous aide à personnaliser tes conseils',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 32),

          // Grille de choix
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _professions.length,
              itemBuilder: (context, index) {
                final profession = _professions[index];
                final isSelected = _selectedProfession == profession['value'];

                return InkWell(
                  onTap: () => _selectProfession(profession['value']),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
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
                          profession['icon'],
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profession['label'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF00A86B)
                                : Colors.black87,
                          ),
                        ),
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
