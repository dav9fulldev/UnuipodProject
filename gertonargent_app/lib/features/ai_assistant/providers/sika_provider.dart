import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../data/services/api_service.dart';

// État de Sika
enum SikaState {
  idle,        // En attente
  listening,   // Écoute en cours
  processing,  // Traitement de la requête
  speaking,    // Sika parle
  error,       // Erreur
}

// Message dans la conversation
class SikaMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? suggestedTransaction;
  final bool canAddTransaction;

  SikaMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.suggestedTransaction,
    this.canAddTransaction = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

// État global de Sika
class SikaData {
  final SikaState state;
  final List<SikaMessage> messages;
  final String? currentText;
  final String? errorMessage;
  final bool isInitialized;

  const SikaData({
    this.state = SikaState.idle,
    this.messages = const [],
    this.currentText,
    this.errorMessage,
    this.isInitialized = false,
  });

  SikaData copyWith({
    SikaState? state,
    List<SikaMessage>? messages,
    String? currentText,
    String? errorMessage,
    bool? isInitialized,
  }) {
    return SikaData(
      state: state ?? this.state,
      messages: messages ?? this.messages,
      currentText: currentText,
      errorMessage: errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// Provider principal de Sika
class SikaNotifier extends StateNotifier<SikaData> {
  final ApiService _apiService;
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _speechEnabled = false;

  SikaNotifier(this._apiService) : super(const SikaData()) {
    _initializeSika();
  }

  Future<void> _initializeSika() async {
    try {
      // Initialiser Speech-to-Text
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          state = state.copyWith(
            state: SikaState.error,
            errorMessage: 'Erreur de reconnaissance vocale',
          );
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
        },
      );

      // Configurer Text-to-Speech
      await _flutterTts.setLanguage('fr-FR');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        if (state.state == SikaState.speaking) {
          state = state.copyWith(state: SikaState.idle);
        }
      });

      // Message de bienvenue
      final welcomeMessage = SikaMessage(
        text: "Salut ! Je suis Sika, ton assistant financier. "
              "Appuie sur le micro et parle-moi de tes dépenses !",
        isUser: false,
      );

      state = state.copyWith(
        isInitialized: true,
        messages: [welcomeMessage],
      );

      debugPrint('Sika initialized. Speech enabled: $_speechEnabled');
    } catch (e) {
      debugPrint('Failed to initialize Sika: $e');
      state = state.copyWith(
        state: SikaState.error,
        errorMessage: 'Impossible d\'initialiser Sika',
      );
    }
  }

  // Démarrer l'écoute
  Future<void> startListening() async {
    if (!_speechEnabled) {
      state = state.copyWith(
        state: SikaState.error,
        errorMessage: 'La reconnaissance vocale n\'est pas disponible',
      );
      return;
    }

    state = state.copyWith(
      state: SikaState.listening,
      currentText: '',
    );

    await _speechToText.listen(
      onResult: (result) {
        state = state.copyWith(
          currentText: result.recognizedWords,
        );

        if (result.finalResult) {
          _processQuery(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'fr_FR',
    );
  }

  // Arrêter l'écoute
  Future<void> stopListening() async {
    await _speechToText.stop();

    if (state.currentText != null && state.currentText!.isNotEmpty) {
      _processQuery(state.currentText!);
    } else {
      state = state.copyWith(state: SikaState.idle);
    }
  }

  // Envoyer un message texte (alternative au vocal)
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    await _processQuery(text);
  }

  // Traiter la requête
  Future<void> _processQuery(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(state: SikaState.idle);
      return;
    }

    // Ajouter le message de l'utilisateur
    final userMessage = SikaMessage(text: query, isUser: true);
    state = state.copyWith(
      state: SikaState.processing,
      messages: [...state.messages, userMessage],
      currentText: null,
    );

    try {
      // Appeler l'API Sika
      final response = await _apiService.sikaChat(query);

      // Créer le message de réponse
      final sikaMessage = SikaMessage(
        text: response['message'] ?? "Je n'ai pas compris, peux-tu reformuler ?",
        isUser: false,
        suggestedTransaction: response['suggested_transaction'],
        canAddTransaction: response['can_add_transaction'] ?? false,
      );

      state = state.copyWith(
        messages: [...state.messages, sikaMessage],
      );

      // Faire parler Sika
      await _speak(sikaMessage.text);

    } catch (e) {
      debugPrint('Sika API error: $e');

      final errorMessage = SikaMessage(
        text: "Oups ! Je n'arrive pas à me connecter au serveur. "
              "Vérifie ta connexion internet.",
        isUser: false,
      );

      state = state.copyWith(
        state: SikaState.error,
        messages: [...state.messages, errorMessage],
        errorMessage: e.toString(),
      );
    }
  }

  // Confirmer une transaction suggérée
  Future<void> confirmTransaction(Map<String, dynamic> transaction) async {
    state = state.copyWith(state: SikaState.processing);

    try {
      final response = await _apiService.sikaConfirmTransaction(
        amount: transaction['amount'],
        category: transaction['category'],
        description: transaction['description'],
      );

      final confirmMessage = SikaMessage(
        text: response['message'] ?? "Transaction enregistrée !",
        isUser: false,
      );

      state = state.copyWith(
        state: SikaState.idle,
        messages: [...state.messages, confirmMessage],
      );

      await _speak(confirmMessage.text);

    } catch (e) {
      debugPrint('Transaction confirmation error: $e');

      final errorMessage = SikaMessage(
        text: "Désolé, je n'ai pas pu enregistrer la transaction. "
              "Réessaie plus tard.",
        isUser: false,
      );

      state = state.copyWith(
        state: SikaState.error,
        messages: [...state.messages, errorMessage],
      );
    }
  }

  // Annuler une transaction suggérée
  void cancelTransaction() {
    final cancelMessage = SikaMessage(
      text: "D'accord, j'annule. Dis-moi si tu as besoin d'autre chose !",
      isUser: false,
    );

    state = state.copyWith(
      messages: [...state.messages, cancelMessage],
    );

    _speak(cancelMessage.text);
  }

  // Faire parler Sika
  Future<void> _speak(String text) async {
    state = state.copyWith(state: SikaState.speaking);
    await _flutterTts.speak(text);
  }

  // Arrêter Sika de parler
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    state = state.copyWith(state: SikaState.idle);
  }

  // Effacer la conversation
  void clearConversation() {
    final welcomeMessage = SikaMessage(
      text: "Conversation effacée ! Comment puis-je t'aider ?",
      isUser: false,
    );

    state = state.copyWith(
      messages: [welcomeMessage],
      state: SikaState.idle,
    );
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    super.dispose();
  }
}

// Provider
final sikaProvider = StateNotifierProvider<SikaNotifier, SikaData>((ref) {
  return SikaNotifier(ApiService());
});
