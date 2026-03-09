import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'services/wallet_connect_service.dart';
import 'pages/home_page.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';

/// Application entry point.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────────────────────
  // Guard against the "duplicate-app" error that appears during hot-restart:
  // Firebase.initializeApp throws if a [DEFAULT] app already exists.
  // Checking Firebase.apps.isEmpty is the correct pattern.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✓ Firebase initialized successfully');
    } else {
      // Already initialised (e.g. hot restart) — reuse the existing app.
      print('✓ Firebase already initialized, reusing existing app');
    }
  } catch (e) {
    // Log but don't crash — Google/email login will fail gracefully,
    // and wallet-only login still works via JWT.
    print('✗ Firebase initialization failed: $e');
  }

  // ── Coinbase Wallet SDK ───────────────────────────────────────────────────
  // Initialise early so the SDK relay connection is ready before the user
  // taps "Sign in with Base Wallet".
  try {
    await WalletConnectService.init();
    print('✓ WalletConnect initialized successfully');
  } catch (e) {
    // Non-fatal — user can still use Google/email login.
    print('✗ WalletConnect init failed: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

/// Root widget. Manages theme and navigation based on authentication state.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'AiCoinTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          // StreamBuilder gates the entire app behind auth state.
          // AuthService.appAuthStateChanges() emits true when:
          //   - Firebase session is active (Google / email / custom token), OR
          //   - A JWT is stored in SharedPreferences (wallet-only user)
          home: StreamBuilder<bool>(
            stream: AuthService.appAuthStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentGreen,
                      ),
                    ),
                  ),
                );
              }
              return snapshot.data == true
                  ? const HomePage()
                  : const LoginPage();
            },
          ),
        );
      },
    );
  }
}