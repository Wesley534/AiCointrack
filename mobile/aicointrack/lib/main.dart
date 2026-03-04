import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✓ Firebase initialized successfully');
  } catch (e) {
    print('✗ Firebase initialization failed: $e');
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
          home: StreamBuilder<dynamic>(
            // Listen to Firebase authentication state changes
            stream: AuthService.authStateChanges(),
            builder: (context, snapshot) {
              // Connection state check
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show loading screen while checking authentication state
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

              // If user is signed in, show HomePage; otherwise show LoginPage
              if (snapshot.hasData && snapshot.data != null) {
                return const HomePage();
              } else {
                return const LoginPage();
              }
            },
          ),
        );
      },
    );
  }
}
