import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/local/registration_cache.dart';
import 'services/sika_sync.dart';
import 'services/sika_native.dart';
// features/ai_assistant import removed (unused)
import 'features/auth/providers/auth_provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/navigation/main_navigation.dart';
import 'data/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and registration cache
  await Hive.initFlutter();
  await RegistrationCache.init();

  debugPrint('[Main] ✅ App initialization started');

  // Start native Sika wake-word service via MethodChannel
  try {
    await SikaNative.startSikaService();
    debugPrint('[Main] ✅ Native Sika service started');
  } catch (e) {
    debugPrint('[Main] ⚠️ Could not start native Sika service: $e');
  }

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
    // Initialize Sika sync and handle lifecycle events
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      debugPrint('[MyApp] Setting up Sika sync handlers...');

      // 1. Sync on initial token availability
      final auth = ref.read(authProvider);
      if (auth.token != null) {
        debugPrint('[MyApp] Token available, performing initial sync');
        final apiService = ref.read(apiServiceProvider);
        apiService.setToken(auth.token!);

        // Sync pending transactions
        await SikaSync.syncPendingTransactions(apiService: apiService);

        // Also set user firstname in native service for Sika to use
        if (auth.user?.firstName != null) {
          await SikaNative.setUserFirstname(auth.user!.firstName!);
        }
      }

      // 2. Listen for auth changes (login/logout)
      ref.listen<AuthState>(authProvider, (previous, next) async {
        if (next.token != null && previous?.token != next.token) {
          debugPrint('[MyApp] Auth state changed, performing sync');
          final apiService = ref.read(apiServiceProvider);
          apiService.setToken(next.token!);

          // Set firstname in native service
          if (next.user?.firstName != null) {
            await SikaNative.setUserFirstname(next.user!.firstName!);
          }

          // Sync pending transactions
          await SikaSync.syncPendingTransactions(apiService: apiService);
        }
      });

      // 3. Handle app resume (when user comes back to app)
      SystemChannels.lifecycle.setMessageHandler((msg) async {
        if (msg == AppLifecycleState.resumed.toString()) {
          debugPrint('[MyApp] App resumed, checking for pending transactions');
          final auth2 = ref.read(authProvider);
          if (auth2.token != null) {
            final apiService = ref.read(apiServiceProvider);
            apiService.setToken(auth2.token!);

            // Sync pending transactions
            await SikaSync.syncPendingTransactions(apiService: apiService);
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
