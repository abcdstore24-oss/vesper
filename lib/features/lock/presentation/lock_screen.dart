import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/services/app_lock_provider.dart';
import '../../../core/services/pin_storage.dart';
import '../../../core/services/remote_status_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/pin_keypad.dart';

/// The actual lock screen, shown whenever the app is locked — cold
/// start, or resume-from-background (see main.dart's _LockGate).
/// Intercepts ALL content, including Dashboard/Settings, per CLAUDE.md
/// Section 1.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _auth = LocalAuthentication();

  bool _authInProgress = false;
  String? _osAuthError;
  bool _deviceUnsupported = false;

  String _pinValue = '';
  String? _pinError;

  @override
  void initState() {
    super.initState();
    // Don't kick off the native prompt at all if kill switch is
    // already active — _KillSwitchGate sits above this in the tree
    // and will replace this whole subtree with KillSwitchScreen
    // shortly anyway (possibly before this frame even settles); there
    // is nothing here worth protecting behind a dead end, and
    // starting the prompt here is what causes it to visibly float
    // over KillSwitchScreen once this widget gets unmounted under it.
    final killSwitchAlreadyActive =
        ref.read(effectiveRemoteStatusProvider).killSwitch;
    if (ref.read(appLockModeProvider) == AppLockMode.os &&
        !killSwitchAlreadyActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _attemptOsAuth());
    }
  }

  Future<void> _attemptOsAuth() async {
    if (_authInProgress) return;
    setState(() {
      _authInProgress = true;
      _osAuthError = null;
    });

    try {
      final supported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!supported && !canCheckBiometrics) {
        if (mounted) setState(() => _deviceUnsupported = true);
        return;
      }
      ref.read(authPromptActiveProvider.notifier).set(true);
      try {
        final didAuthenticate = await _auth.authenticate(
          localizedReason: 'Unlock Vesper',
          options: const AuthenticationOptions(
            biometricOnly: false, // allow device PIN/pattern fallback too
            stickyAuth: true,
          ),
        );

        if (didAuthenticate) {
          ref.read(isUnlockedProvider.notifier).unlock();
        } else {
          // Guarded: if kill switch flipped true mid-prompt (see the
          // ref.listen in build()), stopAuthentication() causes this
          // branch to run right as _KillSwitchGate is unmounting this
          // widget — without the mounted check this throws.
          if (mounted) setState(() => _osAuthError = 'Authentication cancelled.');
        }
      } finally {
        ref.read(authPromptActiveProvider.notifier).set(false);
        if (mounted) setState(() => _authInProgress = false);
      }
    } catch (_) {
      if (mounted) setState(() => _osAuthError = "Couldn't authenticate. Try again.");
    } finally {
      if (mounted) setState(() => _authInProgress = false);
    }
  }

  void _onPinDigit(String digit) {
    setState(() {
      _pinError = null;
      _pinValue += digit;
    });
    if (_pinValue.length == PinStorage.pinLength) {
      _submitPin();
    }
  }

  void _onPinBackspace() {
    if (_pinValue.isEmpty) return;
    setState(() => _pinValue = _pinValue.substring(0, _pinValue.length - 1));
  }

  Future<void> _submitPin() async {
    final ok = await PinStorage.verifyPin(_pinValue);
    if (ok) {
      ref.read(isUnlockedProvider.notifier).unlock();
    } else {
      setState(() {
        _pinError = 'Incorrect PIN';
        _pinValue = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = ref.watch(appLockModeProvider);

    // If kill switch flips true WHILE a native OS prompt is already
    // showing, cancel it — otherwise it keeps floating over
    // KillSwitchScreen once _KillSwitchGate unmounts this widget out
    // from under the in-flight authenticate() call.
    ref.listen<EffectiveRemoteStatus>(effectiveRemoteStatusProvider, (
      previous,
      next,
    ) {
      if (next.killSwitch && _authInProgress) {
        _auth.stopAuthentication();
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: mode == AppLockMode.pin
                ? _buildPinEntry(theme)
                : _buildOsLock(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildOsLock(ThemeData theme) {
    if (_deviceUnsupported) return _buildUnsupportedFallback(theme);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          PhosphorIconsRegular.lockKey,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Vesper is locked', style: theme.textTheme.headlineLarge),
        if (_osAuthError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _osAuthError!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _authInProgress ? null : _attemptOsAuth,
          child: Text(_authInProgress ? 'Authenticating…' : 'Unlock'),
        ),
      ],
    );
  }

  Widget _buildUnsupportedFallback(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          PhosphorIconsRegular.warning,
          size: 48,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'No device lock set up',
          style: theme.textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          "Your device doesn't have a screen lock, so App Lock can't use "
          'it. Choose a custom PIN or turn App Lock off in Settings.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          // Escape hatch: unlocks THIS session only, so the user can
          // reach Settings and pick a working mode. Does NOT change
          // the persisted mode — still 'os' until they choose
          // otherwise in Settings.
          onPressed: () => ref.read(isUnlockedProvider.notifier).unlock(),
          child: const Text('Go to Settings'),
        ),
      ],
    );
  }

  Widget _buildPinEntry(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          PhosphorIconsRegular.lockKey,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Enter your PIN', style: theme.textTheme.headlineLarge),
        if (_pinError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _pinError!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        PinKeypad(
          length: PinStorage.pinLength,
          value: _pinValue,
          onDigit: _onPinDigit,
          onBackspace: _onPinBackspace,
        ),
      ],
    );
  }
}