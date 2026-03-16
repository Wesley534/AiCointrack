import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/base_auth_service.dart';
import '../services/reown_auth_service.dart';
import '../firebase_options.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import 'email_login_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
  with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _logTag = '[LoginPage]';

  // ── Loading flags — one per auth method ──────────────────────────────────────
  bool _isBaseLoading = false;
  bool _isGoogleLoading = false;
  bool _isReownLoading = false;
  String? _errorMessage;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  String? _lastBuildState;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('$_logTag initState');

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Init Reown lazily (needs a BuildContext).
    WidgetsBinding.instance.addPostFrameCallback((_) => _initReown());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('$_logTag dispose');
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('$_logTag appLifecycleState=$state mounted=$mounted');
  }

  Future<void> _initReown() async {
    if (!mounted) return;
    debugPrint('$_logTag Reown init start');
    try {
      await ReownAuthService.init(context);
      debugPrint('$_logTag Reown init success');
    } catch (e) {
      debugPrint('$_logTag Reown init error (non-fatal): $e');
    }
  }

  // ── Auth handlers ─────────────────────────────────────────────────────────────

  /// Opens the miniapp /login page via flutter_web_auth_2 → Base smart wallet.
  Future<void> _handleBaseSignIn() async {
    debugPrint('$_logTag Base sign-in tapped');
    setState(() {
      _isBaseLoading = true;
      _errorMessage = null;
    });
    try {
      final success = await BaseAuthService.loginWithBase(context);
      debugPrint('$_logTag Base sign-in completed success=$success');
      if (!success && mounted) {
        // User cancelled — silent dismiss.
        setState(() { _isBaseLoading = false; });
      }
      // On success the StreamBuilder in main.dart detects the auth state
      // change (Firebase + JWT) and swaps LoginPage → HomePage automatically.
    } catch (e) {
      debugPrint('$_logTag Base sign-in error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Base sign-in failed: ${_friendlyError(e)}';
          _isBaseLoading = false;
        });
      }
    }
  }

  /// Google Sign-In via Firebase.
  Future<void> _handleGoogleSignIn() async {
    debugPrint('$_logTag Google sign-in tapped');
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      if (DefaultFirebaseOptions.currentPlatform.apiKey == 'YOUR_API_KEY') {
        setState(() {
          _errorMessage =
              'Firebase not configured. Update firebase_options.dart.';
          _isGoogleLoading = false;
        });
        return;
      }
      final cred = await AuthService.signInWithGoogle();
      debugPrint('$_logTag Google sign-in credential received=${cred != null}');
      if (cred == null && mounted) {
        setState(() { _isGoogleLoading = false; });
        return;
      }
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
        debugPrint('$_logTag Google sign-in navigating to HomePage');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
      // On success the StreamBuilder in main.dart detects the Firebase auth
      // state change and swaps LoginPage → HomePage automatically.
    } on FirebaseAuthException catch (e) {
      debugPrint('$_logTag Google sign-in FirebaseAuthException: ${e.code}');
      if (mounted) {
        setState(() {
          _errorMessage = _getFirebaseError(e.code);
          _isGoogleLoading = false;
        });
      }
    } catch (e) {
      debugPrint('$_logTag Google sign-in error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Google sign-in failed: ${_friendlyError(e)}';
          _isGoogleLoading = false;
        });
      }
    }
  }

  /// Reown AppKit — WalletConnect v2 modal (MetaMask, Rainbow, Trust, etc.).
  Future<void> _handleReownSignIn() async {
    debugPrint('$_logTag Reown sign-in tapped');
    if (AppConstants.REOWN_PROJECT_ID == 'YOUR_REOWN_PROJECT_ID') {
      setState(() {
        _errorMessage =
            'Reown not configured. Set REOWN_PROJECT_ID in constants.dart.';
      });
      return;
    }
    setState(() {
      _isReownLoading = true;
      _errorMessage = null;
    });
    try {
      final success = await ReownAuthService.loginWithWallet(context);
      debugPrint('$_logTag Reown sign-in completed success=$success');
      if (!success && mounted) {
        setState(() {
          _errorMessage = 'Wallet connection cancelled or failed.';
          _isReownLoading = false;
        });
      }
      // On success the StreamBuilder in main.dart detects the auth state
      // change and swaps LoginPage → HomePage automatically.
    } catch (e) {
      debugPrint('$_logTag Reown sign-in error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Wallet sign-in failed: ${_friendlyError(e)}';
          _isReownLoading = false;
        });
      }
    }
  }

  // ── Error helpers ─────────────────────────────────────────────────────────────

  String _getFirebaseError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Account exists with different credentials.';
      case 'invalid-credential':
        return 'Invalid credentials.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Sign-in failed ($code).';
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    // Strip "Exception: " prefix for cleaner display.
    return s.replaceFirst('Exception: ', '');
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final anyLoading = _isBaseLoading || _isGoogleLoading || _isReownLoading;
    final buildState =
        'loading(base=$_isBaseLoading,google=$_isGoogleLoading,reown=$_isReownLoading) '
        'error=${_errorMessage != null}';
    if (_lastBuildState != buildState) {
      _lastBuildState = buildState;
      debugPrint('$_logTag build state -> $buildState');
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 56),

                  // ── Header ──────────────────────────────────────────────────
                  _Header(textColor: textColor, mutedColor: mutedColor),
                  const SizedBox(height: 40),

                  // ── Error banner ────────────────────────────────────────────
                  if (_errorMessage != null) ...[
                    _ErrorBanner(
                      message: _errorMessage!,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Primary: Sign in with Base ──────────────────────────────
                  _PrimaryButton(
                    id: 'btn-sign-in-base',
                    label: 'Sign in with Base',
                    sublabel: 'Passkey · no seed phrase',
                    loading: _isBaseLoading,
                    disabled: anyLoading,
                    icon: Icons.fingerprint_rounded,
                    onPressed: _handleBaseSignIn,
                  ),
                  const SizedBox(height: 12),

                  // ── Google ──────────────────────────────────────────────────
                  _SecondaryButton(
                    id: 'btn-sign-in-google',
                    label: 'Sign in with Google',
                    loading: _isGoogleLoading,
                    disabled: anyLoading,
                    borderColor: borderColor,
                    mutedColor: mutedColor,
                    onPressed: _handleGoogleSignIn,
                    iconWidget: _GoogleIcon(),
                  ),
                  const SizedBox(height: 12),

                  // ── Email ───────────────────────────────────────────────────
                  _SecondaryButton(
                    id: 'btn-sign-in-email',
                    label: 'Sign in with Email',
                    loading: false,
                    disabled: anyLoading,
                    borderColor: borderColor,
                    mutedColor: mutedColor,
                    icon: Icons.email_outlined,
                    onPressed: () {
                      debugPrint('$_logTag Navigating to EmailLoginPage');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EmailLoginPage(isSignUp: false),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── Divider ─────────────────────────────────────────────────
                  _Divider(
                    color: borderColor,
                    mutedColor: mutedColor,
                    label: 'or connect existing wallet',
                  ),
                  const SizedBox(height: 20),

                  // ── Reown: other wallets ────────────────────────────────────
                  _SecondaryButton(
                    id: 'btn-connect-other-wallet',
                    label: 'Connect other wallet',
                    sublabel: 'MetaMask, Rainbow, Trust & 400+ wallets',
                    loading: _isReownLoading,
                    disabled: anyLoading,
                    borderColor: AppColors.accentGreen.withValues(alpha: 0.4),
                    mutedColor: mutedColor,
                    accentColor: AppColors.accentGreen,
                    icon: Icons.link_rounded,
                    onPressed: _handleReownSignIn,
                  ),

                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'By signing in you agree to our Terms of Service.',
                      style: TextStyle(fontSize: 11, color: mutedColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header widget ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.textColor, required this.mutedColor});
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A3A6B), Color(0xFF0052FF)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x400052FF),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text('💰', style: TextStyle(fontSize: 34)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'AiCoinTrack',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your all-in-one crypto & expense tracker',
          style: TextStyle(fontSize: 14, color: mutedColor, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

// ── Primary "Sign in with Base" button ───────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.id,
    required this.label,
    required this.sublabel,
    required this.loading,
    required this.disabled,
    required this.icon,
    required this.onPressed,
  });

  final String id;
  final String label;
  final String sublabel;
  final bool loading;
  final bool disabled;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        key: Key(id),
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0052FF),
          disabledBackgroundColor: const Color(
            0xFF0052FF,
          ).withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: Colors.white),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        sublabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Secondary outlined button ─────────────────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.id,
    required this.label,
    required this.loading,
    required this.disabled,
    required this.borderColor,
    required this.mutedColor,
    required this.onPressed,
    this.sublabel,
    this.icon,
    this.iconWidget,
    this.accentColor,
  });

  final String id;
  final String label;
  final String? sublabel;
  final bool loading;
  final bool disabled;
  final Color borderColor;
  final Color mutedColor;
  final Color? accentColor;
  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = accentColor ?? mutedColor;
    return SizedBox(
      width: double.infinity,
      height: sublabel != null ? 62 : 52,
      child: OutlinedButton(
        key: Key(id),
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: foreground,
          side: BorderSide(
            color: disabled ? borderColor.withValues(alpha: 0.4) : borderColor,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foreground),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (iconWidget != null) ...[
                        iconWidget!,
                        const SizedBox(width: 8),
                      ] else if (icon != null) ...[
                        Icon(icon, size: 18, color: foreground),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
                  if (sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sublabel!,
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ── Divider with label ────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider({
    required this.color,
    required this.mutedColor,
    required this.label,
  });

  final Color color;
  final Color mutedColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: TextStyle(fontSize: 11, color: mutedColor)),
        ),
        Expanded(child: Divider(color: color, thickness: 1)),
      ],
    );
  }
}

// ── Google coloured "G" icon ──────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4285F4),
        height: 1,
      ),
    );
  }
}
