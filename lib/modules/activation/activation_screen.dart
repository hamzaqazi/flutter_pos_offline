import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _keyController = TextEditingController();
  bool _loading = false;
  String? _error;

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
      Get.offAllNamed('/pin-setup');
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ---------- Brand Logo Area ----------
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.seed, AppColors.seed.withValues(alpha: 0.75)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.seed.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.point_of_sale,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ---------- Title ----------
                    Text(
                      'Shop POS',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Point of Sale System',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ---------- Card ----------
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  ),
                                  child: Icon(Icons.vpn_key_outlined, color: cs.primary, size: 20),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  'Activate Your License',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
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

                            // License key input
                            TextField(
                              controller: _keyController,
                              textCapitalization: TextCapitalization.characters,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                                fontFamily: 'monospace',
                              ),
                              decoration: InputDecoration(
                                labelText: 'License Key',
                                hintText: 'XXXX-XXXX-XXXX',
                                prefixIcon: const Icon(Icons.vpn_key_outlined),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  borderSide: BorderSide(color: cs.outlineVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  borderSide: BorderSide(color: cs.primary, width: 2),
                                ),
                              ),
                              onSubmitted: (_) => _activate(),
                            ),

                            // Error message
                            if (_error != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  border: Border.all(
                                    color: AppColors.danger.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: theme.textTheme.bodySmall?.copyWith(
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

                            // Activate button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: _loading ? null : _activate,
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.verified_user_outlined, size: 20),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            'Activate License',
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              color: cs.onPrimary,
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

                    const SizedBox(height: AppSpacing.xl),

                    // ---------- Device ID + Support Info ----------
                    FutureBuilder<String>(
                      future: LicenseService.deviceId,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final deviceId = snapshot.data!;
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.devices, size: 16, color: cs.onSurfaceVariant),
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

                    // ---------- Footer ----------
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
                            Icon(Icons.call, size: 14, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              '0315-3507075 / 0345-3333316',
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
