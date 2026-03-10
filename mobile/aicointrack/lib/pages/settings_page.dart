import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Settings page with real user profile data and working controls.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  String _userName = '';
  String _email = '';
  String _walletLabel = '';
  bool _mpesaAutoLog = true;
  bool _bankAutoLog = true;
  bool _onchainAutoLog = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.fetchUserProfile();
      if (mounted) {
        setState(() {
          _userName = profile['display_name'] as String? ??
              profile['username'] as String? ??
              'User';
          _email = profile['email'] as String? ?? '';
          final addr = profile['wallet_address'] as String? ?? '';
          _walletLabel = addr.isNotEmpty
              ? '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}'
              : 'No wallet';
          // Load preferences if available
          final prefs = profile['preferences'] as Map<String, dynamic>?;
          if (prefs != null) {
            _mpesaAutoLog = prefs['mpesa_auto_log'] as bool? ?? true;
            _bankAutoLog = prefs['bank_auto_log'] as bool? ?? true;
            _onchainAutoLog = prefs['onchain_auto_log'] as bool? ?? true;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'User';
          _email = '';
          _walletLabel = 'No wallet';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await AuthService.signOut();
      // The auth gate listener in main.dart will handle navigation
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: mutedColor,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Profile card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [AppColors.accentGreen, AppColors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        if (_email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _email,
                            style: TextStyle(fontSize: 12, color: mutedColor),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.accentGreen.withOpacity(0.08),
                            border: Border.all(
                              color: AppColors.accentGreen.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.accentGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _walletLabel,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Auto-Logging Preferences
            Text(
              'Auto-Logging Preferences'.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 8),
            _ToggleRow(
              label: 'M-Pesa auto-log',
              value: _mpesaAutoLog,
              onChanged: (v) => setState(() => _mpesaAutoLog = v),
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
            ),
            _ToggleRow(
              label: 'Bank auto-log',
              value: _bankAutoLog,
              onChanged: (v) => setState(() => _bankAutoLog = v),
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
            ),
            _ToggleRow(
              label: 'On-chain auto-log',
              value: _onchainAutoLog,
              onChanged: (v) => setState(() => _onchainAutoLog = v),
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoggingOut ? null : _logout,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
                  foregroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoggingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: textColor),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: _ToggleSwitch(value: value),
          ),
        ],
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  final bool value;

  const _ToggleSwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackOff = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final thumbOff = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 42,
      height: 22,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: value ? AppColors.accentGreen : trackOff,
      ),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? Colors.black : thumbOff,
          ),
        ),
      ),
    );
  }
}

