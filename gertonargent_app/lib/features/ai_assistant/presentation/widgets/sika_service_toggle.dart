import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sika_service_provider.dart';

/// Widget pour activer/desactiver le service Sika (wake word)
class SikaServiceToggle extends ConsumerWidget {
  const SikaServiceToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sikaState = ref.watch(sikaServiceProvider);
    final sikaNotifier = ref.read(sikaServiceProvider.notifier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sikaState.isServiceRunning
                      ? const Color(0xFF00A86B).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.mic,
                  color: sikaState.isServiceRunning
                      ? const Color(0xFF00A86B)
                      : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assistant Sika',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sikaState.isServiceRunning
                          ? 'Dites "Sika" pour activer'
                          : 'Service desactive',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: sikaState.isServiceRunning,
                onChanged: (value) => sikaNotifier.toggleService(),
                activeColor: const Color(0xFF00A86B),
              ),
            ],
          ),
          if (sikaState.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sikaState.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Bouton pour tester Sika manuellement
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => sikaNotifier.showSikaOverlay(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Tester Sika maintenant'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00A86B),
                side: const BorderSide(color: Color(0xFF00A86B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
