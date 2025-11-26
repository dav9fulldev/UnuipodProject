# ✅ Sika Implementation Checklist

## 📋 Pre-Implementation Checklist

### Project Structure
- [ ] Vérifier que le projet a une structure standard Flutter:
  ```
  gertonargent_app/
  ├── android/
  ├── ios/
  ├── lib/
  ├── pubspec.yaml
  └── README.md
  ```

- [ ] Vérifier la version Flutter minimum:
  ```bash
  flutter --version
  ```
  Doit être **2.10.0+** minimum

- [ ] Vérifier la version Android:
  - Android 7.0+ (API level 24)
  - Target API 34

### Dependencies
- [ ] Ajouter à `pubspec.yaml`:
  ```yaml
  hive_flutter: ^2.0.0
  flutter_riverpod: ^2.4.0
  ```

- [ ] Exécuter:
  ```bash
  flutter pub get
  flutter pub run build_runner build
  ```

---

## 📁 File Creation Checklist

### Kotlin Files (Android/Native)

- [ ] **SikaWakeWordServiceV2.kt**
  - Location: `android/app/src/main/kotlin/com/example/gertonargent_app/`
  - Status: ✅ Created
  - Lines: ~400
  - Dependencies: Android core, TextToSpeech, SpeechRecognizer, SharedPreferences

- [ ] **SikaOverlayServiceV2.kt**
  - Location: `android/app/src/main/kotlin/com/example/gertonargent_app/`
  - Status: ✅ Created
  - Lines: ~150
  - Dependencies: Android view, animation

- [ ] **BootReceiver.kt**
  - Location: `android/app/src/main/kotlin/com/example/gertonargent_app/`
  - Status: ✅ Created
  - Lines: ~40
  - Purpose: Auto-start on device boot

- [ ] **SikaConfig.kt**
  - Location: `android/app/src/main/kotlin/com/example/gertonargent_app/`
  - Status: ✅ Created
  - Lines: ~150
  - Purpose: Centralized configuration constants

- [ ] **MainActivity.kt (MODIFIED)**
  - Location: `android/app/src/main/kotlin/com/example/gertonargent_app/`
  - Status: ✅ Updated with MethodChannel handlers
  - Changes:
    - [ ] Import MethodChannel (android.view.MethodChannel)
    - [ ] In `configureFlutterEngine()`: Setup MethodChannel
    - [ ] Add handler methods for all 15+ cases
    - [ ] Add helper methods (startSikaServiceV2, etc.)

### Dart Files (Flutter)

- [ ] **lib/services/sika_native.dart**
  - Status: ✅ Created
  - Lines: ~200
  - Purpose: Flutter wrapper for MethodChannel calls
  - Key methods: All 10+ static async methods with error handling

- [ ] **lib/services/sika_sync.dart**
  - Status: ✅ Created
  - Lines: ~150
  - Purpose: Auto-sync orchestration with mutex guard
  - Key feature: Thread-safe concurrent prevention

- [ ] **lib/data/local/registration_cache.dart (REPLACED)**
  - Status: ✅ Replaced with enhanced version
  - Lines: ~180
  - Purpose: Hive-based multi-step form cache
  - Key API: saveStep(), getStepAs<T>(), getAllSteps(), clear()

- [ ] **lib/main.dart (MODIFIED)**
  - Status: ✅ Updated
  - Changes:
    - [ ] Import sika_native, sika_sync
    - [ ] In main(): Call RegistrationCache.init() and SikaNative.startSikaService()
    - [ ] In MyApp.build(): Add three lifecycle handlers

### Configuration Files

- [ ] **android/app/src/main/AndroidManifest.xml (MODIFIED)**
  - [ ] Add permissions:
    - [ ] `android.permission.RECORD_AUDIO`
    - [ ] `android.permission.FOREGROUND_SERVICE`
    - [ ] `android.permission.WAKE_LOCK`
    - [ ] `android.permission.SYSTEM_ALERT_WINDOW`
    - [ ] `android.permission.INTERNET`
  
  - [ ] Add service declarations:
    ```xml
    <service android:name=".SikaWakeWordServiceV2" ... />
    <service android:name=".SikaOverlayServiceV2" ... />
    <receiver android:name=".BootReceiver" ... />
    ```

- [ ] **android/app/build.gradle (OPTIONAL)**
  - [ ] Verify minimum SDK is 24
  - [ ] Verify target SDK is 34

- [ ] **ios/Runner/Info.plist (OPTIONAL)**
  - [ ] Add NSMicrophoneUsageDescription
  - [ ] Add NSSpeechRecognitionUsageDescription
  - [ ] Add UIBackgroundModes

