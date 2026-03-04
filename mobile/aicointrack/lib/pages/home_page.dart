import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../config/theme.dart';
import 'login_page.dart';
import 'dashboard_page.dart';

/// Home page displayed after successful authentication
/// Registers user with backend and redirects to Dashboard
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late User? _user;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _user = AuthService.getCurrentUser();
    _registerUserWithBackend();
  }

  /// Register user with backend using Firebase ID token
  /// On success, automatically navigate to Dashboard
  Future<void> _registerUserWithBackend() async {
    try {
      final token = await AuthService.getIdToken();

      if (token != null) {
        // Call backend to register user
        final backendResponse = await ApiService.registerUserWithBackend();

        if (mounted) {
          // Navigate to Dashboard on success
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => DashboardPage(
                userName: _user?.displayName ?? 'User',
                userEmail: _user?.email ?? '',
                photoUrl: _user?.photoURL,
                userData: backendResponse,
              ),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
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
                    'Welcome to CoinTrack',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                    ),
                  ),
                ],
              )
            else if (_hasError)
              Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 48,
                  ),
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
                      color:
                          isDark ? AppColors.darkMuted : AppColors.lightMuted,
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
