import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  // ── Environment Configuration ────────────────────────────────────────────────
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✓ Environment variables loaded from .env');
  } catch (e) {
    debugPrint('✗ Environment loading failed (non-fatal): $e');
  }

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

class _NavLogObserver extends NavigatorObserver {
  void _log(String action, Route<dynamic>? route, Route<dynamic>? previousRoute) {
    final toName = route?.settings.name ?? route?.runtimeType.toString() ?? 'null';
    final fromName =
        previousRoute?.settings.name ??
        previousRoute?.runtimeType.toString() ??
        'null';
    debugPrint('[Nav] $action to=$toName from=$fromName');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('didPush', route, previousRoute);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('didPop', route, previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log('didReplace', newRoute, oldRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('didRemove', route, previousRoute);
    super.didRemove(route, previousRoute);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [_NavLogObserver()],
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
  StreamSubscription<bool>? _authSub;
  bool? _isAuthenticated;
  String? _lastRenderedState;

  @override
  void initState() {
    super.initState();
    debugPrint('[AuthGate] initState');
    unawaited(_initAuthGate());
    _initNotificationListener();
    PendingTxService.syncOnStartup();
  }

  Future<void> _initAuthGate() async {
    final jwt = await TokenService.getJwt();
    final hasJwt = jwt != null && jwt.isNotEmpty;
    final hasFirebaseUser = AuthService.isUserSignedIn();
    final initialAuth = hasJwt || hasFirebaseUser;

    debugPrint(
      '[AuthGate] Initial auth resolved hasJwt=$hasJwt hasFirebaseUser=$hasFirebaseUser -> isAuth=$initialAuth',
    );

    if (mounted) {
      setState(() {
        _isAuthenticated = initialAuth;
      });
    }

    if (initialAuth) {
      unawaited(_maybeShowPermissionScreen());
    }

    debugPrint('[AuthGate] Subscribing to appAuthStateChanges');
    _authSub = AuthService.appAuthStateChanges().listen((isAuth) async {
      debugPrint('[AuthGate] appAuthStateChanges emitted isAuth=$isAuth');
      if (!mounted) return;

      final previous = _isAuthenticated;
      if (previous != isAuth) {
        debugPrint('[AuthGate] UI auth state transition $previous -> $isAuth');
      }

      setState(() {
        _isAuthenticated = isAuth;
      });

      if (isAuth) {
        await _maybeShowPermissionScreen();
      }
    }, onError: (Object e, StackTrace st) {
      debugPrint('[AuthGate] appAuthStateChanges error: $e');
    }, onDone: () {
      debugPrint('[AuthGate] appAuthStateChanges stream done');
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _maybeShowPermissionScreen() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final granted = await NotificationTransactionService.isAccessGranted();
    debugPrint('[AuthGate] Notification permission granted=$granted');
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
    if (_isAuthenticated == null) {
      if (_lastRenderedState != 'splash') {
        _lastRenderedState = 'splash';
        debugPrint('[AuthGate] Rendering splash (auth unresolved)');
      }
      return Scaffold(
        backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.accent,
            ),
          ),
        ),
      );
    }

    if (_isAuthenticated == true) {
      if (_lastRenderedState != 'home') {
        _lastRenderedState = 'home';
        debugPrint('[AuthGate] Rendering HomePage');
      }
      return const HomePage();
    }

    if (_lastRenderedState != 'login') {
      _lastRenderedState = 'login';
      debugPrint('[AuthGate] Rendering LoginPage');
    }
    return const LoginPage();
  }
}
