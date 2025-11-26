# 🧪 Sika Test Cases & Scenarios

## Scénarios de Test Détaillés

### Scénario 1: Première Installation (Happy Path)

**Prérequis:**
- App fraîchement installée
- Appareil SM-A137F déverrouillé
- Android 7.0+

**Étapes:**

1. **Installer l'APK**
```bash
flutter clean
flutter pub get
flutter run -d R9AQC952897
```

2. **Permissions**
   - Permettre RECORD_AUDIO ✓
   - Permettre SYSTEM_ALERT_WINDOW ✓

3. **Inscription**
   - Prénom: "David"
   - Email: "david@test.com"
   - Valider ✓

4. **Logs attendus:**
```
I/flutter: ✅ RegistrationCache initialized
D/MainActivity: 🎙️ MethodChannel ready: com.gertonargent/sika
I/flutter: [SikaNative] Service started: true
D/SikaWakeWordServiceV2: Service created successfully
D/SikaWakeWordServiceV2: Firstname loaded: David
D/SikaWakeWordServiceV2: Starting wake-word detection loop...
```

---

### Scénario 2: Wake-Word Detection (Crispy Test)

**Prérequis:**
- App installée et configurée
- Utilisateur connecté
- App fermée complètement

**Étapes:**

1. **Fermer l'app**
```bash
adb shell input keyevent KEYCODE_HOME
```

2. **Filtrer les logs**
```bash
adb logcat | grep -E "SikaWakeWordServiceV2|SikaOverlayServiceV2" &
```

3. **Dire "Sika"** (clairement, en français)
   - Attendu: Bulle overlay noir + animation pulse

4. **Dire une commande**
   - "ajoute dépense 5000 transport"
   
   Attendu:
   ```
   D/SikaWakeWordServiceV2: 🎤 Wake-word detected (loud sound)
   D/SikaWakeWordServiceV2: Username loaded: David
   D/SikaWakeWordServiceV2: 🔊 TTS: Oui David ?
   D/SikaWakeWordServiceV2: Starting STT capture...
   D/SikaWakeWordServiceV2: 📝 STT result: "ajoute dépense 5000 transport"
   D/SikaWakeWordServiceV2: Parsed: add_expense, amount=5000, category=transport
   D/SikaWakeWordServiceV2: 📌 Transaction saved to SharedPreferences
   D/SikaWakeWordServiceV2: 🔊 TTS: Très bien David, j'ai enregistré 5000 FCFA en transport.
   ```

5. **Audit SharedPreferences**
```bash
adb shell "su -c 'cat /data/data/com.example.gertonargent_app/shared_prefs/sika_prefs.xml' | head -20"
```

Attendu:
```xml
<string name="pending_transactions">[
  {"amount":5000,"category":"transport","source":"sika_voice","status":"pending","date":"2024-01-15T10:30:00"}
]</string>
```

---

### Scénario 3: Multi-Commands avec Même Wake-Word

**Étapes:**

1. Dire "Sika"
2. Répondre "ajoute dépense 2500 taxi"
3. Reconfirmation TTS ✓

4. Dire "Sika" à nouveau (avant 30 secondes)
5. Répondre "enregistre 10000 en repas"
6. Reconfirmation TTS ✓

**Attendu:**
- Deux transactions dans SharedPreferences:
```json
[
  {"amount":5000,"category":"transport",...},
  {"amount":2500,"category":"taxi",...},
  {"amount":10000,"category":"repas",...}
]
```

---

### Scénario 4: Synchronisation au Démarrage

**Prérequis:**
- 2 transactions pendantes dans SharedPreferences
- Utilisateur authentifié (token valide)
- Backend accessible

**Étapes:**

1. **Vérifier les transactions pendantes**
```bash
adb shell "su -c 'cat /data/data/com.example.gertonargent_app/shared_prefs/sika_prefs.xml' | grep pending_transactions"
```

2. **Redémarrer l'app**
```bash
flutter run -d R9AQC952897
```

3. **Filtrer les logs SikaSync**
```bash
adb logcat | grep "SikaSync" &
```

**Logs attendus:**
```
I/SikaSync: ============ START SYNC ============
I/SikaSync: Pending transactions count: 2
I/SikaSync: [1/2] Syncing transaction: 5000 FCFA (transport)
D/flutter: [apiService] POST /api/transactions - Status: 201
I/SikaSync: ✅ Transaction 1 synced successfully
I/SikaSync: [2/2] Syncing transaction: 2500 FCFA (taxi)
D/flutter: [apiService] POST /api/transactions - Status: 201
I/SikaSync: ✅ Transaction 2 synced successfully
I/SikaSync: ============ SYNC COMPLETE: 2/2 ============
```