### Documentation Files

- [ ] **SIKA_IMPLEMENTATION_GUIDE.md**
  - Status: ✅ Created
  - Purpose: Complete setup and test guide
  - Sections: Architecture, Permissions, Installation, Live Testing, Troubleshooting

- [ ] **SIKA_TEST_SCENARIOS.md**
  - Status: ✅ Created
  - Purpose: 10+ detailed test scenarios
  - Sections: Happy path, Wake-word, Multi-commands, Sync, Errors, etc.

- [ ] **SIKA_VOICE_COMMANDS.md**
  - Status: ✅ Created
  - Purpose: Voice command reference
  - Content: Supported commands, categories, parsing rules

---

## 🔧 Code Modification Checklist

### MainActivity.kt Changes

- [ ] **Import statements** - Add if not present:
  ```kotlin
  import android.view.MethodChannel
  import com.example.gertonargent_app.SikaWakeWordServiceV2
  import com.example.gertonargent_app.SikaOverlayServiceV2
  ```

- [ ] **configureFlutterEngine()** method:
  ```kotlin
  MethodChannel(flutterEngine.dartExecutor.binaryMessenger, 
    "com.gertonargent/sika").setMethodCallHandler { call, result ->
    when (call.method) {
      "startSikaService" -> result.success(startSikaServiceV2())
      // ... 15+ more cases
    }
  }
  ```

- [ ] **Helper methods** - Add:
  - [ ] `startSikaServiceV2()`
  - [ ] `stopSikaServiceV2()`
  - [ ] `isSikaServiceRunning()`
  - [ ] All transaction management methods
  - [ ] All preference access methods

### lib/main.dart Changes

- [ ] **Imports section** - Add:
  ```dart
  import 'services/sika_native.dart';
  import 'services/sika_sync.dart';
  ```

- [ ] **main() function** - Add initialization:
  ```dart
  void main() {
    WidgetsFlutterBinding.ensureInitialized();
    await RegistrationCache.init();
    await SikaNative.startSikaService();
    runApp(const MyApp());
  }
  ```

- [ ] **MyApp.build()** - Add lifecycle handlers:
  - [ ] Token availability listener
  - [ ] Auth state change listener
  - [ ] App resume listener (SystemChannels.lifecycle)

---

## 🎯 Android Manifest Modifications

### Permissions to Add

```xml
<!-- Sika Voice Assistant Permissions -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Services to Register

```xml
<service
    android:name=".SikaWakeWordServiceV2"
    android:exported="false"
    android:foregroundServiceType="microphone"
    android:permission="android.permission.FOREGROUND_SERVICE" />

<service
    android:name=".SikaOverlayServiceV2"
    android:exported="false" />
```

### Boot Receiver to Register

```xml
<receiver
    android:name=".BootReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

---

## 🧪 Pre-Testing Checklist

### Code Validation

- [ ] No compilation errors:
  ```bash
  flutter analyze
  ```

- [ ] No Dart/Flutter issues:
  ```bash
  flutter run --verbose
  ```

- [ ] Android Lint passes (Optional):
  ```bash
  ./gradlew lint
  ```

### Device Setup

- [ ] Device connected:
  ```bash
  adb devices
  ```

- [ ] Device is Android 7.0+ (API 24+)

- [ ] Device storage has at least 500MB free

### Permission Pre-Check

- [ ] Microphone permission not globally denied
- [ ] Overlay permission (SYSTEM_ALERT_WINDOW) not globally denied
- [ ] Developer mode enabled if needed

---

## 🚀 Testing Checklist

### Installation Phase

- [ ] Build succeeds:
  ```bash
  flutter clean
  flutter pub get
  flutter run -d <device_id>
  ```

- [ ] App launches without crash

- [ ] Permission prompts appear correctly

### Initialization Phase

- [ ] App shows splash screen

- [ ] Auth/Login flow works

- [ ] Registration cache loads (if re-running)

- [ ] Logs show:
  ```
  [SikaNative] Service started: true
  [RegistrationCache] ✅ Initialized
  ```

### Service Startup Phase

- [ ] Service starts in background

- [ ] Service appears in active services:
  ```bash
  adb shell dumpsys activity services | grep "SikaWakeWordServiceV2"
  ```

- [ ] Logs show wake-word detection loop active

### Wake-Word Detection Phase

- [ ] Say "Sika" while app is backgrounded

- [ ] Overlay appears (black bubble with animation)

- [ ] TTS plays: "Oui [prénom] ?"

