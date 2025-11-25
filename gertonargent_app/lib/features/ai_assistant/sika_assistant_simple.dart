import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

/// Simple UI widget that displays Sika status and listens for native commands.
/// The actual continuous voice listening is handled by SikaVoiceService (runs in background).
class SikaAssistant extends StatefulWidget {
  const SikaAssistant({Key? key}) : super(key: key);

  @override
  State<SikaAssistant> createState() => _SikaAssistantState();
}

class _SikaAssistantState extends State<SikaAssistant> {
  String _status = 'Sika listening in background...';
  String _lastCommand = '';
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    // Listen for native broadcasts forwarded by MainActivity
    const method = MethodChannel('com.gertonargent/sika');
    method.setMethodCallHandler((call) async {
      if (call.method == 'onSikaCommand') {
        final String cmd = call.arguments ?? '';
        if (cmd.isNotEmpty) {
          debugPrint('Received native Sika command: $cmd');
          await _processCommand(cmd);
        }
      }
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _processCommand(String command) async {
    setState(() => _status = 'Processing: $command');
    setState(() => _lastCommand = command);

    debugPrint('Command: $command');
    await _speak("J'ai entendu: $command");

    final parsed = _parseAddExpense(command);
    if (parsed != null) {
      final amount = parsed['amount'] as double;
      final category = parsed['category'] as String?;
      final description = parsed['description'] as String?;

      final success = await _sendTransactionToBackend(
          amount, category ?? 'autre', description);
      if (success) {
        await _speak('Dépense de ${amount.toStringAsFixed(0)} FCFA ajoutée.');
        setState(() => _status = 'Expense saved ✓');
      } else {
        await _speak('Impossible d\'enregistrer la dépense maintenant.');
        setState(() => _status = 'Error saving expense');
      }
      return;
    }

    if (command.toLowerCase().contains('solde') ||
        command.toLowerCase().contains('reste')) {
      await _speak('Votre solde restant est de 120 000 FCFA.');
      setState(() => _status = 'Balance check');
      return;
    }

    await _speak('Désolé, je n\'ai pas compris. Pouvez‑vous répéter ?');
    setState(() => _status = 'Command not understood');
  }

  Map<String, dynamic>? _parseAddExpense(String text) {
    final t = text.toLowerCase();

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
      return null;
    }

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
      final resp = await http.post(url,
          headers: {'Content-Type': 'application/json'}, body: body);
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

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sika Assistant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Status: $_status',
                style: const TextStyle(fontSize: 14, color: Colors.green)),
            if (_lastCommand.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Last command: $_lastCommand',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 12),
            const Text(
              'Sika is always listening in the background. Say "Sika" followed by your command.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