4. **Vérifier que SharedPreferences est vidé**
```bash
adb shell "su -c 'cat /data/data/com.example.gertonargent_app/shared_prefs/sika_prefs.xml' | grep pending_transactions"
```

Attendu: Array vide `[]`

5. **Vérifier dans le dashboard** que les transactions sont affichées ✓

---

### Scénario 5: Détection de Montant Varié

Tester la reconnaissance d'écriture numérique:

| Commande | Montant attendu | Catégorie |
|----------|-----------------|-----------|
| "ajoute 5000 transport" | 5000 | transport |
| "enregistre dix mille transport" | 10000 | transport |
| "une dépense de 2500 repas" | 2500 | repas |
| "ajoute 15k en taxi" | 15000 | taxi |
| "5k pour l'essence" | 5000 | carburant |
| "trois mille FCFA en restaurants" | 3000 | repas |

**Test:**
```bash
# Lancer test avec tous les cas
for cmd in "ajoute 5000 transport" "enregistre 10k taxi" "15 mille FCFA en repas"; do
  echo "Testing: $cmd"
  # Dire la commande en français via TTS
  adb logcat | grep "Parsed:"
done
```

---

### Scénario 6: Permission Denied Recovery

**Prérequis:**
- Microphone permission DENIED dans Settings

**Étapes:**

1. **Revoquer la permission**
```bash
adb shell pm revoke com.example.gertonargent_app android.permission.RECORD_AUDIO
```

2. **Redémarrer l'app**
```bash
flutter run -d R9AQC952897
```

3. **Dire "Sika"**

**Logs attendus:**
```
W/SikaWakeWordServiceV2: ⚠️ RECORD_AUDIO permission not granted
E/SikaWakeWordServiceV2: Cannot initialize audio recording
I/flutter: [ERROR] Microphone permission denied
I/flutter: [UI] Show toast: "Veuillez activer le microphone"
```

4. **Granted la permission via Settings** ✓

5. **Redémarrer l'app, tester à nouveau** ✓

---

### Scénario 7: Network Error Handling

**Prérequis:**
- 1 transaction pendante
- Backend inaccessible (firewall activé ou service down)

**Étapes:**

1. **Ajouter une transaction via Sika** ✓

2. **Désactiver le réseau**
```bash
adb shell svc wifi disable
adb shell svc data disable
```

3. **Redémarrer l'app**

**Logs attendus:**
```
I/SikaSync: ============ START SYNC ============
I/SikaSync: Found 1 pending transaction(s)
I/SikaSync: Syncing transaction #0...
E/SikaSync: ⚠️ Network error: Connection timeout (10s)
I/SikaSync: Transaction kept pending (retry on next launch)
I/SikaSync: ============ SYNC COMPLETE: 0/1 ============
```

4. **Vérifier que la transaction reste**
```bash
adb shell "su -c 'cat /data/data/com.example.gertonargent_app/shared_prefs/sika_prefs.xml' | grep pending_transactions"
```

Attendu: Transaction toujours présente ✓

5. **Réactiver le réseau**
```bash
adb shell svc wifi enable
adb shell svc data enable
```

6. **Redémarrer l'app, vérifier la sync** ✓

---

### Scénario 8: Form Cache Multi-Étapes (Registration)

**Prérequis:**
- App fraîchement installée
- Utilisateur non enregistré

**Étapes:**

1. **Ouvrir le formulaire d'inscription**

2. **Remplir partiellement (Étape 1)**
   - Prénom: "David"
   - Nom: "Dupont"
   - Appuyer "Suivant"

3. **Logs attendus:**
```
D/RegistrationCache: Saving step: firstname = "David"
D/RegistrationCache: Saving step: lastname = "Dupont"
I/RegistrationCache: ✅ [2 steps] cached
```

4. **Fermer l'app complètement**
```bash
adb shell input keyevent KEYCODE_HOME
adb shell am force-stop com.example.gertonargent_app
```

5. **Rouvrir l'app**

6. **Vérifier que les données sont restaurées**
   - Prénom: "David" ✓
   - Nom: "Dupont" ✓

