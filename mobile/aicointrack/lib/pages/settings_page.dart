import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/local_auth_lock_service.dart';
import '../services/sync_service.dart';
import '../widgets/design_system.dart';
import 'login_page.dart';
import 'pin_setup_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  bool _securityBusy = false;
  String? _error;
  Map<String, dynamic> _data = {};
  late List<bool> _toggleValues;
  SecuritySettingsState? _securityState;

  @override
  void initState() {
    super.initState();
    _toggleValues = ApiService.exampleSettings.toggles
        .map((toggle) => toggle.enabled)
        .toList();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final result = await ApiService.fetchUserProfile();
      final securityState = await LocalAuthLockService.getSecurityState();
      if (!mounted) return;
      setState(() {
        _data = result;
        _securityState = securityState;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSecurityState() async {
    final securityState = await LocalAuthLockService.getSecurityState();
    if (!mounted) return;
    setState(() {
      _securityState = securityState;
    });
  }

  Future<void> _openPinSetup({required bool isUpdate}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PinSetupPage(canSkip: false, isUpdate: isUpdate),
      ),
    );
    await _refreshSecurityState();
  }

  Future<void> _toggleAppLock(bool value) async {
    if (_securityState == null || !_securityState!.hasPin) {
      await _openPinSetup(isUpdate: false);
      return;
    }

    setState(() => _securityBusy = true);
    await LocalAuthLockService.setAppLockEnabled(value);
    await _refreshSecurityState();
    if (!mounted) return;
    setState(() => _securityBusy = false);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_securityState == null || !_securityState!.hasPin) {
      await _openPinSetup(isUpdate: false);
      return;
    }

    setState(() => _securityBusy = true);
    await LocalAuthLockService.setBiometricEnabled(value);
    await _refreshSecurityState();
    if (!mounted) return;
    setState(() => _securityBusy = false);
  }

  Future<void> _syncNow() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await SyncService.instance.syncAll(trigger: 'settings_manual');
    if (!mounted) return;
    messenger?.showSnackBar(
      const SnackBar(content: Text('Local cache refreshed')),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    try {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Account & app setup')),
      body: AppPage(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _loadData)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHero(mutedColor),
                  const SizedBox(height: 18),
                  if (_securityState?.hasPin != true)
                    _buildPinPromptCard(mutedColor),
                  if (_securityState?.hasPin != true)
                    const SizedBox(height: 18),
                  _buildSecuritySection(mutedColor),
                  const SizedBox(height: 18),
                  _buildExperienceSection(context, mutedColor),
                  const SizedBox(height: 18),
                  _buildAutoLoggingSection(mutedColor),
                  const SizedBox(height: 18),
                  _buildDangerSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileHero(Color mutedColor) {
    final displayName = (_data['display_name'] ?? _data['email'] ?? 'User')
        .toString();
    final email = (_data['email'] ?? '').toString();
    final walletAddress = (_data['wallet_address'] ?? '').toString();
    final walletLabel = walletAddress.isNotEmpty
        ? '${walletAddress.substring(0, 6)}…${walletAddress.substring(walletAddress.length - 4)}'
        : 'No wallet linked';

    return AppGlassCard(
      radius: 30,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.positiveDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(email, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppPill(
                label: walletAddress.isNotEmpty
                    ? 'Wallet ready'
                    : 'Wallet pending',
                color: walletAddress.isNotEmpty
                    ? AppColors.positive
                    : AppColors.warning,
              ),
              AppPill(label: walletLabel, color: AppColors.accent),
              AppPill(
                label: _securityState?.hasPin == true
                    ? 'App lock ready'
                    : 'App lock not set',
                color: _securityState?.hasPin == true
                    ? AppColors.positive
                    : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Use this space to secure the local app, refresh offline data, and tune device-level behavior without affecting your backend session.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPinPromptCard(Color mutedColor) {
    return AppGlassCard(
      color: AppColors.accent.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              AppIconBadge(
                icon: Icons.lock_rounded,
                background: AppColors.accentBg,
                foreground: AppColors.accent,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Set a PIN to enable local unlock',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You are signed in, but the local app lock has not been configured yet. Set a 4 or 6 digit PIN here, then optionally enable biometric unlock.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: mutedColor),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openPinSetup(isUpdate: false),
                  icon: const Icon(Icons.password_rounded),
                  label: const Text('Set up PIN'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(Color mutedColor) {
    final securityState = _securityState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(title: 'Security'),
        const SizedBox(height: 12),
        AppGlassCard(
          child: Column(
            children: [
              _SettingsActionRow(
                icon: Icons.pin_outlined,
                iconTint: AppColors.accent,
                title: securityState?.hasPin == true
                    ? 'Change PIN'
                    : 'Create PIN',
                subtitle: securityState?.hasPin == true
                    ? 'Update the PIN used to unlock this device.'
                    : 'Add a 4 or 6 digit PIN for local unlock.',
                actionLabel: securityState?.hasPin == true ? 'Edit' : 'Set up',
                onTap: () =>
                    _openPinSetup(isUpdate: securityState?.hasPin == true),
              ),
              const Divider(height: 20),
              _SettingsToggleRow(
                icon: Icons.shield_outlined,
                iconTint: AppColors.positive,
                title: 'App lock',
                subtitle: securityState?.hasPin == true
                    ? 'Require your PIN before opening the app.'
                    : 'Set your PIN first to enable app lock.',
                value: securityState?.appLockEnabled ?? false,
                onChanged: _securityBusy ? null : _toggleAppLock,
              ),
              const Divider(height: 20),
              _SettingsToggleRow(
                icon: Icons.fingerprint_rounded,
                iconTint: AppColors.warning,
                title: 'Biometric unlock',
                subtitle: securityState?.biometricAvailable == true
                    ? 'Use face or fingerprint unlock when available.'
                    : 'Biometrics are not available on this device.',
                value: securityState?.biometricEnabled ?? false,
                onChanged:
                    (_securityBusy || securityState?.biometricAvailable != true)
                    ? null
                    : _toggleBiometric,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceSection(BuildContext context, Color mutedColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(title: 'App experience'),
        const SizedBox(height: 12),
        AppGlassCard(
          child: Column(
            children: [
              _SettingsActionRow(
                icon: isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                iconTint: AppColors.purple,
                title: 'Theme',
                subtitle: isDark
                    ? 'Dark mode is active.'
                    : 'Light mode is active.',
                actionLabel: 'Toggle',
                onTap: () {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleTheme();
                },
              ),
              const Divider(height: 20),
              _SettingsActionRow(
                icon: Icons.sync_rounded,
                iconTint: AppColors.accent,
                title: 'Refresh local cache',
                subtitle:
                    'Sync transactions, budgets, categories, and your profile for offline use.',
                actionLabel: 'Sync',
                onTap: _syncNow,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoLoggingSection(Color mutedColor) {
    final toggles = ApiService.exampleSettings.toggles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(title: 'Auto-logging preferences'),
        const SizedBox(height: 12),
        AppGlassCard(
          child: Column(
            children: toggles.asMap().entries.map((entry) {
              final index = entry.key;
              final toggle = entry.value;
              final isLast = index == toggles.length - 1;

              return Column(
                children: [
                  _SettingsToggleRow(
                    icon: Icons.tune_rounded,
                    iconTint: AppColors.purple,
                    title: toggle.label,
                    subtitle:
                        'Keep this aligned with how you want automatic activity to behave.',
                    value: _toggleValues[index],
                    onChanged: (value) {
                      setState(() {
                        _toggleValues[index] = value;
                      });
                    },
                  ),
                  if (!isLast) const Divider(height: 20),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'These are local UI preferences for now and do not change server-side auth or wallet access.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: mutedColor),
        ),
      ],
    );
  }

  Widget _buildDangerSection() {
    return AppGlassCard(
      color: AppColors.danger.withValues(alpha: 0.06),
      child: Row(
        children: [
          const AppIconBadge(
            icon: Icons.logout_rounded,
            background: AppColors.redBg,
            foreground: AppColors.danger,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign out',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'This clears your Firebase session, backend JWT, and returns you to login.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: _handleLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.35)),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.icon,
    required this.iconTint,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color iconTint;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconBadge(
          icon: icon,
          background: iconTint.withValues(alpha: 0.14),
          foreground: iconTint,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.icon,
    required this.iconTint,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconTint;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconBadge(
          icon: icon,
          background: iconTint.withValues(alpha: 0.14),
          foreground: iconTint,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
