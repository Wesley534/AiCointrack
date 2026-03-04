import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'dashboard_page.dart';

/// Shown after registration when user has no wallet.
/// Options: Connect existing Base wallet, Create one, Skip.
class WalletOptionsPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    void goToDashboard() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            userName: userName,
            userEmail: userEmail,
            photoUrl: photoUrl,
            userData: userData,
          ),
        ),
        (route) => false,
      );
    }

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
                        'For now, open CoinTrack in the Base app to use your wallet.',
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

              // Create one
              _OptionCard(
                icon: Icons.add_circle_outline,
                title: 'Create one for me',
                subtitle: 'We\'ll set up a wallet for you',
                borderColor: borderColor,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Smart wallet creation coming soon. Use Base miniapp for now.',
                      ),
                    ),
                  );
                },
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
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continue to app',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.onTap,
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
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
