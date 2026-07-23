import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/launcher.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  // ── License key activation ──
  final _keyController = TextEditingController();
  bool _loading = false;
  String? _error;

  // ── Phone verification for trial ──
  final _phoneController = TextEditingController();
  bool _phoneLoading = false;
  String? _phoneError;

  // ── Trial eligibility ──
  bool _trialEligible = true;
  bool _checkingTrialEligibility = true;

  // ── Step tracking: 'choose' or 'phone' ──
  String _step = 'choose';

  @override
  void initState() {
    super.initState();
    _checkTrialEligibility();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Check Firestore if this device can start a new trial.
  Future<void> _checkTrialEligibility() async {
    if (LicenseService.hasUsedTrial || LicenseService.isActivated) {
      setState(() {
        _trialEligible = false;
        _checkingTrialEligibility = false;
      });
      return;
    }
    final eligible = await LicenseService.checkDeviceTrialEligibility();
    setState(() {
      _trialEligible = eligible != false;
      _checkingTrialEligibility = false;
    });
  }

  // ── License key activation ──
  Future<void> _activate() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Please enter a license key');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await LicenseService.validateLicense(key);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      LicenseService.clearDeactivationReason();
      Get.offAllNamed('/pin-setup');
    } else {
      setState(() => _error = result.message);
    }
  }

  // ── Phone validation ──
  /// Validate Pakistani phone number format.
  /// Accepts: 03XX-XXXXXXX, 03XXXXXXXXXX, or 923XXXXXXXXXX
  bool _isValidPakistaniPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    // 03XX-XXXXXXX (11 digits local) or 923XXXXXXXXXX (12 digits with country code)
    if (digits.length == 11 && digits.startsWith('03')) return true;
    if (digits.length == 12 && digits.startsWith('923')) return true;
    return false;
  }

  /// Convert phone to international format (923XXXXXXXXXX) for WhatsApp.
  String _phoneToInternational(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('03')) return '92${digits.substring(1)}';
    return digits; // already has 92 prefix
  }

  // ── Start trial with phone number ──
  Future<void> _startTrialWithPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Please enter your phone number');
      return;
    }
    if (!_isValidPakistaniPhone(phone)) {
      setState(
        () =>
            _phoneError = 'Enter a valid Pakistani number (e.g. 0315-3507075)',
      );
      return;
    }

    setState(() {
      _phoneLoading = true;
      _phoneError = null;
    });

    // Re-check Firestore eligibility before starting
    final eligible = await LicenseService.checkDeviceTrialEligibility();
    if (eligible == false) {
      if (!mounted) return;
      await LicenseService.markTrialAlreadyUsed();
      setState(() {
        _trialEligible = false;
        _phoneLoading = false;
        _step = 'choose';
      });
      Get.snackbar(
        'Trial Already Used',
        'This device has already used a free trial. Activate a license or continue with the free plan.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Start trial with phone number
    final intlPhone = _phoneToInternational(phone);
    await LicenseService.startTrial(customerPhone: intlPhone);

    if (!mounted) return;
    setState(() => _phoneLoading = false);
    LicenseService.clearDeactivationReason();
    Get.offAllNamed('/pin-setup');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withValues(alpha: 0.05),
              cs.surface,
              cs.primary.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Brand Logo ──
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Image(
                          image: AssetImage(
                            'lib/assets/images/cn_pos_logo_rm.png',
                          ),
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    Text(
                      'Codynest POS',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Point of Sale System',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Trial Expired Banner ──
                    if (LicenseService.trialStartDate != null &&
                        !LicenseService.isTrialActive &&
                        !LicenseService.isActivated)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_off_outlined,
                                  color: AppColors.warning,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    'Free Trial Expired',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Your 14-day free trial has ended. Activate a license to continue using all features, or continue with the free plan (${LicenseService.freeMaxProducts} products max).',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.warning.withValues(alpha: 0.9),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Deactivation Reason Banner ──
                    if (LicenseService.hasDeactivationReason)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.danger,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    'License Deactivated',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              LicenseService.deactivationReason,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.danger,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Icon(
                                  Icons.call,
                                  size: 14,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Contact: 0315-3507075',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // ── STEP: Choose (Free Trial or License Key) ──
                    if (_step == 'choose') ...[
                      // ── Free Trial Card ──
                      if (_trialEligible && !LicenseService.isActivated)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => setState(() => _step = 'phone'),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.seed.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.celebration_outlined,
                                      color: AppColors.seed,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Try Free for 14 Days',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.seed,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Full access to all Premium features.\nNo credit card required — just verify your phone number.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: FilledButton.tonal(
                                      onPressed: () =>
                                          setState(() => _step = 'phone'),
                                      style: FilledButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusMd,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.rocket_launch_outlined,
                                            size: 18,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            'Start Free Trial',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── License Key Card ──
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.vpn_key_outlined,
                                      color: cs.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    'Activate Your License',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Enter the license key provided to you to activate this application. Each key is linked to your shop and device.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              TextField(
                                controller: _keyController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3,
                                  fontFamily: 'monospace',
                                ),
                                decoration: InputDecoration(
                                  labelText: 'License Key',
                                  hintText: 'CNPO-XXXX-XXXX-XXXX',
                                  prefixIcon: const Icon(
                                    Icons.vpn_key_outlined,
                                  ),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _activate(),
                              ),

                              if (_error != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm,
                                    ),
                                    border: Border.all(
                                      color: AppColors.danger.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: AppColors.danger,
                                        size: 18,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: AppColors.danger,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: AppSpacing.xl),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: _loading ? null : _activate,
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.verified_user_outlined,
                                              size: 20,
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Text(
                                              'Activate License',
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    color: cs.onPrimary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),
                              // ── Buy license via WhatsApp ──
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () => Launcher.openWhatsApp(
                                    '923153507075',
                                    'Hi! I want to buy a Codynest POS license key. My device ID: ${LicenseService.deviceId}',
                                  ),
                                  // asset image with WhatsApp logo can also be used instead of icon
                                  icon: Image.asset(
                                    'lib/assets/images/whatsapp-logo1.png',
                                    width: 28,
                                    height: 28,

                                    // color: const Color(0xFF25D366),
                                  ),
                                  label: Text(
                                    'Buy via WhatsApp',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF25D366),
                                    side: const BorderSide(
                                      color: Color(0xFF25D366),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ── STEP: Phone verification for trial ──
                    if (_step == 'phone') ...[
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            children: [
                              // Back button
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _step = 'choose'),
                                  icon: const Icon(Icons.arrow_back, size: 18),
                                  label: const Text('Back'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              Icon(
                                Icons.phone_android_rounded,
                                color: AppColors.seed,
                                size: 48,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Verify Your Phone Number',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'We need your phone number to set up your 14-day free trial. We may contact you via WhatsApp about your subscription.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: '0315-3507075',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  prefixText: '+92 ',
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _startTrialWithPhone(),
                              ),

                              if (_phoneError != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm,
                                    ),
                                    border: Border.all(
                                      color: AppColors.danger.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: AppColors.danger,
                                        size: 18,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          _phoneError!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: AppColors.danger,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: AppSpacing.xl),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: _phoneLoading
                                      ? null
                                      : _startTrialWithPhone,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.seed,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                  ),
                                  child: _phoneLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.rocket_launch_outlined,
                                              size: 20,
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Text(
                                              'Start 14-Day Free Trial',
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Your trial starts immediately after verification.\nFull access to all Premium features for 14 days.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ── Continue with Free Plan ──
                    if (LicenseService.trialStartDate != null &&
                        !LicenseService.isTrialActive &&
                        !LicenseService.isActivated)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: TextButton(
                          onPressed: () => Get.offAllNamed('/dashboard'),
                          child: Text(
                            'Continue with Free Plan (${LicenseService.freeMaxProducts} products max)',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Device ID ──
                    FutureBuilder<String>(
                      future: LicenseService.deviceId,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final deviceId = snapshot.data!;
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.devices,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Device: ${deviceId.length > 20 ? deviceId.substring(0, 20) : deviceId}...',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Footer ──
                    Column(
                      children: [
                        Text(
                          'Need help? Contact support',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.call,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '0315-3507075',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Powered by Codynest.com',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
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
