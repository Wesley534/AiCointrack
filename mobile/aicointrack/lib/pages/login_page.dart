import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../firebase_options.dart';
import '../services/auth_service.dart';
import '../services/base_auth_service.dart';
import '../services/local_auth_lock_service.dart';
import '../services/reown_auth_service.dart';
import '../widgets/design_system.dart';
import 'email_login_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  bool _isBaseLoading = false;
  bool _isGoogleLoading = false;
  bool _isReownLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initReown());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initReown() async {
    if (!mounted) return;
    try {
      await ReownAuthService.init(context);
    } catch (_) {}
  }

  Future<void> _handleBaseSignIn() async {
    setState(() {
      _isBaseLoading = true;
      _errorMessage = null;
    });
    try {
      final success = await BaseAuthService.loginWithBase(context);
      if (!success && mounted) {
        setState(() => _isBaseLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Base sign-in failed: ${_friendlyError(e)}';
        _isBaseLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      if (DefaultFirebaseOptions.currentPlatform.apiKey == 'YOUR_API_KEY') {
        setState(() {
          _errorMessage =
              'Firebase is not configured yet. Update firebase options first.';
          _isGoogleLoading = false;
        });
        return;
      }

      final cred = await AuthService.signInWithGoogle();
      if (cred == null && mounted) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      await LocalAuthLockService.requestPinSetupPrompt();

      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomePage(promptForPinSetup: true),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _getFirebaseError(e.code);
        _isGoogleLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Google sign-in failed: ${_friendlyError(e)}';
        _isGoogleLoading = false;
      });
    }
  }

  Future<void> _handleReownSignIn() async {
    if (AppConstants.REOWN_PROJECT_ID == 'YOUR_REOWN_PROJECT_ID') {
      setState(() {
        _errorMessage =
            'Reown is not configured. Add a project id in constants.dart.';
      });
      return;
    }

    setState(() {
      _isReownLoading = true;
      _errorMessage = null;
    });
    try {
      final success = await ReownAuthService.loginWithWallet(context);
      if (success) {
        await LocalAuthLockService.requestPinSetupPrompt();
        if (!mounted) return;
        setState(() => _isReownLoading = false);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomePage(promptForPinSetup: true),
          ),
          (route) => false,
        );
        return;
      }

      if (!success && mounted) {
        setState(() {
          _errorMessage = 'Wallet connection cancelled or failed.';
          _isReownLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Wallet sign-in failed: ${_friendlyError(e)}';
        _isReownLoading = false;
      });
    }
  }

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

  String _friendlyError(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    final anyLoading = _isBaseLoading || _isGoogleLoading || _isReownLoading;

    return Scaffold(
      body: Container(
        decoration: AppDecorations.pageBackground(context),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'AiCoinTrack',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                AppPill(
                  label: 'Secured by Stellar Network',
                  color: AppColors.positive,
                ),
                const SizedBox(height: 18),
                Text(
                  'Institutional power.\nPersonal precision.',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Track fiat and crypto in one clean workspace with smart transaction detection and wallet-first access.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Expanded(
                      child: _TrustTile(
                        icon: Icons.security_rounded,
                        title: 'MPC Security',
                        subtitle: 'Wallet-first protection',
                        tint: AppColors.accent,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _TrustTile(
                        icon: Icons.bolt_rounded,
                        title: 'Real-time Data',
                        subtitle: 'Fast portfolio updates',
                        tint: AppColors.positive,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                AppGlassCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to manage your portfolio and smart ledger.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBanner(
                          message: _errorMessage!,
                          onDismiss: () => setState(() => _errorMessage = null),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _PrimaryAuthButton(
                        label: 'Sign in with Base Wallet',
                        subtitle: 'Passkey, no seed phrase',
                        icon: Icons.wallet_rounded,
                        loading: _isBaseLoading,
                        enabled: !anyLoading,
                        onPressed: _handleBaseSignIn,
                      ),
                      const SizedBox(height: 12),
                      _SecondaryAuthButton(
                        label: 'Connect with Reown',
                        subtitle: 'MetaMask, Rainbow, Trust and more',
                        icon: Icons.hub_rounded,
                        accent: AppColors.accent,
                        loading: _isReownLoading,
                        enabled: !anyLoading,
                        onPressed: _handleReownSignIn,
                      ),
                      const SizedBox(height: 18),
                      _InlineDivider(label: 'or continue with email'),
                      const SizedBox(height: 18),
                      _SecondaryAuthButton(
                        label: 'Continue with Google',
                        icon: Icons.g_mobiledata_rounded,
                        loading: _isGoogleLoading,
                        enabled: !anyLoading,
                        onPressed: _handleGoogleSignIn,
                      ),
                      const SizedBox(height: 12),
                      _SecondaryAuthButton(
                        label: 'Sign in with Email',
                        icon: Icons.email_outlined,
                        loading: false,
                        enabled: !anyLoading,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const EmailLoginPage(isSignUp: false),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'By signing in you agree to our Terms of Service.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustTile extends StatelessWidget {
  const _TrustTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBadge(
            icon: icon,
            background: tint.withValues(alpha: 0.12),
            foreground: tint,
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
      ),
    );
  }
}

class _SecondaryAuthButton extends StatelessWidget {
  const _SecondaryAuthButton({
    required this.label,
    this.subtitle,
    required this.icon,
    this.accent,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color? accent;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = accent ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                children: [
                  Icon(icon, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InlineDivider extends StatelessWidget {
  const _InlineDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Divider(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.redBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.danger,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
