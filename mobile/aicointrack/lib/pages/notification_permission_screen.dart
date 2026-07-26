import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/notification_transaction_service.dart';
import '../services/pending_transactions_service.dart';

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
  bool _isScanning = false;
  bool _scanDone = false;
  int _scanCount = 0;
  int _selectedDuration = 30; // default: last 30 days

  Future<void> _openAndWait() async {
    await NotificationTransactionService.openSettings();
    if (!mounted) return;
    setState(() => _checking = true);

    for (int i = 0; i < 60; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      final granted = await NotificationTransactionService.isAccessGranted();
      if (granted) {
        try {
          final testResult = await NotificationTransactionService.testService();
          debugPrint(
            '[NotificationPermission] Service test result: $testResult',
          );
        } catch (e) {
          debugPrint('[NotificationPermission] Service test failed: $e');
        }
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
    }

    if (mounted) setState(() => _checking = false);
  }

  Future<void> _scanHistorical() async {
    // Check SMS permission first
    final hasSms = await NotificationTransactionService.hasSmsPermission();
    if (!hasSms && mounted) {
      final grant = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('SMS Permission'),
          content: const Text(
            'CoinTrack needs SMS permission to read past M-Pesa and bank messages. '
            'Would you like to grant it now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Grant'),
            ),
          ],
        ),
      );

      if (grant == true && mounted) {
        await NotificationTransactionService.requestSmsPermission();
        // Wait a moment for user to grant
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) return;
      final stillHas = await NotificationTransactionService.hasSmsPermission();
      if (!stillHas && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS permission is required to scan past messages.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    setState(() {
      _isScanning = true;
      _scanDone = false;
      _scanCount = 0;
    });

    try {
      final transactions = await NotificationTransactionService
          .scanHistoricalMessages(durationDays: _selectedDuration);

      if (!mounted) return;

      // Add each found transaction as a pending transaction
      for (final tx in transactions) {
        await PendingTxService.add(
          PendingTx(
            id: '${tx.hash}_${DateTime.now().millisecondsSinceEpoch}',
            amount: tx.amount,
            type: tx.type,
            description: tx.description,
            source: tx.source,
            category: tx.type == 'income' ? 'Income' : 'General',
            detectedAt: DateTime.now(),
            rawText: tx.rawText,
            transactionCode: tx.transactionCode,
          ),
        );
      }

      if (!mounted) return;
      pendingCountNotifier.value = await PendingTxService.count();

      setState(() {
        _isScanning = false;
        _scanDone = true;
        _scanCount = transactions.length;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scanned ${transactions.length} historical transaction${transactions.length == 1 ? '' : 's'} — review them in Pending',
          ),
          backgroundColor: AppColors.accent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanDone = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
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
                  color: AppColors.accent.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.accent,
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
                'CoinTrack can read your M-Pesa and bank notifications and SMS messages to detect transactions — nothing is logged without your approval.',
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
                icon: Icons.history_outlined,
                label: 'Scan past SMS messages and auto-log',
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
              ),
              const SizedBox(height: 20),

              // ── Historical Scan Section ────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            size: 20,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan past messages',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Read historical SMS from M-Pesa, KCB, Equity, NCBA and queue them for review.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DurationDropdown(
                            value: _selectedDuration,
                            onChanged: (v) {
                              if (v != null && mounted) {
                                setState(() => _selectedDuration = v);
                              }
                            },
                            mutedColor: mutedColor,
                            borderColor: borderColor,
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isScanning ? null : _scanHistorical,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.accent.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                            ),
                            child: _isScanning
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Scan'),
                          ),
                        ),
                      ],
                    ),
                    if (_scanDone) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _scanCount > 0
                              ? AppColors.accent.withValues(alpha: 0.08)
                              : AppColors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _scanCount > 0
                                ? AppColors.accent.withValues(alpha: 0.2)
                                : AppColors.warning.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _scanCount > 0
                                  ? Icons.check_circle_outline
                                  : Icons.info_outline,
                              size: 16,
                              color: _scanCount > 0
                                  ? AppColors.accent
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _scanCount > 0
                                    ? 'Found $_scanCount transaction${_scanCount == 1 ? '' : 's'}. Review them in Pending.'
                                    : 'No financial transactions found in the selected period.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _scanCount > 0
                                      ? AppColors.accent
                                      : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  'Recommended Android setup:\n'
                  '1. Settings -> Notification Access -> AiCoinTrack -> Allowed\n'
                  '2. Settings -> Apps -> AiCoinTrack -> Battery -> Unrestricted\n'
                  '3. Enable SMS permission for scanning past messages',
                  style: TextStyle(
                    fontSize: 13,
                    color: mutedColor,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_checking) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.accent),
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
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.accent.withValues(
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

/// Duration picker dropdown for historical scan.
class _DurationDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int?> onChanged;
  final Color mutedColor;
  final Color borderColor;
  final Color cardColor;
  final Color textColor;

  const _DurationDropdown({
    required this.value,
    required this.onChanged,
    required this.mutedColor,
    required this.borderColor,
    required this.cardColor,
    required this.textColor,
  });

  static const _options = <int, String>{
    1: 'Last 1 day',
    7: 'Last 7 days',
    14: 'Last 2 weeks',
    30: 'Last 1 month',
    90: 'Last 3 months',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        color: Colors.transparent,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          dropdownColor: cardColor,
          style: TextStyle(color: textColor, fontSize: 13),
          isExpanded: true,
          items: _options.entries
              .map((e) => DropdownMenuItem<int>(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: onChanged,
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
          child: Icon(icon, size: 18, color: AppColors.accent),
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
