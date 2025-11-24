import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../providers/sika_provider.dart';

class SikaPage extends ConsumerStatefulWidget {
  const SikaPage({super.key});

  @override
  ConsumerState<SikaPage> createState() => _SikaPageState();
}

class _SikaPageState extends ConsumerState<SikaPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sikaData = ref.watch(sikaProvider);
    final sikaNotifier = ref.read(sikaProvider.notifier);

    // Scroll vers le bas quand nouveaux messages
    _scrollToBottom();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A86B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  '🤖',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sika',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _getStatusText(sikaData.state),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => sikaNotifier.clearConversation(),
            tooltip: 'Nouvelle conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone de conversation
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: sikaData.messages.length,
              itemBuilder: (context, index) {
                final message = sikaData.messages[index];
                return _buildMessageBubble(message, sikaNotifier);
              },
            ),
          ),

          // Texte en cours de reconnaissance
          if (sikaData.state == SikaState.listening &&
              sikaData.currentText != null &&
              sikaData.currentText!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Color(0xFF00A86B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sikaData.currentText!,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Zone de saisie et micro
          _buildInputArea(sikaData, sikaNotifier),
        ],
      ),
    );
  }

  String _getStatusText(SikaState state) {
    switch (state) {
      case SikaState.listening:
        return 'Je t\'écoute...';
      case SikaState.processing:
        return 'Je réfléchis...';
      case SikaState.speaking:
        return 'Je parle...';
      case SikaState.error:
        return 'Une erreur est survenue';
      default:
        return 'En ligne';
    }
  }

  Widget _buildMessageBubble(SikaMessage message, SikaNotifier notifier) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A86B),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text('🤖', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF00A86B) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.person, color: Colors.grey, size: 20),
                ),
              ],
            ],
          ),

          // Boutons d'action si transaction suggérée
          if (!isUser && message.canAddTransaction && message.suggestedTransaction != null)
            Padding(
              padding: EdgeInsets.only(
                top: 8,
                left: isUser ? 0 : 44,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => notifier.confirmTransaction(message.suggestedTransaction!),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Oui, enregistrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A86B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => notifier.cancelTransaction(),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea(SikaData sikaData, SikaNotifier notifier) {
    final isListening = sikaData.state == SikaState.listening;
    final isProcessing = sikaData.state == SikaState.processing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Champ de texte
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !isListening && !isProcessing,
                    decoration: InputDecoration(
                      hintText: 'Écris ton message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (text) {
                      if (text.isNotEmpty) {
                        notifier.sendTextMessage(text);
                        _textController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: isListening || isProcessing
                      ? null
                      : () {
                          if (_textController.text.isNotEmpty) {
                            notifier.sendTextMessage(_textController.text);
                            _textController.clear();
                          }
                        },
                  icon: const Icon(Icons.send),
                  color: const Color(0xFF00A86B),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bouton micro central
            Center(
              child: AvatarGlow(
                animate: isListening,
                glowColor: const Color(0xFF00A86B),
                glowRadiusFactor: 0.7,
                child: GestureDetector(
                  onTapDown: (_) {
                    if (!isProcessing) {
                      notifier.startListening();
                    }
                  },
                  onTapUp: (_) {
                    if (isListening) {
                      notifier.stopListening();
                    }
                  },
                  onTapCancel: () {
                    if (isListening) {
                      notifier.stopListening();
                    }
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isListening
                            ? [const Color(0xFFFF6B00), const Color(0xFFFF8C00)]
                            : isProcessing
                                ? [Colors.grey, Colors.grey]
                                : [const Color(0xFF00A86B), const Color(0xFF00D084)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isListening
                              ? const Color(0xFFFF6B00).withOpacity(0.4)
                              : const Color(0xFF00A86B).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening
                          ? Icons.mic
                          : isProcessing
                              ? Icons.hourglass_empty
                              : Icons.mic_none,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isListening
                  ? 'Relâche pour envoyer'
                  : isProcessing
                      ? 'Sika réfléchit...'
                      : 'Maintiens pour parler',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
