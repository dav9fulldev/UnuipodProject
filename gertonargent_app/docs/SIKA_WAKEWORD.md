# Sika Wake-Word & Background Listening — Notes d'intégration

Ce document décrit les limitations, permissions et options pour rendre "Sika" capable d'une écoute continue / wake-word.

## Rappel important
- Le code fourni dans `lib/features/ai_assistant/sika_assistant.dart` implémente une écoute continue *en foreground* (lorsque l'application est ouverte et à l'écran).
- Pour obtenir un comportement "Siri-like" (wake-word en arrière-plan lorsque l'app est fermée), il faut intégrer un moteur de wake-word natif (Porcupine/Picovoice, ou un modèle TFLite) et exécuter une capture audio via un service natif (ForegroundService Android, background audio iOS). Cela requiert du code natif et parfois une licence commerciale.

## Ce que j'ai ajouté
- Dépendances: `speech_to_text`, `flutter_tts`, `http` (dans `pubspec.yaml`).
- Widget Flutter: `lib/features/ai_assistant/sika_assistant.dart` (écoute foreground, détection du mot 'Sika', capture de commande, parsing d'exemple, TTS, envoi au backend).
- Android: permissions déjà présentes dans `AndroidManifest.xml` (`RECORD_AUDIO`, `FOREGROUND_SERVICE`, `POST_NOTIFICATIONS`, `INTERNET`).
- iOS: ajouté dans `ios/Runner/Info.plist` :
  - `NSMicrophoneUsageDescription`
  - `NSSpeechRecognitionUsageDescription`
  - `UIBackgroundModes` avec `audio` (optionnel — attention aux règles App Store).

## Limitations techniques
1. Écoute continue en foreground seulement
   - `speech_to_text` fonctionne bien quand l'app est ouverte (foreground). L'approche utilisée capte des résultats partiels et détecte la présence du mot-clé dans le texte transcrit.

2. Wake-word natif (Siri-like) nécessite :
   - Un moteur KWS (keyword spotting) natif : Porcupine (Picovoice), Snowboy (deprecated), ou TF Lite KWS.
   - Un service natif (Android `ForegroundService`) qui lit le flux audio en continu et exécute l'inférence KWS localement.
   - Sur iOS, background audio + utilisation d'un moteur natif ; Apple est strict sur l'usage du micro en arrière-plan.

3. Consommation batterie et vie privée
   - Écoute continue consomme batterie. Indiquez à l'utilisateur la raison et fournissez un toggle pour activer/désactiver l'écoute.
   - Soyez transparent sur l'envoi de données vocales au serveur. Préférez l'analyse locale pour le wake-word et la confidentialité.

## Option recommandée pour production (wake-word natif)
- Picovoice Porcupine
  - Très efficace pour le hotword spotting, faible consommation CPU.
  - Nécessite clé et intégration native (Android & iOS). Picovoice fournit SDKs et exemples.
  - Intégration générale :
    1. Ajouter le binaire/SDK natif pour Android (AAR) et iOS (framework).
    2. Créer un `ForegroundService` (Android) qui capture audio et exécute Porcupine.
    3. Exposer via MethodChannel l'événement `wakeword_detected` au Flutter side.
    4. Quand wakeword détecté, lancer la logique Flutter (TTS / STT session) ou ouvrir une UI.

- TF Lite KWS (open-source)
  - Former ou utiliser un modèle KWS `.tflite` et exécuter l'inférence sur l'audio.
  - Nécessite buffer audio, préprocessing (MFCC), et un runner TFLite.

## Étapes rapides pour tester en local (workflow recommandé)
1. Endpoint backend: assurez-vous que `ApiConstants.baseUrl` pointe vers l'IP accessible par le téléphone (ou utilisez `adb reverse tcp:8000 tcp:8000`).
2. Brancher téléphone, autoriser le micro quand demandé.
3. Lancer l'app via `flutter run -d <deviceId>`.
4. Ouvrir l'écran contenant `SikaAssistant` et dire "Sika" puis la commande (ex: "ajoute une dépense de 5000 FCFA pour taxi").

## Exemples de ressources
- Porcupine (Picovoice): https://picovoice.ai/docs/overview/ 
- Flutter TF Lite plugin: https://pub.dev/packages/tflite_flutter
- Exemple wake-word natif Android: implémentation d'un `ForegroundService` qui capte l'audio et exécute l'inférence KWS.

## Questions / prochaine étape
- Voulez-vous que j'intègre un prototype Porcupine (Flutter + instructions natif) dans ce repo (incluant un service Android minimal) ?
- Préférez-vous d'abord tester la version foreground que nous avons ajoutée et collecter les retours ?

---
Fichier créé automatiquement par l'assistant. Si vous voulez que j'ajoute le code natif pour Porcupine (Android service + iOS integration), dites "Porcupine" et je commencerai par Android ForegroundService + MethodChannel.