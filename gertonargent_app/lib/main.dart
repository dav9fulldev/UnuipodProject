import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/local/registration_cache.dart';
import 'features/ai_assistant/sika_sync.dart';
import 'features/ai_assistant/sika_voice_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/navigation/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await RegistrationCache.init();

  // Initialize Sika voice service (independent of UI, keeps running in background)
  final voiceService = SikaVoiceService();
  await voiceService.initialize(onWakeWordDetected: (String msg) {
    debugPrint('Wake-word detected: $msg');
  });

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // schedule a one-time init after the first frame: perform Sika sync when token available
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // Wait for token to be set in auth provider; if already set, sync now
      final auth = ref.read(authProvider);
      if (auth.token != null) {
        // ensure ApiService has token
        ref.read(apiServiceProvider).setToken(auth.token!);
        await SikaSync.syncPendingTransactions();
      }
      // also listen for auth changes (login) to trigger sync
      ref.listen<AuthState>(authProvider, (previous, next) async {
        if (next.token != null && previous?.token != next.token) {
          ref.read(apiServiceProvider).setToken(next.token!);
          await SikaSync.syncPendingTransactions();
        }
      });
      // handle app resume to trigger sync
      SystemChannels.lifecycle.setMessageHandler((msg) async {
        if (msg == AppLifecycleState.resumed.toString()) {
          final auth2 = ref.read(authProvider);
          if (auth2.token != null) {
            ref.read(apiServiceProvider).setToken(auth2.token!);
            await SikaSync.syncPendingTransactions();
          }
        }
        return null;
      });
    });
    return MaterialApp(
      title: 'GèrTonArgent',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const MainNavigation(),
      },
    );
  }
}