- [ ] Logs show:
  ```
  D/SikaWakeWordServiceV2: 🎤 Wake-word detected
  D/SikaWakeWordServiceV2: Starting STT capture...
  ```

### Command Capture Phase

- [ ] Say a command: "ajoute 5000 transport"

- [ ] STT captures the audio

- [ ] Logs show:
  ```
  D/SikaWakeWordServiceV2: 📝 STT result: "ajoute 5000 transport"
  ```

### Parsing Phase

- [ ] Command is parsed correctly

- [ ] Amount is extracted: 5000

- [ ] Category is extracted: transport

- [ ] Logs show:
  ```
  D/SikaWakeWordServiceV2: Parsed intention: add_expense, entities: {amount=5000, ...}
  ```

### Saving Phase

- [ ] Transaction is saved to SharedPreferences

- [ ] TTS plays confirmation

- [ ] Logs show:
  ```
  D/SikaWakeWordServiceV2: 📌 Pending transaction saved (total: 1)
  ```

### Overlay Phase

- [ ] Overlay shows TTS/STT feedback during interaction

- [ ] Overlay auto-hides after command

- [ ] No UI freezes or janks

### Sync Phase

- [ ] Open app

- [ ] Auto-sync triggers automatically

- [ ] Logs show:
  ```
  [SikaSync] ============ START SYNC ============
  [SikaSync] Found 1 pending transaction(s)
  [SikaSync] ✅ Transaction synced successfully
  [SikaSync] ============ SYNC COMPLETE: 1/1 ============
  ```

- [ ] Transaction appears in dashboard/history

- [ ] SharedPreferences is cleared

### Registration Cache Phase

- [ ] Fill form partially

- [ ] Close app completely

- [ ] Reopen app

- [ ] Form data is restored from cache

- [ ] Complete form and submit

- [ ] Cache is cleared after success

---

## 📊 Performance Checklist

- [ ] App startup time < 3 seconds

- [ ] Wake-word detection response < 1 second

- [ ] STT latency < 2 seconds

- [ ] Overlay animation smooth (60 FPS)

- [ ] Battery usage < 10% per hour (while idle with Sika)

- [ ] No memory leaks:
  ```bash
  adb shell dumpsys meminfo com.example.gertonargent_app | tail -20
  ```

---

## 🐛 Troubleshooting Checklist

If something doesn't work:

- [ ] Check logcat:
  ```bash
  adb logcat | grep -i sika
  ```

- [ ] Check permissions:
  ```bash
  adb shell pm list permissions | grep -i record
  adb shell pm list permissions | grep -i microphone
  ```

- [ ] Check service status:
  ```bash
  adb shell dumpsys activity services | grep Sika
  ```

- [ ] Check SharedPreferences:
  ```bash
  adb shell "su -c 'cat /data/data/com.example.gertonargent_app/shared_prefs/sika_prefs.xml'"
  ```

- [ ] Restart device and test again

- [ ] Re-install app and test

---

## 📝 Documentation Checklist

- [ ] SIKA_IMPLEMENTATION_GUIDE.md reviewed

- [ ] SIKA_TEST_SCENARIOS.md reviewed

- [ ] SIKA_VOICE_COMMANDS.md reviewed

- [ ] Team knows about:
  - [ ] MethodChannel name: `com.gertonargent/sika`
  - [ ] SharedPreferences key: `sika_prefs`
  - [ ] Wake-word: "Sika"
  - [ ] Default language: French
  - [ ] Supported categories (transport, repas, etc.)

---

## 🎓 Knowledge Transfer Checklist

- [ ] Team member A knows:
  - [ ] How to modify wake-word detection threshold
  - [ ] How to add new voice commands
  - [ ] How to debug MethodChannel calls

- [ ] Team member B knows:
  - [ ] How to customize TTS messages
  - [ ] How to handle permission errors
  - [ ] How to manage pending transactions

- [ ] Team member C knows:
  - [ ] How to sync transactions manually
  - [ ] How to clear cache/prefs if needed
  - [ ] How to test on multiple devices

---

## ✨ Final Sign-Off

- [ ] All files created/modified
- [ ] Code compiles without errors
- [ ] Tests pass (all 10 scenarios)
- [ ] Documentation complete
- [ ] Team trained
- [ ] Ready for production

**Status:** 🚀 **Ready to Deploy**

Date: _______________
Tester: _______________
Sign-Off: _______________

---

**Notes:**
```
_____________________________________________________________________
_____________________________________________________________________
_____________________________________________________________________
_____________________________________________________________________
```
