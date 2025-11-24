import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../providers/sika_provider.dart';
import '../pages/sika_page.dart';

/// Bouton flottant Sika - comme le bouton Siri sur iPhone
/// Affiche l'état de Sika et permet d'ouvrir l'assistant
class SikaFloatingButton extends ConsumerWidget {
  final bool mini;
  final EdgeInsets? margin;

  const SikaFloatingButton({
    super.key,
    this.mini = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sikaData = ref.watch(sikaProvider);
    final isActive = sikaData.state == SikaState.listening ||
        sikaData.state == SikaState.processing ||
        sikaData.state == SikaState.speaking;

    return Padding(
      padding: margin ?? const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const SikaPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        child: AvatarGlow(
          animate: isActive,
          glowColor: const Color(0xFF00A86B),
          glowRadiusFactor: 0.7,
          child: Container(
            width: mini ? 50 : 60,
            height: mini ? 50 : 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00A86B), Color(0xFF00D084)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A86B).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _getIcon(sikaData.state),
                  color: Colors.white,
                  size: mini ? 24 : 28,
                ),
                // Indicateur d'activité
                if (isActive)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _getStatusColor(sikaData.state),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(SikaState state) {
    switch (state) {
      case SikaState.listening:
        return Icons.mic;
      case SikaState.processing:
        return Icons.auto_awesome;
      case SikaState.speaking:
        return Icons.volume_up;
      default:
        return Icons.assistant;
    }
  }

  Color _getStatusColor(SikaState state) {
    switch (state) {
      case SikaState.listening:
        return Colors.red;
      case SikaState.processing:
        return Colors.orange;
      case SikaState.speaking:
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}

/// Widget pour afficher Sika en mode compact dans le dashboard
class SikaCompactCard extends ConsumerWidget {
  const SikaCompactCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SikaPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00A86B), Color(0xFF00D084)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00A86B).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parle à Sika',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ton assistant financier intelligent',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
