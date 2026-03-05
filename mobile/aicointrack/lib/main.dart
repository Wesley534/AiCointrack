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

/// Application entry point with Firebase initialization
void main() async {
  // Ensure Flutter bindings are initialized before calling async code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for all platforms
  // Uses firebase_options.dart which contains platform-specific configuration
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    print('✓ Firebase initialized successfully');
  } catch (e) {
    print('✗ Firebase initialization failed: $e');
  }

  // Initialize WalletConnect early so relay is ready by login time
  try {
    await WalletConnectService.init();
    print('✓ WalletConnect initialized successfully');
  } catch (e) {
    print('✗ WalletConnect init failed: $e');
    // Non-fatal — user can still use Google/email login
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

/// Root widget of the application
/// Manages theme and navigation based on authentication state
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'CoinTrack',
          debugShowCheckedModeBanner: false,
          // Use theme system with light/dark mode support
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          // Stream builder to manage navigation based on authentication state
          // This ensures the user is automatically logged out if their session expires
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
              if (snapshot.data == true) {
                return const HomePage();
              }
              return const LoginPage();
            },
          ),
        );
      },
    );
  }
}
