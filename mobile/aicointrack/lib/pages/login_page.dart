import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/wallet_auth_service.dart';
import '../services/wallet_connect_service.dart';
import '../firebase_options.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import 'home_page.dart';
import 'email_login_page.dart';

/// Login page with Google Sign-In authentication
/// Handles user authentication flow and navigation to home page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _isWalletLoading = false;
  String? _errorMessage;

  /// Handle Google Sign-In button press
  Future<void> _handleGoogleSignIn() async {
    // Clear previous error messages
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Check if Firebase is configured
      if (DefaultFirebaseOptions.currentPlatform.apiKey == 'YOUR_API_KEY') {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Firebase not configured yet. Please update firebase_options.dart with your Firebase credentials. See SETUP_CHECKLIST.md for details.';
            _isLoading = false;
          });
        }
        return;
      }

      // Attempt to sign in with Google
      final UserCredential? userCredential =
          await AuthService.signInWithGoogle();

      if (userCredential == null) {
        // User canceled the sign-in
        if (mounted) {
          setState(() {
            _errorMessage = 'Sign-in cancelled by user';
            _isLoading = false;
          });
        }
        return;
      }

      // Sign-in successful, navigate to home page
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication errors
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.code);
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle other unexpected errors
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Handle Base Wallet sign-in via WalletConnect
  Future<void> _handleBaseWalletSignIn() async {
    if (AppConstants.WALLETCONNECT_PROJECT_ID ==
        'YOUR_WALLETCONNECT_PROJECT_ID') {
      if (mounted) {
        setState(() {
          _errorMessage =
              'WalletConnect not configured. Add WALLETCONNECT_PROJECT_ID in constants.dart. '
              'Get a free project ID at cloud.walletconnect.com';
        });
      }
      return;
    }

    setState(() {
      _errorMessage = null;
      _isWalletLoading = true;
    });

    try {
      final walletAuth = WalletAuthService();
      await walletAuth.loginWithWallet();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isWalletLoading = false;
        });
      }
    }
  }

  /// Map Firebase error codes to user-friendly messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled in Firebase Console';
      case 'invalid-api-key':
        return 'Invalid API key. Check firebase_options.dart';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      case 'user-disabled':
        return 'This user account has been disabled';
      default:
        return 'Authentication failed: $errorCode';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    // Check if user is already signed in
    if (AuthService.isUserSignedIn()) {
      // Redirect to home page if already logged in
      Future.microtask(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      });
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Add spacing from top
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),

              // App Logo or Title
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGreen, AppColors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text('💰', style: TextStyle(fontSize: 40)),
                ),
              ),

              const SizedBox(height: 24),

              // App Title
              Text(
                'CoinTrack',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Your AI-powered money companion\n— tracks every shilling, automatically.',
                style: TextStyle(fontSize: 14, color: mutedColor, height: 1.5),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Error Message Display
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    border: Border.all(color: AppColors.danger),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    disabledBackgroundColor: AppColors.accentGreen.withOpacity(
                      0.5,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // Sign in with Google (explicit)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: mutedColor,
                    side: BorderSide(color: borderColor),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Sign in with Google',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Email/password
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EmailLoginPage(isSignUp: false),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: mutedColor,
                    side: BorderSide(color: borderColor),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Sign in with email',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Sign in with Base Wallet (WalletConnect)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: (_isLoading || _isWalletLoading)
                      ? null
                      : _handleBaseWalletSignIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: mutedColor,
                    side: BorderSide(color: borderColor),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isWalletLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.account_balance_wallet, size: 20),
                  label: Text(
                    _isWalletLoading
                        ? 'Waiting for Base app...'
                        : 'Sign in with Base Wallet',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Base Chain Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.08),
                  border: Border.all(
                    color: AppColors.accentGreen.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Powered by Firebase — your data is secure',
                        style: TextStyle(fontSize: 11, color: mutedColor),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom spacing
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
