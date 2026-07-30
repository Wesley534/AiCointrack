import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/local_auth_lock_service.dart';
import '../services/sync_service.dart';

class PinUnlockPage extends StatefulWidget {
  const PinUnlockPage({super.key});

  @override
  State<PinUnlockPage> createState() => _PinUnlockPageState();
}

class _PinUnlockPageState extends State<PinUnlockPage> {
  final _pinController = TextEditingController();
  int _pinLength = 4;
  int _attempts = 0;
  bool _isBusy = false;
  bool _biometricAvailable = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final length = await LocalAuthLockService.getPinLength() ?? 4;
    final biometricAvailable =
        await LocalAuthLockService.isBiometricAvailable();
    if (!mounted) return;
    setState(() {
      _pinLength = length;
      _biometricAvailable = biometricAvailable;
    });

    if (await LocalAuthLockService.isBiometricEnabled()) {
      await _tryBiometricUnlock();
    }
  }

  Future<void> _submitPin() async {
    final pin = _pinController.text.trim();
    if (pin.length != _pinLength) {
      setState(() => _error = 'Enter your $_pinLength-digit PIN.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    final isValid = await LocalAuthLockService.verifyPin(pin);
    if (!mounted) return;

    if (isValid) {
      await SyncService.instance.syncAll(trigger: 'unlock');
      setState(() => _isBusy = false);
      return;
    }

    setState(() {
      _attempts += 1;
      _isBusy = false;
      _error = _attempts >= 3
          ? 'Still locked. Check your PIN and try again.'
          : 'Incorrect PIN. Try again.';
    });
  }

  Future<void> _tryBiometricUnlock() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    final success = await LocalAuthLockService.authenticateWithBiometrics();
    if (!mounted) return;

    if (success) {
      await SyncService.instance.syncAll(trigger: 'unlock');
      setState(() => _isBusy = false);
      return;
    }

    setState(() {
      _isBusy = false;
      _error = 'Biometric unlock was unavailable. Use your PIN instead.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Scaffold(
      body: Container(
        decoration: AppDecorations.pageBackground(context),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock AiCoinTrack',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your signed-in session is still valid. Enter your PIN to unlock the local app.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: _pinLength,
                      decoration: InputDecoration(
                        labelText: 'PIN',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onSubmitted: (_) => _isBusy ? null : _submitPin(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isBusy ? null : _submitPin,
                        child: _isBusy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Unlock'),
                      ),
                    ),
                    if (_biometricAvailable) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isBusy ? null : _tryBiometricUnlock,
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: const Text('Use biometric unlock'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
