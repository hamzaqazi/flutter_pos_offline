import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  bool _pinEnabled = true; // default: PIN on

  void _onDigit(String digit) {
    setState(() {
      if (!_isConfirmStep) {
        if (_pin.length < 4) _pin += digit;
        if (_pin.length == 4) {
          _isConfirmStep = true;
        }
      } else {
        if (_confirmPin.length < 4) _confirmPin += digit;
        if (_confirmPin.length == 4) {
          _submit();
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (!_isConfirmStep) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirmStep = false;
        }
      }
    });
  }

  Future<void> _submit() async {
    if (_pin != _confirmPin) {
      setState(() {
        _confirmPin = '';
        _isConfirmStep = false;
      });
      Get.snackbar(
        'Mismatch',
        'PINs do not match. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withValues(alpha: 0.15),
        colorText: AppColors.danger,
      );
      return;
    }

    if (_pinEnabled) {
      await LicenseService.setPin(_pin);
    } else {
      await LicenseService.setPin('');
    }

    Get.offAllNamed('/');
  }

  void _skip() async {
    await LicenseService.setPin('');
    Get.offAllNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currentPin = _isConfirmStep ? _confirmPin : _pin;
    final title = _isConfirmStep ? 'Confirm PIN' : 'Set PIN';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),

            // Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline, color: cs.primary, size: 40),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _isConfirmStep
                  ? 'Enter the same PIN again to confirm'
                  : 'Create a 4-digit PIN to secure your app',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < currentPin.length;
                return Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? cs.primary : cs.surfaceContainerHighest,
                    border: Border.all(
                      color: filled ? cs.primary : cs.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: filled
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.onPrimary,
                            ),
                          ),
                        )
                      : null,
                );
              }),
            ),

            const SizedBox(height: AppSpacing.xl),

            // PIN toggle (optional)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Card(
                child: SwitchListTile(
                  value: _pinEnabled,
                  onChanged: (v) => setState(() => _pinEnabled = v),
                  title: const Text('Enable PIN lock'),
                  subtitle: Text(
                    _pinEnabled
                        ? 'PIN will be required on app launch'
                        : 'App will open without PIN',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  secondary: Icon(
                    _pinEnabled ? Icons.lock : Icons.lock_open,
                    color: _pinEnabled ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Skip button
            TextButton(
              onPressed: _skip,
              child: Text(
                'Skip — No PIN needed',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),

            const Spacer(),

            // Numpad
            if (_pinEnabled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['1', '2', '3'].map((d) => _numpadBtn(d)).toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['4', '5', '6'].map((d) => _numpadBtn(d)).toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['7', '8', '9'].map((d) => _numpadBtn(d)).toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 72, height: 72),
                        _numpadBtn('0'),
                        _numpadBtn('⌫', isDelete: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        ),
      ),
    ),
    );
  }

  Widget _numpadBtn(String digit, {bool isDelete = false}) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDelete ? _onDelete : () => _onDigit(digit),
          borderRadius: BorderRadius.circular(36),
          child: Center(
            child: isDelete
                ? Icon(Icons.backspace_outlined, size: 28, color: theme.colorScheme.onSurfaceVariant)
                : Text(
                    digit,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
