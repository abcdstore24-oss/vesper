import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_lock_provider.dart';
import '../../../core/services/pin_storage.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/pin_keypad.dart';

enum _PinSetupStage { enter, confirm }

/// Choose-then-confirm flow for a new custom PIN (App Lock mode b).
/// On success, stores the hashed PIN and switches AppLockMode to
/// [AppLockMode.pin], then pops back to Settings.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  _PinSetupStage _stage = _PinSetupStage.enter;
  String _value = '';
  String? _firstPin;
  String? _error;

  void _onDigit(String digit) {
    setState(() {
      _error = null;
      _value += digit;
    });
    if (_value.length == PinStorage.pinLength) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    if (_value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
  }

  Future<void> _handleComplete() async {
    if (_stage == _PinSetupStage.enter) {
      setState(() {
        _firstPin = _value;
        _value = '';
        _stage = _PinSetupStage.confirm;
      });
      return;
    }

    if (_value == _firstPin) {
      await PinStorage.setPin(_value);
      await ref.read(appLockModeProvider.notifier).setMode(AppLockMode.pin);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = "PINs didn't match — try again.";
        _value = '';
        _firstPin = null;
        _stage = _PinSetupStage.enter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Set a PIN')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _stage == _PinSetupStage.enter
                    ? 'Choose a PIN'
                    : 'Confirm your PIN',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PinKeypad(
                length: PinStorage.pinLength,
                value: _value,
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
