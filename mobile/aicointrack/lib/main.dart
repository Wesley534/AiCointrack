import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'pages/home_page.dart';

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

  runApp(const MyApp());
}

/// Root widget of the application
/// Manages theme and navigation based on authentication state
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoinTrack',
      debugShowCheckedModeBanner: false,
      // Configure the application theme - matching MVP design
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0D12),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00E5A0),
          secondary: const Color(0xFF7C6AFA),
          surface: const Color(0xFF111620),
          background: const Color(0xFF0A0D12),
          error: const Color(0xFFEF4444),
        ),
        cardColor: const Color(0xFF161C28),
        dividerColor: const Color(0xFF1E2A3A),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 32,
            color: Color(0xFFE8EDF5),
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 26,
            color: Color(0xFFE8EDF5),
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: Color(0xFFE8EDF5),
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF6B7A90),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5A0),
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF161C28),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E2A3A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E2A3A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00E5A0), width: 2),
          ),
        ),
        useMaterial3: true,
      ),
      // Stream builder to manage navigation based on authentication state
      // This ensures the user is automatically logged out if their session expires
      home: StreamBuilder<dynamic>(
        // Listen to Firebase authentication state changes
        stream: AuthService.authStateChanges(),
        builder: (context, snapshot) {
          // Connection state check
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loading screen while checking authentication state
            return const Scaffold(
              backgroundColor: Color(0xFF0A0D12),
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5A0)),
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
      // Error handling for production
      onGenerateTitle: (BuildContext context) => 'AICoinTrack',
    );
  }
}
