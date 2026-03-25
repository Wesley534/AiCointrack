import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import 'dashboard_page.dart';

/// Shown after registration when user has no wallet.
/// Options: Connect existing Base wallet, Create one (Privy), Skip.
class WalletOptionsPage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? photoUrl;
  final Map<String, dynamic>? userData;

  const WalletOptionsPage({
    super.key,
    required this.userName,
    required this.userEmail,
    this.photoUrl,
    this.userData,
  });

  @override
  State<WalletOptionsPage> createState() => _WalletOptionsPageState();
}

class _WalletOptionsPageState extends State<WalletOptionsPage> {
  bool _isCreatingWallet = false;

  void goToDashboard([Map<String, dynamic>? updatedUserData]) {
    final userData = updatedUserData ?? widget.userData;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => DashboardPage(
          userName: widget.userName,
          userEmail: widget.userEmail,
          photoUrl: widget.photoUrl,
          userData: userData,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _createPrivyWallet() async {
    if (_isCreatingWallet) return;
    setState(() => _isCreatingWallet = true);
    try {
      final result = await ApiService.createWallet();
      final user = result['user'] as Map<String, dynamic>?;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Wallet created! You can export it later in Settings.',
            ),
            backgroundColor: AppColors.accent,
          ),
        );
        goToDashboard(user);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingWallet = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'Link your wallet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect a Base wallet to send and receive USDC. You can do this later in Settings.',
                style: TextStyle(fontSize: 14, color: mutedColor, height: 1.5),
              ),
              const SizedBox(height: 40),

              // Connect existing
              _OptionCard(
                icon: Icons.link,
                title: 'Connect existing Base wallet',
                subtitle: 'Use a wallet you already have',
                borderColor: borderColor,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Connect wallet'),
                      content: const Text(
                        'WalletConnect integration coming soon. '
                        'For now, open CoinTrack via the Base/Coinbase Wallet browser to ensure the window.base provider is injected.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Create one (Privy)
              _OptionCard(
                icon: Icons.add_circle_outline,
                title: 'Create one for me',
                subtitle:
                    'We\'ll set up a Base wallet (exportable to Base app)',
                borderColor: borderColor,
                onTap: _isCreatingWallet ? null : _createPrivyWallet,
                trailing: _isCreatingWallet
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              const SizedBox(height: 24),

              // Skip
              TextButton(
                onPressed: goToDashboard,
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: mutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: goToDashboard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continue to app',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color borderColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkMuted
                            : AppColors.lightMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
