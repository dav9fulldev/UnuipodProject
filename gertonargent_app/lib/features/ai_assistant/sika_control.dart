import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'sika_sync.dart';

class SikaControl extends StatefulWidget {
  const SikaControl({Key? key}) : super(key: key);

  @override
  State<SikaControl> createState() => _SikaControlState();
}

class _SikaControlState extends State<SikaControl> {
  static const MethodChannel _overlayChan =
      MethodChannel('com.gertonargent/overlay');
  static const MethodChannel _sikaChan = MethodChannel('com.gertonargent/sika');

  bool _overlayAllowed = false;
  bool _micGranted = false;
  bool _serviceRunning = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    try {
      final perms = await _overlayChan.invokeMethod('checkPermissions');
      final mic = await Permission.microphone.status;
      final running = await _sikaChan.invokeMethod('isSikaServiceRunning');
      setState(() {
        _overlayAllowed = perms['overlay'] ?? false;
        _micGranted = mic.isGranted;
        _serviceRunning = running ?? false;
      });
    } catch (e) {
      debugPrint('SikaControl: refresh error: $e');
    }
  }

  Future<void> _requestMicrophone() async {
    final status = await Permission.microphone.request();
    setState(() => _micGranted = status.isGranted);
  }

  Future<void> _requestOverlay() async {
    try {
      await _overlayChan.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('requestOverlay error: $e');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    _refreshStatus();
  }

  Future<void> _startService() async {
    try {
      await _sikaChan.invokeMethod('startSikaService');
    } catch (e) {
      debugPrint('start service error: $e');
    }
    await Future.delayed(const Duration(milliseconds: 400));
    _refreshStatus();
  }

  Future<void> _stopService() async {
    try {
      await _sikaChan.invokeMethod('stopSikaService');
    } catch (e) {
      debugPrint('stop service error: $e');
    }
    await Future.delayed(const Duration(milliseconds: 400));
    _refreshStatus();
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final count = await SikaSync.syncPendingTransactions();
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync terminé: $count dépense(s) envoyée(s)')));
    _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sika — Contrôle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(
                  _serviceRunning
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _serviceRunning ? Colors.green : Colors.grey),
              const SizedBox(width: 8),
              Text(_serviceRunning ? 'Service actif' : 'Service arrêté')
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(_overlayAllowed ? Icons.check : Icons.warning,
                  color: _overlayAllowed ? Colors.green : Colors.orange),
              const SizedBox(width: 8),
              Text(
                  'Permission overlay: ${_overlayAllowed ? "OK" : "Manquante"}')
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(_micGranted ? Icons.mic : Icons.mic_off,
                  color: _micGranted ? Colors.green : Colors.orange),
              const SizedBox(width: 8),
              Text('Microphone: ${_micGranted ? "Autorisé" : "Non autorisé"}')
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              ElevatedButton(
                  onPressed: _requestMicrophone,
                  child: const Text('Demander Micro')),
              ElevatedButton(
                  onPressed: _requestOverlay,
                  child: const Text('Demander Overlay')),
              ElevatedButton(
                  onPressed: _serviceRunning ? _stopService : _startService,
                  child:
                      Text(_serviceRunning ? 'Arrêter Sika' : 'Démarrer Sika')),
              ElevatedButton(
                  onPressed: _syncing ? null : _syncNow,
                  child: Text(_syncing ? 'Sync...' : 'Sync pending')),
              ElevatedButton(
                  onPressed: _refreshStatus, child: const Text('Actualiser')),
            ])
          ],
        ),
      ),
    );
  }
}
