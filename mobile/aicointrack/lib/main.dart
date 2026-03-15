import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/notification_permission_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_transaction_service.dart';
import 'services/pending_transactions_service.dart';
import 'services/token_service.dart';
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
  static const _permShownKey = 'notif_perm_shown';
  final Set<int> _seenHashes = <int>{};

  @override
  void initState() {
    super.initState();
    _listenToAuth();
    _initNotificationListener();
    PendingTxService.syncOnStartup();
  }

  void _listenToAuth() {
    AuthService.appAuthStateChanges().listen((isAuth) async {
      if (!mounted) return;
      final current = navigatorKey.currentState;
      if (current == null) return;

      if (isAuth) {
        current.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
        await _maybeShowPermissionScreen();
      } else {
        current.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    });
  }

  Future<void> _maybeShowPermissionScreen() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final granted = await NotificationTransactionService.isAccessGranted();
    if (granted) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(_permShownKey) ?? false;

    if (!alreadyShown || !granted) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      prefs.setBool(_permShownKey, true);
      // ignore: use_build_context_synchronously
      await NotificationPermissionScreen.show(ctx);
    }
  }

  Future<void> _initNotificationListener() async {
    NotificationTransactionService.init(
      onTransaction: (tx) async {
        if (_seenHashes.contains(tx.hash)) return;
        _seenHashes.add(tx.hash);

        await PendingTxService.add(
          PendingTx(
            id: '${tx.hash}_${DateTime.now().millisecondsSinceEpoch}',
            amount: tx.amount,
            type: tx.type,
            description: tx.description,
            source: tx.source,
            category: tx.type == 'income' ? 'Income' : 'General',
            detectedAt: DateTime.now(),
            rawText: tx.rawText,
          ),
        );

        await _refreshPendingCount();
      },
    );
  }

  Future<void> _refreshPendingCount() async {
    pendingCountNotifier.value = await PendingTxService.count();
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
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.accentGreen,
                ),
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
