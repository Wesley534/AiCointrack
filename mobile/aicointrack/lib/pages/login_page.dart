import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../firebase_options.dart';
import 'home_page.dart';

/// Login page with Google Sign-In authentication
/// Handles user authentication flow and navigation to home page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
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
            _errorMessage = 'Firebase not configured yet. Please update firebase_options.dart with your Firebase credentials. See SETUP_CHECKLIST.md for details.';
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
                    colors: [Color(0xFF00E5A0), Color(0xFF7C6AFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '💰',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App Title
              const Text(
                'CoinTrack',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE8EDF5),
                  fontFamily: 'Inter',
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Your AI-powered money companion\n— tracks every shilling, automatically.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7A90),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Error Message Display
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
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
                    backgroundColor: const Color(0xFF00E5A0),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    disabledBackgroundColor: const Color(0xFF00E5A0).withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // Alternative sign-in button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: const Color(0xFF6B7A90),
                    side: const BorderSide(color: Color(0xFF1E2A3A)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Base Chain Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5A0).withOpacity(0.08),
                  border: Border.all(
                    color: const Color(0xFF00E5A0).withOpacity(0.2),
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
                        color: Color(0xFF00E5A0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Powered by Firebase — your data is secure',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7A90),
                        ),
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
