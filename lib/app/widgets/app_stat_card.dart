import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// KPI stat card — icon + value + label + optional trend.
/// Used on dashboards, reports, and overview screens.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.tooltip,
    this.onTap,
    this.trend,
    this.trendUp,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? tooltip;
  final VoidCallback? onTap;
  final String? trend;       // e.g. "+12%"
  final bool? trendUp;       // true = green, false = red, null = neutral

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Icon row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (trendUp == true
                                ? AppColors.success
                                : trendUp == false
                                    ? AppColors.danger
                                    : AppColors.textSecondary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trendUp == true
                                ? Icons.trending_up_rounded
                                : trendUp == false
                                    ? Icons.trending_down_rounded
                                    : Icons.trending_flat_rounded,
                            size: 12,
                            color: trendUp == true
                                ? AppColors.success
                                : trendUp == false
                                    ? AppColors.danger
                                    : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            trend!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: trendUp == true
                                  ? AppColors.success
                                  : trendUp == false
                                      ? AppColors.danger
                                      : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Value ──
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),

              // ── Label ──
              Text(
                tooltip ?? label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
