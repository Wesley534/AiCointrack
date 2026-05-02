import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/local_auth_lock_service.dart';

class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key, this.canSkip = true, this.isUpdate = false});

  final bool canSkip;
  final bool isUpdate;

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  int _selectedLength = 4;
  bool _biometricAvailable = false;
  bool _enableBiometric = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBiometricAvailability();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricAvailability() async {
    final available = await LocalAuthLockService.isBiometricAvailable();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
    });
  }

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length != _selectedLength || !RegExp(r'^\d+$').hasMatch(pin)) {
      setState(() => _error = 'Enter a $_selectedLength-digit PIN.');
      return;
    }
    if (confirm != pin) {
      setState(() => _error = 'PINs do not match.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    await LocalAuthLockService.savePin(
      pin: pin,
      enableBiometric: _biometricAvailable && _enableBiometric,
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _skip() {
    LocalAuthLockService.deferPinSetupPrompt();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (widget.canSkip)
            TextButton(
              onPressed: _isSaving ? null : _skip,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isUpdate ? 'Update app PIN' : 'Set app PIN',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'This PIN only unlocks the local app on this device. Your backend session and wallet auth stay the same.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: muted),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('4 digits'),
                    selected: _selectedLength == 4,
                    onSelected: _isSaving
                        ? null
                        : (_) => setState(() => _selectedLength = 4),
                  ),
                  ChoiceChip(
                    label: const Text('6 digits'),
                    selected: _selectedLength == 6,
                    onSelected: _isSaving
                        ? null
                        : (_) => setState(() => _selectedLength = 6),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: _selectedLength,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: _selectedLength,
                decoration: InputDecoration(
                  labelText: 'Confirm PIN',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (_biometricAvailable) ...[
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable biometric unlock'),
                  subtitle: Text(
                    'Use fingerprint or face unlock after the PIN is saved.',
                    style: TextStyle(color: muted),
                  ),
                  value: _enableBiometric,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _enableBiometric = value),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePin,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isUpdate ? 'Update PIN' : 'Save PIN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
