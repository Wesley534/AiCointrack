import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'services/token_service.dart';
import 'services/sync_service.dart';
import 'services/cache_service.dart';
import 'db/local_database.dart';
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

  // ── Local SQLite database ──────────────────────────────────────────────────
  try {
    await LocalDatabase.database;  // pre-open / create tables
    debugPrint('✓ Local database initialized');
  } catch (e) {
    debugPrint('✗ Local database initialization failed: $e');
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'CoinTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _listenToAuth();
  }

  void _listenToAuth() {
    AuthService.appAuthStateChanges().listen((isAuth) {
      if (!mounted) return;
      final current = navigatorKey.currentState;
      if (current == null) return;

      if (isAuth) {
        // Start background sync when authenticated
        SyncService.init();
        current.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else {
        // Stop sync and clear cache on logout
        SyncService.dispose();
        CacheService.clearAll();
        current.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash while auth resolves
    return FutureBuilder<String?>(
      future: TokenService.getJwt(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
              ),
            ),
          );
        }
        // JWT exists → go straight to app
        if (snapshot.data != null && snapshot.data!.isNotEmpty) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}
