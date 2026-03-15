import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/notification_transaction_service.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const NotificationPermissionScreen(),
        fullscreenDialog: true,
      ),
    );
    return result ?? false;
  }

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  bool _checking = false;

  Future<void> _openAndWait() async {
    await NotificationTransactionService.openSettings();
    if (!mounted) return;
    setState(() => _checking = true);

    for (int i = 0; i < 60; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      final granted = await NotificationTransactionService.isAccessGranted();
      if (granted) {
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
    }

    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.accentGreen.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.accentGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.accentGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Auto-detect transactions',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'CoinTrack can silently read your M-Pesa and bank notifications, parse the amounts, and queue them for your review — nothing is logged without your approval.',
                style: TextStyle(fontSize: 15, color: mutedColor, height: 1.6),
              ),
              const SizedBox(height: 32),
              _FeatureBullet(
                icon: Icons.search_outlined,
                label: 'Detects M-Pesa, KCB, Equity, NCBA',
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
              ),
              const SizedBox(height: 12),
              _FeatureBullet(
                icon: Icons.queue_outlined,
                label: 'Queues transactions for your review',
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
              ),
              const SizedBox(height: 12),
              _FeatureBullet(
                icon: Icons.lock_outline,
                label: 'All processing stays on-device',
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
              ),
              const SizedBox(height: 12),
              _FeatureBullet(
                icon: Icons.do_not_disturb_on_outlined,
                label: 'Never logs without your approval',
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
              ),
              const Spacer(),
              if (_checking) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accentGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.accentGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Waiting for you to enable access…',
                        style: TextStyle(fontSize: 13, color: mutedColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _checking ? null : _openAndWait,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppColors.accentGreen.withValues(
                      alpha: 0.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _checking
                        ? 'Waiting for permission…'
                        : 'Enable notification access',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _checking
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: mutedColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Skip for now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;

  const _FeatureBullet({
    required this.icon,
    required this.label,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, size: 18, color: AppColors.accentGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
