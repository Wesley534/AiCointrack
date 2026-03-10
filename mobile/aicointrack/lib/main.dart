import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'pages/home_page.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ─────────────────────────────────────────────────────────────────
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint('✓ Firebase initialized');
  } catch (e) {
    debugPrint('✗ Firebase initialization failed: $e');
  }

  // NOTE: ReownAuthService.init() requires a BuildContext, so it is called
  // lazily the first time LoginPage builds — see LoginPage._initReown().
  // BaseAuthService has no async init — it is fully stateless.

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'CoinTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
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
              if (snapshot.data == true) return const HomePage();
              return const LoginPage();
            },
          ),
        );
      },
    );
  }
}
