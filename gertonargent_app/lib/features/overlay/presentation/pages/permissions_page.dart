import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  static const platform = MethodChannel('com.gertonargent/overlay');

  bool overlayPermissionGranted = false;
  bool accessibilityPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  Future<void> checkPermissions() async {
    try {
      final result = await platform.invokeMethod('checkPermissions');
      setState(() {
        overlayPermissionGranted = result['overlay'] ?? false;
        accessibilityPermissionGranted = result['accessibility'] ?? false;
      });
    } catch (e) {
      print('Erreur vérification permissions: $e');
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await platform.invokeMethod('requestOverlayPermission');
      await Future.delayed(const Duration(seconds: 1));
      await checkPermissions();
    } catch (e) {
      print('Erreur demande overlay: $e');
    }
  }

  Future<void> requestAccessibilityPermission() async {
    try {
      await platform.invokeMethod('requestAccessibilityPermission');
      await Future.delayed(const Duration(seconds: 1));
      await checkPermissions();
    } catch (e) {
      print('Erreur demande accessibility: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A86B),
        elevation: 0,
        title: const Text(
          'Permissions',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Activation des fonctionnalités',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pour fonctionner, GèrTonArgent a besoin de ces permissions :',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Permission Overlay
            _PermissionCard(
              icon: Icons.layers,
              title: 'Affichage par-dessus d\'autres apps',
              description:
                  'Permet d\'afficher des alertes quand vous utilisez des apps Mobile Money.',
              isGranted: overlayPermissionGranted,
              onActivate: requestOverlayPermission,
            ),
            const SizedBox(height: 16),

            // Permission Accessibility
            _PermissionCard(
              icon: Icons.accessibility_new,
              title: 'Service d\'accessibilité',
              description:
                  'Détecte automatiquement quand vous ouvrez Wave, Orange Money, etc.',
              isGranted: accessibilityPermissionGranted,
              onActivate: requestAccessibilityPermission,
            ),
            const SizedBox(height: 32),

            // Info sécurité
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00A86B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield,
                    color: Color(0xFF00A86B),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ces permissions ne donnent AUCUN accès à vos données bancaires. '
                      'Nous observons uniquement pour vous alerter.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onActivate;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A86B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF00A86B),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isGranted ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: isGranted ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isGranted ? 'Activée' : 'Non activée',
                          style: TextStyle(
                            fontSize: 12,
                            color: isGranted ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (!isGranted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onActivate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A86B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Activer'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
