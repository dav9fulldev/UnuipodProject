# 🎙️ Sika Assistant — Guide d'Implémentation Complet

## Table des matières
1. [Architecture](#architecture)
2. [Permissions (AndroidManifest)](#permissions)
3. [Installation & Setup](#installation)
4. [Guide de Test Live](#guide-de-test-live)
5. [Logs Attendus](#logs-attendus)
6. [Intégration dans les Formulaires](#intégration-dans-les-formulaires)
7. [Troubleshooting](#troubleshooting)

---

## Architecture

### Composants Natifs (Android/Kotlin)

```
┌─────────────────────────────────────────────────────────────┐
│                  SikaWakeWordServiceV2                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Wake-Word Detection (loudness-based fallback)        │   │
│  │ TTS: "Oui {firstname} ?"                             │   │
│  │ STT: Capture commande complète                       │   │
│  │ Parse: extract amount, category, description         │   │
│  │ Save: JSONArray → SharedPreferences                  │   │
│  │ MethodChannel Event: "onPendingTransactionAdded"     │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              SikaOverlayServiceV2                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Affiche bulle de Sika avec animation pulse          │   │
│  │ Texte TTS et visualisation de STT                   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              MainActivity MethodChannel Handler             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ getUserFirstname()                                   │   │
│  │ setUserFirstname(String)                            │   │
│  │ readPendingTransactions() → JSON Array              │   │
│  │ addPendingTransaction(JSON)                         │   │
│  │ clearPendingTransactions()                          │   │
│  │ removePendingTransaction(index)                     │   │
│  │ showSikaOverlay(message)                            │   │
│  │ hideSikaOverlay()                                   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Flutter Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ SikaNative   │  │ SikaSync     │  │ RegistrationCache│  │
│  │ (wrapper)    │  │ (auto-sync)  │  │ (form cache)     │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Permissions

### AndroidManifest.xml

Ajoute les permissions suivantes à `android/app/src/main/AndroidManifest.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.gertonargent_app">

    <!-- ============================================================================ -->
    <!-- SIKA PERMISSIONS -->
    <!-- ============================================================================ -->
    
    <!-- Microphone pour la détection de wake-word et STT -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    
    <!-- Service de premier plan pour écoute continue -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    
    <!-- Wake-lock pour garder le device réveillé -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    
    <!-- Pour afficher l'overlay -->
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    
    <!-- Autres permissions standard -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application>
        <!-- ... other configuration ... -->

        <!-- ============================================================================ -->
        <!-- SIKA SERVICES -->
        <!-- ============================================================================ -->

        <!-- Service de détection du wake-word -->
        <service
            android:name=".SikaWakeWordServiceV2"
            android:exported="false"
            android:foregroundServiceType="microphone"
            android:permission="android.permission.FOREGROUND_SERVICE" />

        <!-- Service d'overlay -->
        <service
            android:name=".SikaOverlayServiceV2"
            android:exported="false" />

        <!-- Boot receiver pour auto-start -->
        <receiver
            android:name=".BootReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
            </intent-filter>
        </receiver>

        <!-- MainActivity avec MethodChannel -->
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### iOS (Info.plist)

Pour iOS, ajoute les permissions suivantes à `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Sika a besoin d'accès au microphone pour écouter le mot clé "Sika"</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Sika a besoin de la reconnaissance vocale pour convertir vos commandes</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>microphone</string>
</array>
```

---

## Installation

### 1. Copier les fichiers

Les fichiers suivants doivent être copiés dans le projet:

**Côté natif (Kotlin):**
- `android/app/src/main/kotlin/com/example/gertonargent_app/SikaWakeWordServiceV2.kt`
- `android/app/src/main/kotlin/com/example/gertonargent_app/SikaOverlayServiceV2.kt`
- Modifier `MainActivity.kt` avec les handlers MethodChannel

**Côté Flutter (Dart):**
- `lib/services/sika_native.dart` ← Wrapper MethodChannel
- `lib/services/sika_sync.dart` ← Synchronisation auto
- `lib/data/local/registration_cache.dart` ← Cache inscription
- Modifier `lib/main.dart` pour initialiser Sika

### 2. Dépendances

Assurez-vous que `pubspec.yaml` contient:

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive_flutter: ^2.0.0
  flutter_riverpod: ^2.4.0
  flutter_tts: ^4.0.2  # Pour TTS côté Flutter (optionnel)
  speech_to_text: ^7.0.0  # Pour STT (optionnel)

dev_dependencies:
  hive_generator: ^2.0.0
  build_runner: ^2.4.0
```

Puis exécute:
```bash
flutter pub get
flutter pub run build_runner build
```

### 3. Gradle (build.gradle)

Assurez-vous que `android/app/build.gradle` contient:

```gradle
dependencies {
    // ... autres dépendances ...
    
    // TTS et STT via Android
    implementation 'androidx.core:core:1.10.1'
    
    // Vosk (optionnel, si tu ajoutes le modèle)
    // implementation 'alphacephei:vosk-android:0.3.28'
}
```

---

## Guide de Test Live

### Prérequis
- Appareil Android SM-A137F (ou similaire) connecté en USB
- Android Studio ou terminal avec `adb`
- App Flutter compilée et installée

### Étapes de Test

#### 1. Préparer l'appareil

```bash
# Vérifier que l'appareil est connecté
adb devices

# Installer l'APK
flutter run -d R9AQC952897

# Ou build APK
flutter build apk --release
adb install build/app/outputs/apk/release/app-release.apk
```

#### 2. Première ouverture

1. **Ouvrir l'app**
   ```bash
   flutter run -d R9AQC952897
   ```

2. **Accepter les permissions**
   - Microphone ✓
   - Overlay (SYSTEM_ALERT_WINDOW) ✓
   - Accessibility (optionnel) ✓

3. **Se connecter / S'inscrire**
   - Accès au formulaire d'inscription
   - Vérifier que le prénom est sauvegardé
   - Connexion successful

#### 3. Tester le wake-word

1. **Fermer complètement l'app**
   - Appuyer sur le bouton "back" ou "home"
   - App complètement fermée (visible dans Recent Apps)

2. **Rester sur l'écran d'accueil**
   - L'appareil doit être déverrouillé mais l'app fermée

3. **Dire "Sika"**
   - Parler clairement: "Si-ka"
   - Attendre 1-2 secondes
   - Vous devriez voir:
     - **Overlay noir** avec une bulle bleue
     - **Texte TTS**: "Oui [prénom] ?" (hautparleur)

4. **Dire la commande**
   - Exemples:
     - "ajoute dépense 5000 transport"
     - "enregistre 10000 FCFA en repas"
     - "ajouter 2500 pour le taxi"
   - L'app va capturer la voix jusqu'au silence (2 secondes)

5. **Confirmation TTS**
   - Vous devriez entendre: "Très bien [prénom], j'ai enregistré [montant] FCFA en [catégorie]"
   - L'overlay disparaît automatiquement

### Logs à Vérifier

Pendant le test, filtrez les logs:

```bash
adb logcat | grep -E "SikaWakeWordServiceV2|SikaOverlayServiceV2|MainActivity|SikaNative|SikaSync|RegistrationCache"
```

Ou utiliser Android Studio Logcat avec filtre "Sika*"

---

## Logs Attendus

### 1️⃣ Au démarrage de l'app

```
[Main] ✅ App initialization started
[Main] ✅ Native Sika service started
[MyApp] Setting up Sika sync handlers...
[RegistrationCache] ✅ Initialized
[SikaNative] Service started: true
```

### 2️⃣ Lors de la connexion

```
[MyApp] Auth state changed, performing sync
[SikaNative] Firstname set: true
[SikaSync] ============ START SYNC ============
[SikaSync] Found 0 pending transaction(s)
[SikaSync] ============ SYNC COMPLETE: 0/0 synced ============
```

### 3️⃣ Lors de la détection du wake-word

```
D/SikaWakeWordServiceV2: 🎤 Wake-word detected (loud sound)
D/SikaWakeWordServiceV2: ======== WAKE-WORD DETECTED ========
D/SikaWakeWordServiceV2: Username: David
D/SikaWakeWordServiceV2: 🔊 TTS: Oui David ?
D/SikaWakeWordServiceV2: Starting command capture...
D/SikaWakeWordServiceV2: Ready for speech input
```

### 4️⃣ Lors de la capture de commande

```
D/SikaWakeWordServiceV2: User started speaking
D/SikaWakeWordServiceV2: User finished speaking
D/SikaWakeWordServiceV2: 📝 STT result: "ajoute dépense 5000 transport"
D/SikaWakeWordServiceV2: Parsed intention: add_expense, entities: {amount=5000, category=transport, ...}
```

### 5️⃣ Lors de l'enregistrement de la dépense

```
D/SikaWakeWordServiceV2: 📌 Pending transaction saved (total: 1)
D/SikaWakeWordServiceV2: ✅ Expense added and confirmed via TTS
D/SikaWakeWordServiceV2: 🔊 TTS: Très bien David, j'ai enregistré 5000 FCFA en transport.
D/SikaNative] Transaction added: true
[SikaWakeWordServiceV2: Restarting wake-word detection...
```

### 6️⃣ Lors de la reprise de l'app

```
[MyApp] App resumed, checking for pending transactions
[SikaSync] ============ START SYNC ============
[SikaSync] Found 1 pending transaction(s)
[SikaSync] Syncing transaction #0 (id=...)...
[SikaSync] ✅ Transaction #0 synced successfully
[SikaSync] ============ SYNC COMPLETE: 1/1 synced ============
```

---

## Intégration dans les Formulaires

### Exemple : Formulaire d'Inscription Multi-Étapes

```dart
import 'package:gertonargent_app/data/local/registration_cache.dart';
import 'package:gertonargent_app/services/sika_native.dart';

class RegistrationForm extends StatefulWidget {
  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  void _loadCachedData() {
    // Restaurer les données en cache
    _firstnameController.text = RegistrationCache.getStepAs<String>('firstname') ?? '';
    _lastnameController.text = RegistrationCache.getStepAs<String>('lastname') ?? '';
    _emailController.text = RegistrationCache.getStepAs<String>('email') ?? '';
    _phoneController.text = RegistrationCache.getStepAs<String>('phone') ?? '';
  }

  void _onFirstnameChanged(String value) {
    // Sauvegarder chaque modification
    RegistrationCache.saveStep('firstname', value);
  }

  Future<void> _submitForm() async {
    try {
      // Récupérer toutes les données en cache
      final payload = RegistrationCache.getAllSteps();
      
      debugPrint('[RegistrationForm] Submitting: $payload');

      // Appeler le backend
      final response = await apiService.register(payload);

      if (response.statusCode == 201) {
        // Succès: Sauvegarder le prénom côté natif pour Sika
        final firstname = _firstnameController.text;
        await SikaNative.setUserFirstname(firstname);
        
        // Vider le cache
        await RegistrationCache.clear();
        
        // Naviguer vers le dashboard
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        // Erreur: garder les données en cache pour retry
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(text: 'Erreur d\'inscription'),
        );
      }
    } catch (e) {
      debugPrint('[RegistrationForm] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(text: 'Erreur: $e'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _firstnameController,
          decoration: const InputDecoration(labelText: 'Prénom'),
          onChanged: _onFirstnameChanged,
        ),
        TextField(
          controller: _lastnameController,
          decoration: const InputDecoration(labelText: 'Nom'),
          onChanged: (v) => RegistrationCache.saveStep('lastname', v),
        ),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          onChanged: (v) => RegistrationCache.saveStep('email', v),
        ),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Téléphone'),
          onChanged: (v) => RegistrationCache.saveStep('phone', v),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('S\'inscrire'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
```

### Exemple : Affichage des Transactions Pendantes

```dart
import 'package:gertonargent_app/services/sika_native.dart';

class PendingTransactionsScreen extends StatefulWidget {
  @override
  State<PendingTransactionsScreen> createState() => _PendingTransactionsScreenState();
}

class _PendingTransactionsScreenState extends State<PendingTransactionsScreen> {
  late Future<List<Map<String, dynamic>>> _pendingTransactions;

  @override
  void initState() {
    super.initState();
    _pendingTransactions = SikaNative.readPendingTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _pendingTransactions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return const Text('Aucune transaction en attente');
        }

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return ListTile(
              title: Text('${tx['amount']} FCFA'),
              subtitle: Text(tx['category'] ?? 'Autre'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await SikaNative.removePendingTransaction(index);
                  setState(() {
                    _pendingTransactions = SikaNative.readPendingTransactions();
                  });
                },
              ),
            );
          },
        );
      },
    );
  }
}
```

---

## Troubleshooting

### Problème: "Permission denied" pour le microphone

**Solution:**
1. Demander la permission au runtime:
```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestMicrophonePermission() async {
  final status = await Permission.microphone.request();
  if (status.isDenied) {
    debugPrint('Microphone permission denied');
  }
}
```

2. Ou accéder aux Paramètres > Applications > Gertonargent > Permissions > Microphone

### Problème: Wake-word ne se déclenche pas

**Diagnostic:**
1. Vérifier que l'app est fermée complètement (Recents/Recent Apps)
2. Vérifier que le service est actif:
   ```bash
   adb shell dumpsys activity services | grep SikaWakeWordServiceV2
   ```
3. Vérifier les permissions microphone et FOREGROUND_SERVICE
4. Parler plus fort et plus clairement "SI-KA"

**Solution:**
- Augmenter le seuil de loudness dans le code:
  ```kotlin
  if (Math.abs(sample) > 4000) loudSamples++  // Augmenter de 3000 à 4000
  ```

### Problème: TTS ne parle pas

**Diagnostic:**
1. Vérifier que le volume du device n'est pas muet
2. Vérifier que TTS est initialisée:
   ```bash
   adb logcat | grep "TextToSpeech"
   ```

**Solution:**
- Tester TTS manuellement:
```dart
final tts = TextToSpeech();
await tts.setLanguage('fr-FR');
await tts.speak('Ceci est un test');
```

### Problème: Transactions pas synchronisées

**Diagnostic:**
1. Vérifier que l'utilisateur est authentifié (token disponible)
2. Vérifier les logs SikaSync:
   ```bash
   adb logcat | grep SikaSync
   ```
3. Vérifier que le backend est accessible:
   ```bash
   curl -X POST http://192.168.75.46:8000/api/transactions \
     -H "Authorization: Bearer TOKEN" \
     -d '{"amount": 5000, "category": "transport"}'
   ```

**Solution:**
- Appeler manuellement la sync:
```dart
await SikaSync.syncPendingTransactions(apiService: apiService);
```

### Problème: STT ne reconnait rien

**Diagnostic:**
1. Vérifier les permissions RECORD_AUDIO
2. Vérifier que le microphone n'est pas bloqué
3. Vérifier que le device supporte STT (Android 5.0+)

**Solution:**
- Tester STT manuellement:
```dart
import 'package:speech_to_text/speech_to_text.dart' as stt;

final speechToText = stt.SpeechToText();
await speechToText.initialize();
speechToText.listen();
```

---

## Notes de Performance

### Consommation de batterie
- Le service wake-word consomme ~5-10% de batterie par heure
- Utiliser les optimisations de batterie du device
- Considérer une interface on/off pour Sika dans Settings

### Permissions OEM
Certains fabricants (Samsung, Xiaomi, etc.) ont des restrictions:
- **Samsung**: Aller dans Paramètres > Applications > Gertonargent > Autorisations > Microphone > Autoriser toujours
- **Xiaomi**: Settings > Permissions > Microphone > Always allow
- **Oppo**: Settings > App Permissions > Microphone > Permit all the time

### Alternative: Wake-word avec Vosk
Si tu veux utiliser Vosk pour une meilleure reconnaissance:
1. Télécharger le modèle français: https://alphacephei.com/vosk/models
2. Extraire dans `android/app/src/main/assets/vosk-model-small-fr`
3. Décommenter les lignes Vosk dans `SikaWakeWordServiceV2.kt`

---

## Prochaines Étapes

1. ✅ Tester le wake-word
2. ✅ Tester les commandes de dépense
3. ✅ Tester la synchronisation au démarrage
4. 📋 Ajouter plus de commandes (rappels, conseils, etc.)
5. 📋 Intégrer avec l'IA pour réponses contextuelles
6. 📋 Support iOS (Speech Recognition + Background Modes)
7. 📋 Optimisations batterie et performance

---

**Questions?** Consultez les logs avec `adb logcat | grep Sika` 🎤
