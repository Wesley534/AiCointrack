import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../config/theme.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'wallet_options_page.dart';

/// Home page displayed after successful authentication
/// Registers user with backend and redirects to Dashboard
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _logTag = '[HomePage]';

  late User? _user;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _user = AuthService.getCurrentUser();
    debugPrint('$_logTag initState firebaseUser=${_user?.uid}');
    _registerUserWithBackend();
  }

  /// Register or fetch user: Firebase path or JWT path (wallet-only).
  Future<void> _registerUserWithBackend() async {
    try {
      debugPrint('$_logTag register start');
      final firebaseToken = await AuthService.getIdToken();
      final jwt = await TokenService.getJwt();
      debugPrint(
        '$_logTag token availability firebaseToken=${firebaseToken != null} jwt=${jwt != null && jwt.isNotEmpty}',
      );

      Map<String, dynamic> backendResponse;
      if (firebaseToken != null) {
        debugPrint('$_logTag calling registerUserWithBackend()');
        backendResponse = await ApiService.registerUserWithBackend();
      } else if (jwt != null && jwt.isNotEmpty) {
        debugPrint('$_logTag calling fetchUserProfile()');
        backendResponse = await ApiService.fetchUserProfile();
      } else {
        debugPrint('$_logTag no token available -> aborting register flow');
        return;
      }

      if (mounted) {
        final userData = backendResponse['user'] ?? backendResponse;
        final normalizedUserData = userData is Map<String, dynamic>
            ? userData
            : userData is Map
            ? Map<String, dynamic>.from(userData)
            : null;
        final hasWallet =
            userData is Map &&
            userData['wallet_address'] != null &&
            (userData['wallet_address'] as String).isNotEmpty;
        debugPrint('$_logTag backend success hasWallet=$hasWallet');

        final displayName =
            _user?.displayName ??
            (userData is Map ? userData['name'] as String? : null) ??
            'User';
        final email =
            _user?.email ??
            (userData is Map ? userData['email'] as String? : null) ??
            '';

        if (!hasWallet) {
          debugPrint('$_logTag navigating to WalletOptionsPage');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => WalletOptionsPage(
                userName: displayName,
                userEmail: email,
                photoUrl: _user?.photoURL,
                userData: normalizedUserData,
              ),
            ),
            (route) => false,
          );
        } else {
          debugPrint('$_logTag navigating to DashboardPage');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => DashboardPage(
                userName: displayName,
                userEmail: email,
                photoUrl: _user?.photoURL,
                userData: normalizedUserData,
              ),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('$_logTag register error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Retry backend registration
  Future<void> _retryRegistration() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    await _registerUserWithBackend();
  }

  /// Handle user sign-out
  Future<void> _handleSignOut() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Setting up your dashboard...',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome to AiCoinTrack',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkMuted
                          : AppColors.lightMuted,
                    ),
                  ),
                ],
              )
            else if (_hasError)
              Column(
                children: [
                  Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Registration Failed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to connect to backend',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkMuted
                          : AppColors.lightMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _retryRegistration,
                        child: const Text('Retry'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _handleSignOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
