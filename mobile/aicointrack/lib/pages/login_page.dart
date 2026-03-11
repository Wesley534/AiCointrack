import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/wallet_auth_service.dart';
import '../services/wallet_connect_service.dart';
import '../firebase_options.dart';
import '../config/theme.dart';
import 'home_page.dart';
import 'email_login_page.dart';

/// Login page with Google Sign-In, Email, and Base Wallet authentication.
///
/// Auth flows available:
///   1. Google Sign-In  (Firebase OAuth)
///   2. Email / Password (Firebase Auth)
///   3. Base Wallet      (Coinbase Wallet SDK → SIWE → backend JWT)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _isWalletLoading = false;
  String? _errorMessage;

  // ─── Google Sign-In ──────────────────────────────────────────────────────

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Guard: check Firebase is configured (catches copy-paste mistakes)
      if (DefaultFirebaseOptions.currentPlatform.apiKey == 'YOUR_API_KEY') {
        setState(() {
          _errorMessage =
              'Firebase not configured. Update firebase_options.dart with your credentials.';
          _isLoading = false;
        });
        return;
      }

      final UserCredential? userCredential =
          await AuthService.signInWithGoogle();

      if (userCredential == null) {
        // User cancelled — not an error
        setState(() {
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getFirebaseErrorMessage(e.code);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unexpected error: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ─── Base Wallet Sign-In ─────────────────────────────────────────────────

  /// Handles "Sign in with Base Wallet" button press.
  ///
  /// Uses the Coinbase Wallet SDK (not WalletConnect) — no project ID needed.
  /// Requires Coinbase Wallet or Base Wallet app to be installed on the device.
  Future<void> _handleBaseWalletSignIn() async {
    // Ensure the SDK was initialised at startup (should already be, but guard)
    if (!WalletConnectService.isInitialized) {
      try {
        await WalletConnectService.init();
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to initialise wallet SDK: $e';
        });
        return;
      }
    }

    setState(() {
      _errorMessage = null;
      _isWalletLoading = true;
    });

    try {
      final walletAuth = WalletAuthService();
      await walletAuth.loginWithWallet();

      // loginWithWallet() has:
      //   1. Connected to Coinbase/Base Wallet app
      //   2. Got address + signed SIWE message
      //   3. Sent to backend → got JWT
      //   4. Optionally signed into Firebase with custom token
      //
      // Either the Firebase stream or the JWT fallback will now emit true,
      // but we navigate explicitly here for speed (no need to wait for stream).
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Clean up the "Exception: " prefix for cleaner UX
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isWalletLoading = false;
        });
      }
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled in Firebase Console.';
      case 'invalid-api-key':
        return 'Invalid API key — check firebase_options.dart.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Authentication failed: $code';
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final borderColor = isDark
        ? AppColors.darkBorder
        : AppColors.lightBorder;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    final bool anyLoading = _isLoading || _isWalletLoading;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo / Brand ──────────────────────────────────────────────
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.accentGreen.withOpacity(0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.currency_bitcoin,
                    color: AppColors.accentGreen,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'CoinTrack',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'AI-powered crypto expense tracker\non Base',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: mutedColor,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // ── Error Banner ──────────────────────────────────────────────
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.danger,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Primary CTA: Base Wallet ──────────────────────────────────
              // Shown first and most prominently — this is the Base-native flow
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: anyLoading ? null : _handleBaseWalletSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        AppColors.accentGreen.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isWalletLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.account_balance_wallet, size: 20),
                  label: Text(
                    _isWalletLoading
                        ? 'Waiting for Base Wallet…'
                        : 'Continue with Base Wallet',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Divider ───────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Divider(color: borderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: TextStyle(color: mutedColor, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: borderColor)),
                ],
              ),

              const SizedBox(height: 16),

              // ── Google Sign-In ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: anyLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: textColor,
                    side: BorderSide(color: borderColor),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: mutedColor,
                          ),
                        )
                      : const Icon(Icons.g_mobiledata, size: 22),
                  label: Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Email ─────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: anyLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const EmailLoginPage(isSignUp: false),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: textColor,
                    side: BorderSide(color: borderColor),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.email_outlined, size: 20),
                  label: Text(
                    'Sign in with email',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Sign Up Link ──────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: anyLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const EmailLoginPage(isSignUp: true),
                            ),
                          );
                        },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: mutedColor, fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: TextStyle(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Base Chain Badge ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.06),
                  border: Border.all(
                    color: AppColors.accentGreen.withOpacity(0.18),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
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
                        'Built on Base · Secured by Firebase · Your keys, your coins',
                        style: TextStyle(fontSize: 11, color: mutedColor),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            ],
          ),
        ),
      ),
    );
  }
}