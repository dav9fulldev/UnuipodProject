import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class SikaAssistant extends StatefulWidget {
  const SikaAssistant({Key? key}) : super(key: key);

  @override
  State<SikaAssistant> createState() => _SikaAssistantState();
}

class _SikaAssistantState extends State<SikaAssistant> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _lastWords = '';
  String _status = 'Idle';
  final FlutterTts _tts = FlutterTts();

  Timer? _restartTimer;
  // When wake word detected we capture a short command (e.g., 6-8s)
  bool _awaitingCommand = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    _available = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );
    if (_available) {
      // Start listening in the foreground to detect wake word.
      _startListeningContinuous();
    } else {
      setState(() {
        _status = 'Speech recognition not available';
      });
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void _onStatus(String status) {
    // restart listening if it stopped unexpectedly (keeps foreground continuous listening)
    if (status == 'done' || status == 'notListening') {
      if (!_awaitingCommand) {
        // short delay before restarting to avoid tight loops
        _restartTimer?.cancel();
        _restartTimer = Timer(const Duration(milliseconds: 300), () {
          if (!_listening && mounted) _startListeningContinuous();
        });
      }
    }
  }

  void _onError(dynamic error) {
    // speech_to_text types changed between versions; accept dynamic and access safely
    try {
      final msg = error?.errorMsg ?? error?.toString();
      final perm = error?.permanent;
      debugPrint('Speech error: $msg, permanent: $perm');
    } catch (e) {
      debugPrint('Speech error (unknown format): $error');
    }
    if (!_awaitingCommand && mounted) {
      _restartTimer?.cancel();
      _restartTimer = Timer(const Duration(milliseconds: 500), () {
        if (!_listening) _startListeningContinuous();
      });
    }
  }

  Future<void> _startListeningContinuous() async {
    if (!_available) return;
    if (_listening) return;
    setState(() {
      _status = 'Listening for wake word...';
    });
    _listening = true;
    _lastWords = '';
    await _speech.listen(
      onResult: _onSpeechResultContinuous,
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
      cancelOnError: false,
      listenFor: const Duration(seconds: 60), // long session then restart
    );
  }

  // Continuous callback to detect wake word 'sika'
  void _onSpeechResultContinuous(dynamic result) {
    if (!mounted) return;
    String recognized = '';
    try {
      recognized =
          (result?.recognizedWords ?? result?.recognized ?? '') as String;
    } catch (e) {
      recognized = result?.toString() ?? '';
    }
    _lastWords = recognized;
    // debug
    // print('partial: $recognized');

    // Detect wake-word (case-insensitive)
    if (!_awaitingCommand && recognized.toLowerCase().contains('sika')) {
      _triggerWakeWord();
    }
  }

  Future<void> _triggerWakeWord() async {
    // Stop background listening and enter command capture mode
    _awaitingCommand = true;
    _restartTimer?.cancel();
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }
    setState(() {
      _status = 'Sika detected — listening command...';
    });

    // Provide an audible cue
    await _speak('Oui ?');

    // Start a shorter listening session to capture the user's command
    final success = await _speech.listen(
      onResult: _onSpeechResultCommand,
      listenFor: const Duration(seconds: 8),
      partialResults: false,
      cancelOnError: true,
      listenMode: stt.ListenMode.dictation,
    );

    // fallback: if listen not started, exit command mode
    if (!success) {
      _awaitingCommand = false;
      _startListeningContinuous();
    }
  }

  // Handle the final command transcript
  void _onSpeechResultCommand(dynamic result) {
    if (!mounted) return;
    String command = '';
    try {
      command = (result?.recognizedWords ?? result?.recognized ?? '') as String;
    } catch (e) {
      command = result?.toString() ?? '';
    }
    command = command.trim();
    _status = 'Command captured';
    _processCommand(command);
    _awaitingCommand = false;
    // Restart continuous listening after short delay
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 400), () {
      _startListeningContinuous();
    });
  }

  Future<void> _processCommand(String command) async {
    debugPrint('Command: $command');
    await _speak("J'ai entendu: $command");

    // Example simple parsing: "ajoute une dépense de 5000 FCFA pour taxi"
    final parsed = _parseAddExpense(command);
    if (parsed != null) {
      final amount = parsed['amount'] as double;
      final category = parsed['category'] as String?;
      final description = parsed['description'] as String?;
      // Call backend to save transaction (optional)
      final success = await _sendTransactionToBackend(
          amount, category ?? 'autre', description);
      if (success) {
        await _speak('Dépense de ${amount.toStringAsFixed(0)} FCFA ajoutée.');
      } else {
        await _speak('Impossible d\'enregistrer la dépense maintenant.');
      }
      return;
    }

    // Other sample intents
    if (command.toLowerCase().contains('solde') ||
        command.toLowerCase().contains('reste')) {
      // Here we would call API to get balance; for now reply with placeholder
      await _speak('Votre solde restant est de 120 000 FCFA.'); // placeholder
      return;
    }

    // Default response
    await _speak('Désolé, je n\'ai pas compris. Pouvez‑vous répéter ?');
  }

  Map<String, dynamic>? _parseAddExpense(String text) {
    // Normalize
    final t = text.toLowerCase();

    // Look for verb forms that imply adding expense
    final triggers = [
      'ajoute',
      'ajouter',
      'enregistre',
      'déclare',
      'j ai dépensé',
      "j'ai dépensé",
      'j\'ai dépensé',
      'pai',
      'payer',
      'payé'
    ];
    final containsTrigger = triggers.any((w) => t.contains(w));
    if (!containsTrigger && !t.contains('dépense')) {
      // not an add-expense command
      // but still allow phrases like "5000 pour taxi"
      // fallthrough only if it contains amount
    }

    // Extract amount with simple regex
    final amountRegex = RegExp(
        r'(\d{2,}(?:[ ,.]?\d{3})*|\d+)\s*(fcfa|f|francs?)?',
        caseSensitive: false);
    final m = amountRegex.firstMatch(t);
    double? amount;
    if (m != null) {
      final raw = m.group(1)!.replaceAll(RegExp(r'[ ,.]'), '');
      amount = double.tryParse(raw);
    }

    if (amount == null) return null;

    // Try to extract category (a simple keyword match)
    final categories = [
      'alimentation',
      'transport',
      'logement',
      'santé',
      'education',
      'loisirs',
      'épargne',
      'vetements',
      'communication',
      'taxi',
      'restaurant'
    ];
    String? category;
    for (final c in categories) {
      if (t.contains(c)) {
        category = c;
        break;
      }
    }

    // Extract a short description after "pour" or "à" or "au"
    String? description;
    final descRegex = RegExp(r'(?:pour|à|au|aux)\s+([a-z0-9éèêàâ_\- ]{3,})',
        caseSensitive: false);
    final md = descRegex.firstMatch(text);
    if (md != null) {
      description = md.group(1)?.trim();
    }

    return {'amount': amount, 'category': category, 'description': description};
  }

  Future<bool> _sendTransactionToBackend(
      double amount, String category, String? description) async {
    try {
      final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.transactions);
      final body = jsonEncode({
        'amount': amount,
        'category': category,
        'description': description ?? '',
        'transaction_type': 'expense',
      });
      final resp = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 8));
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      debugPrint('Backend error: $e');
      return false;
    }
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _stopAll() async {
    _restartTimer?.cancel();
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }
    await _tts.stop();
  }

  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.mic,
              color: _awaitingCommand
                  ? Colors.orange
                  : (_listening ? Colors.green : Colors.grey)),
          title: Text('Sika — $_status'),
          subtitle: Text(_lastWords),
          trailing: IconButton(
            icon: const Icon(Icons.mic_none),
            onPressed: () async {
              if (_listening) {
                await _speech.stop();
                setState(() {
                  _listening = false;
                  _status = 'Stopped';
                });
              } else {
                _startListeningContinuous();
              }
            },
          ),
        ),
        const SizedBox(height: 6),
        ElevatedButton(
          onPressed: () async {
            await _speak('Bonjour, je suis Sika, votre assistant financier.');
          },
          child: const Text('Tester la voix'),
        ),
      ],
    );
  }
}