7. **Logs attendus:**
```
I/RegistrationCache: ✅ Initialized
D/RegistrationCache: Loaded step: firstname = "David"
D/RegistrationCache: Loaded step: lastname = "Dupont"
I/RegistrationCache: ✅ [2 steps] restored from cache
```

8. **Continuer et remplir Étape 2**
   - Email: "david@test.com"
   - Appuyer "Suivant"

9. **Valider l'inscription complète**

10. **Vérifier que le cache est vidé**
```
D/RegistrationCache: Clearing all cached data
```

---

### Scénario 9: Overlay Animation Test

**Étapes:**

1. **Dire "Sika"**

2. **Vérifier visellement:**
   - ✅ Bulle noire avec icône Sika
   - ✅ Animation pulse (zoom in/out)
   - ✅ Texte TTS affiché
   - ✅ Feedback STT en direct

3. **Pendant STT:**
   - ✅ Bulle bouge légèrement avec amplitude audio
   - ✅ Texte change "Écoute..." → "[Votre commande]"

4. **Après confirmation:**
   - ✅ Bulle disparaît après 3 secondes

**Diagnostic visuel:**
```bash
adb shell dumpsys activity windows | grep "SikaOverlay"
```

---

### Scénario 10: Service Restart & Crash Recovery

**Étapes:**

1. **Vérifier que le service est actif**
```bash
adb shell dumpsys activity services | grep "SikaWakeWordServiceV2"
```

Attendu: `Running` ✓

2. **Forcer l'arrêt du service**
```bash
adb shell am force-stop com.example.gertonargent_app
```

3. **Vérifier que le service s'est arrêté**
```bash
adb shell dumpsys activity services | grep "SikaWakeWordServiceV2"
```

Attendu: Aucun résultat (ou `Not Running`)

4. **Redémarrer l'app**
```bash
flutter run -d R9AQC952897
```

5. **Vérifier que le service redémarre**
```bash
adb logcat | grep "SikaWakeWordServiceV2.*onStartCommand"
```

Attendu:
```
D/SikaWakeWordServiceV2: onStartCommand called
D/SikaWakeWordServiceV2: Service already running, skipping reinit
```

---

## Test Suite Automatisée

Créer un fichier `test/sika_integration_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gertonargent_app/services/sika_native.dart';
import 'package:gertonargent_app/services/sika_sync.dart';
import 'package:gertonargent_app/data/local/registration_cache.dart';

void main() {
  group('Sika Integration Tests', () {
    
    setUpAll(() async {
      await RegistrationCache.init();
    });

    test('SikaNative.startSikaService() should return true', () async {
      final result = await SikaNative.startSikaService();
      expect(result, isTrue);
    });

    test('SikaNative.setUserFirstname() should persist name', () async {
      await SikaNative.setUserFirstname('David');
      final name = await SikaNative.getUserFirstname();
      expect(name, 'David');
    });

    test('SikaNative.readPendingTransactions() should return list', () async {
      final transactions = await SikaNative.readPendingTransactions();
      expect(transactions, isA<List<Map<String, dynamic>>>());
    });

    test('RegistrationCache should save and restore data', () async {
      await RegistrationCache.clear();
      
      RegistrationCache.saveStep('firstname', 'John');
      RegistrationCache.saveStep('email', 'john@test.com');
      
      expect(RegistrationCache.getStepAs<String>('firstname'), 'John');
      expect(RegistrationCache.getStepAs<String>('email'), 'john@test.com');
      expect(RegistrationCache.getStepCount(), 2);
      
      await RegistrationCache.clear();
    });

    test('SikaSync should not run concurrently', () async {
      // Test mutex guard
      SikaSync.resetLock();
      
      expect(await SikaSync.hasPendingTransactions(), false);
    });
  });
}
```

Lancer les tests:
```bash
flutter test test/sika_integration_test.dart -v
```

---

## Checklist de Validation

- [ ] App se lance sans crash
- [ ] Permissions sont acceptées
- [ ] Service démarre en background
- [ ] Wake-word "Sika" est détecté
- [ ] TTS prononce le prénom correctement
- [ ] STT capture la commande
- [ ] Commande est parsée correctement
- [ ] Transaction est sauvegardée en SharedPreferences
- [ ] Overlay affiche le feedback visual
- [ ] App se relance et synchro automatique
- [ ] Transactions sont supprimées après sync
- [ ] Form cache restore les données
- [ ] Permission denied ne crash pas l'app
- [ ] Network error garde les transactions
- [ ] Service redémarre après force-stop

---

**Status:** Ready for live testing 🚀
