import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class LicensePage extends StatelessWidget {
  const LicensePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('License & Subscription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Plan Card ──
            _PlanHeader(),
            const SizedBox(height: AppSpacing.xl),

            // ── License Details ──
            Text(
              'License Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailsCard(),
            const SizedBox(height: AppSpacing.xl),

            // ── Plan Comparison ──
            Text(
              'Available Plans',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PlanComparisonCards(),
            const SizedBox(height: AppSpacing.xl),

            // ── Actions ──
            if (LicenseService.isActivated)
              _DeactivateButton(),
            if (!LicenseService.isPaidPlan)
              _UpgradeSection(),
            const SizedBox(height: AppSpacing.xl),

            // ── Support ──
            _SupportCard(),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Plan Header
// ────────────────────────────────────────────────────────────

class _PlanHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPremium = LicenseService.isPremium;
    final isTrial = LicenseService.isTrialActive;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPremium
              ? [AppColors.seed, AppColors.seed.withValues(alpha: 0.7)]
              : [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPremium
                  ? (LicenseService.storedPlan == 'lifetime'
                      ? Icons.workspace_premium
                      : Icons.verified)
                  : Icons.lock_outline,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Plan name
          Text(
            LicenseService.planDisplayWithEmoji,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Subtitle
          if (isTrial)
            Text(
              '${LicenseService.trialDaysRemaining} days remaining — full access',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            )
          else if (isPremium && LicenseService.storedPlan == 'lifetime')
            const Text(
              'All features unlocked forever',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            )
          else if (isPremium && LicenseService.expiresAt != null)
            Text(
              'Renews ${_formatDate(LicenseService.expiresAt!)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            )
          else
            Text(
              'Limited to ${LicenseService.freeMaxProducts} products',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Details Card
// ────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Shop Name
            if (LicenseService.shopName.isNotEmpty)
              _DetailRow(
                icon: Icons.store_outlined,
                label: 'Shop Name',
                value: LicenseService.shopName,
              ),

            // License Key
            if (LicenseService.isActivated) ...[
              if (LicenseService.shopName.isNotEmpty)
                const _DetailDivider(),
              _DetailRow(
                icon: Icons.vpn_key_outlined,
                label: 'License Key',
                value: LicenseService.licenseKey,
                monospace: true,
              ),
            ],

            // Plan
            const _DetailDivider(),
            _DetailRow(
              icon: Icons.card_membership_outlined,
              label: 'Plan',
              value: LicenseService.planDisplayName,
            ),

            // Expiry
            if (LicenseService.expiresAt != null) ...[
              const _DetailDivider(),
              Builder(
                builder: (_) {
                  final exp = LicenseService.expiresAt!;
                  final days = LicenseService.daysUntilExpiry ?? 0;
                  final isWarning = days <= 30;
                  final isCritical = days <= 7;
                  final color = isCritical
                      ? AppColors.danger
                      : isWarning
                          ? AppColors.warning
                          : AppColors.success;
                  return _DetailRow(
                    icon: Icons.event_outlined,
                    label: 'Expires',
                    value: '${_formatDate(exp)} ($days days left)',
                    valueColor: color,
                  );
                },
              ),
            ],

            // Lifetime
            if (LicenseService.storedPlan == 'lifetime' && LicenseService.isActivated) ...[
              const _DetailDivider(),
              const _DetailRow(
                icon: Icons.all_inclusive,
                label: 'Expires',
                value: 'Never — Lifetime License',
                valueColor: AppColors.success,
              ),
            ],

            // Trial start
            if (LicenseService.trialStartDate != null) ...[
              const _DetailDivider(),
              _DetailRow(
                icon: Icons.celebration_outlined,
                label: 'Trial Started',
                value: _formatDate(LicenseService.trialStartDate!),
              ),
            ],

            // Device ID
            const _DetailDivider(),
            FutureBuilder<String>(
              future: LicenseService.deviceId,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return _DetailRow(
                  icon: Icons.devices,
                  label: 'Device ID',
                  value: snapshot.data!,
                  monospace: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool monospace;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: monospace ? 'monospace' : null,
                  color: valueColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Plan Comparison
// ────────────────────────────────────────────────────────────

class _PlanComparisonCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentPlan = LicenseService.storedPlan;
    final isTrial = LicenseService.isTrialActive;

    return Column(
      children: [
        // Free
        _PlanRow(
          icon: '🆓',
          title: 'Free',
          price: 'Free',
          features: '25 products, basic POS',
          isCurrent: !isTrial && !LicenseService.isActivated,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Monthly
        _PlanRow(
          icon: '⭐',
          title: 'Monthly',
          price: 'Rs 500/mo',
          features: 'Unlimited products, all features',
          isCurrent: currentPlan == 'monthly',
          onTap: () => _openWhatsApp(context, 'Monthly'),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Yearly
        _PlanRow(
          icon: '⭐',
          title: 'Yearly',
          price: 'Rs 4,000/yr',
          features: 'All features, 33% off monthly',
          badge: '33% off',
          isCurrent: currentPlan == 'yearly',
          onTap: () => _openWhatsApp(context, 'Yearly'),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Lifetime
        _PlanRow(
          icon: '👑',
          title: 'Lifetime',
          price: 'Rs 10,000',
          features: 'All features forever, best value',
          badge: 'Best value',
          isCurrent: currentPlan == 'lifetime',
          isHighlighted: true,
          onTap: () => _openWhatsApp(context, 'Lifetime'),
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.icon,
    required this.title,
    required this.price,
    required this.features,
    this.isCurrent = false,
    this.isHighlighted = false,
    this.badge,
    this.onTap,
  });

  final String icon;
  final String title;
  final String price;
  final String features;
  final bool isCurrent;
  final bool isHighlighted;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: isCurrent ? null : onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.seed.withValues(alpha: 0.06)
              : isHighlighted
                  ? cs.primary.withValues(alpha: 0.04)
                  : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isCurrent
                ? AppColors.seed.withValues(alpha: 0.4)
                : isHighlighted
                    ? cs.primary.withValues(alpha: 0.3)
                    : cs.outlineVariant,
            width: isCurrent || isHighlighted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.md),

            // Title + features
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.seed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: AppColors.seed,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    features,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Price or Current badge
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.seed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Text(
                  'Current',
                  style: TextStyle(
                    color: AppColors.seed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Text(
                price,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isHighlighted ? cs.primary : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Deactivate Button
// ────────────────────────────────────────────────────────────

class _DeactivateButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => _confirmDeactivate(context),
          icon: Icon(
            Icons.logout,
            size: 18,
            color: AppColors.danger.withValues(alpha: 0.7),
          ),
          label: Text(
            'Deactivate License',
            style: TextStyle(
              color: AppColors.danger.withValues(alpha: 0.7),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: AppColors.danger.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeactivate(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Deactivate License?'),
        content: const Text(
          'This will remove your license from this device. '
          'Your data will NOT be deleted, but premium features will be locked.\n\n'
          'You can reactivate anytime with the same license key.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () async {
              await LicenseService.deactivate(
                reason: 'License deactivated by user from settings.',
              );
              Navigator.of(context).pop(); // Close dialog
              Get.offAllNamed('/activation'); // Go to activation
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Upgrade Section (for free/trial users)
// ────────────────────────────────────────────────────────────

class _UpgradeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: () => _openWhatsApp(context, 'Any Plan'),
            icon: const Icon(Icons.chat, size: 20),
            label: const Text('Purchase via WhatsApp'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () async {
              final telUri = Uri.parse('tel:+923153507075');
              if (await canLaunchUrl(telUri)) {
                await launchUrl(telUri);
              }
            },
            icon: const Icon(Icons.call, size: 18),
            label: const Text('Call: 0315-3507075'),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Support Card
// ────────────────────────────────────────────────────────────

class _SupportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.support_agent, size: 20, color: cs.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Need Help?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'For license activation, renewal, or any issues, contact us:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // WhatsApp
            InkWell(
              onTap: () => _openWhatsApp(context, 'Support'),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(Icons.chat, size: 18, color: Colors.green[700]),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'WhatsApp: 0315-3507075',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Call
            InkWell(
              onTap: () async {
                final telUri = Uri.parse('tel:+923153507075');
                if (await canLaunchUrl(telUri)) {
                  await launchUrl(telUri);
                }
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(Icons.call, size: 18, color: cs.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Call: 0315-3507075',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Website
            Row(
              children: [
                Icon(Icons.language, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Codynest.com',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
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

// ────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────

String _formatDate(DateTime date) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month]} ${date.year}';
}

void _openWhatsApp(BuildContext context, String plan) async {
  final message = Uri.encodeComponent(
    'Hi, I want to purchase Codynest POS license.\n'
    'Plan: $plan\n'
    'App: Codynest POS',
  );
  final whatsappUrl = 'https://wa.me/923153507075?text=$message';

  try {
    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final smsUri = Uri.parse('sms:+923153507075?body=$message');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    }
  } catch (e) {
    if (context.mounted) {
      Get.snackbar(
        'Contact Us',
        'WhatsApp/Call: 0315-3507075',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
