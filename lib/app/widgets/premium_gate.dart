import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ad_shop_pos/app/utils/launcher.dart';

/// A widget that gates premium features behind the license check.
///
/// - If [isPremium] or [isTrialActive] → shows [child] normally.
/// - If free tier → shows a locked placeholder with upgrade CTA.
/// - If trial is active → shows [child] with an optional trial banner.
///
/// Usage:
/// ```dart
/// PremiumGate(
///   feature: 'Reports & Analytics',
///   child: ReportsContent(),
/// )
/// ```
class PremiumGate extends StatelessWidget {
  const PremiumGate({
    super.key,
    required this.feature,
    required this.child,
    this.showTrialBanner = false,
    this.lockedBuilder,
  });

  /// The name of the premium feature (shown in upgrade dialog).
  final String feature;

  /// The widget to show when the user has premium access.
  final Widget child;

  /// Whether to show a "trial days remaining" banner above the child.
  final bool showTrialBanner;

  /// Optional custom builder for the locked state.
  /// If not provided, a default locked card is shown.
  final Widget Function(BuildContext context, String feature)? lockedBuilder;

  @override
  Widget build(BuildContext context) {
    // Premium or trial → show feature
    if (LicenseService.isPremium) {
      if (LicenseService.isTrialActive && showTrialBanner) {
        return Column(
          children: [
            _TrialBanner(daysRemaining: LicenseService.trialDaysRemaining),
            Expanded(child: child),
          ],
        );
      }
      return child;
    }

    // Free tier → show locked state
    if (lockedBuilder != null) {
      return lockedBuilder!(context, feature);
    }
    return _LockedFeature(feature: feature);
  }
}

/// Inline premium check — returns child or a small locked badge.
/// Use for small UI elements like buttons, icons, list tiles.
class PremiumGateIcon extends StatelessWidget {
  const PremiumGateIcon({
    super.key,
    required this.feature,
    required this.child,
    this.onLocked,
  });

  final String feature;
  final Widget child;
  final VoidCallback? onLocked;

  @override
  Widget build(BuildContext context) {
    if (LicenseService.isPremium) return child;

    return GestureDetector(
      onTap: onLocked ?? () => _showUpgradeSheet(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Default locked feature card shown to free users.
class _LockedFeature extends StatelessWidget {
  const _LockedFeature({required this.feature});

  final String feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 48,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              feature,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This feature is available on Premium plans.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 220,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => _showUpgradeSheet(context),
                icon: const Icon(Icons.workspace_premium_outlined, size: 20),
                label: const Text('Upgrade to Premium'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => _showUpgradeSheet(context, showKeyEntry: true),
              child: Text(
                'Already have a license key?',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trial banner shown at the top of pages during the trial period.
class _TrialBanner extends StatelessWidget {
  const _TrialBanner({required this.daysRemaining});

  final int daysRemaining;

  @override
  Widget build(BuildContext context) {
    final isUrgent = daysRemaining <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: (isUrgent ? AppColors.warning : AppColors.seed)
            .withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: (isUrgent ? AppColors.warning : AppColors.seed)
                .withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUrgent ? Icons.timer_outlined : Icons.celebration_outlined,
            size: 18,
            color: isUrgent ? AppColors.warning : AppColors.seed,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isUrgent
                  ? 'Trial expires in $daysRemaining day${daysRemaining == 1 ? '' : 's'}! Upgrade now to keep all features.'
                  : 'Trial: $daysRemaining days remaining — enjoy all Premium features!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUrgent ? AppColors.warning : AppColors.seed,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showUpgradeSheet(context),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show the upgrade/pricing bottom sheet.
void _showUpgradeSheet(BuildContext context, {bool showKeyEntry = false}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _UpgradeSheet(showKeyEntry: showKeyEntry),
  );
}

/// Upgrade bottom sheet with plan comparison + license key entry.
class _UpgradeSheet extends StatefulWidget {
  const _UpgradeSheet({this.showKeyEntry = false});

  final bool showKeyEntry;

  @override
  State<_UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends State<_UpgradeSheet> {
  bool _showKeyEntry = false;
  final _keyController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _showKeyEntry = widget.showKeyEntry;
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _activateKey() async {
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
      Navigator.of(context).pop(); // Close sheet
      Get.snackbar(
        'Activated! 🎉',
        'Your ${result.plan ?? 'premium'} plan is now active.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            'Upgrade to Premium',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Unlock all features and grow your business',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Plan cards
          Row(
            children: [
              Expanded(
                child: _PlanCard(
                  title: 'Monthly',
                  price: 'Rs 500',
                  period: '/month',
                  onTap: () => _openWhatsApp('Monthly'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PlanCard(
                  title: 'Yearly',
                  price: 'Rs 4,000',
                  period: '/year',
                  badge: '33% off',
                  onTap: () => _openWhatsApp('Yearly'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _PlanCard(
            title: 'Lifetime',
            price: 'Rs 10,000',
            period: ' one-time',
            badge: 'Best value',
            highlighted: true,
            onTap: () => _openWhatsApp('Lifetime'),
          ),

          const SizedBox(height: AppSpacing.lg),

          // License key entry toggle
          if (!_showKeyEntry)
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showKeyEntry = true),
                icon: const Icon(Icons.vpn_key_outlined, size: 18),
                label: const Text('Already have a license key?'),
              ),
            ),

          if (_showKeyEntry) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Enter License Key',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _keyController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'XXXX-XXXX-XXXX-XXXX',
                prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                filled: true,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                errorText: _error,
              ),
              onSubmitted: (_) => _activateKey(),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: _loading ? null : _activateKey,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Activate'),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Contact support — Call + WhatsApp
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Call button
              InkWell(
                onTap: () => Launcher.makeCall('923153507075'),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.call, size: 14, color: cs.onSurfaceVariant),
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
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // WhatsApp button
              InkWell(
                onTap: () => _openWhatsApp('General Inquiry'),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat, size: 14, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'WhatsApp',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openWhatsApp(String plan) async {
    final success = await Launcher.openWhatsApp(
      '923153507075',
      'Hi, I want to purchase Codynest POS license.\nPlan: $plan\nApp: Codynest POS',
    );
    if (!success && context.mounted) {
      Get.snackbar(
        'Contact Us',
        'WhatsApp/Call: 0315-3507075',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

/// A single plan card in the upgrade sheet.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.onTap,
    this.badge,
    this.highlighted = false,
  });

  final String title;
  final String price;
  final String period;
  final VoidCallback onTap;
  final String? badge;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: highlighted
              ? cs.primary.withValues(alpha: 0.08)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: highlighted
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outlineVariant,
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.seed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: AppColors.seed,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: highlighted ? cs.primary : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    period,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
