import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';

class CategoriesStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const CategoriesStep({super.key, required this.onNext});

  @override
  ConsumerState<CategoriesStep> createState() => _CategoriesStepState();
}

class _CategoriesStepState extends ConsumerState<CategoriesStep> {
  final Set<String> _selectedCategories = {};

  final List<Map<String, dynamic>> _categories = [
    {
      'icon': '🍔',
      'label': 'Alimentation',
      'value': 'alimentation',
      'color': const Color(0xFFFF6B00)
    },
    {
      'icon': '🏠',
      'label': 'Logement',
      'value': 'logement',
      'color': const Color(0xFF2196F3)
    },
    {
      'icon': '🚗',
      'label': 'Transport',
      'value': 'transport',
      'color': const Color(0xFF9C27B0)
    },
    {
      'icon': '👕',
      'label': 'Vêtements',
      'value': 'vetements',
      'color': const Color(0xFFE91E63)
    },
    {
      'icon': '📱',
      'label': 'Loisirs',
      'value': 'loisirs',
      'color': const Color(0xFF00BCD4)
    },
    {
      'icon': '🏥',
      'label': 'Santé',
      'value': 'sante',
      'color': const Color(0xFF4CAF50)
    },
  ];

  void _toggleCategory(String value) {
    setState(() {
      if (_selectedCategories.contains(value)) {
        _selectedCategories.remove(value);
      } else {
        _selectedCategories.add(value);
      }
    });
  }

  void _submit() {
    if (_selectedCategories.isNotEmpty) {
      ref
          .read(onboardingProvider.notifier)
          .updateCategories(_selectedCategories.toList());
      widget.onNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionne au moins une catégorie'),
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
            'Dans quoi dépenses-tu le plus ?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionne tes principales catégories de dépenses',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 24),

          // Compteur
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00A86B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_selectedCategories.length} catégorie${_selectedCategories.length > 1 ? 's' : ''} sélectionnée${_selectedCategories.length > 1 ? 's' : ''}',
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
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected =
                    _selectedCategories.contains(category['value']);

                return InkWell(
                  onTap: () => _toggleCategory(category['value']),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (category['color'] as Color).withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? (category['color'] as Color)
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
                          category['icon'],
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          category['label'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? (category['color'] as Color)
                                : Colors.black87,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Icon(
                            Icons.check_circle,
                            color: category['color'] as Color,
                            size: 20,
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
                _selectedCategories.isEmpty
                    ? 'Sélectionne au moins une catégorie'
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
