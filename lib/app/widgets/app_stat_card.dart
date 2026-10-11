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
  final String? trend; // e.g. "+12%"
  final bool? trendUp; // true = green, false = red, null = neutral

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The trend chip's colours, resolved once. `trendUp` is nullable and null
    // means "no comparison", which reads as neutral grey.
    final trendColor = trendUp == true
        ? AppColors.success
        : trendUp == false
        ? AppColors.danger
        : AppColors.textSecondary;
    final trendIcon = trendUp == true
        ? Icons.trending_up_rounded
        : trendUp == false
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Icon row ──
              // A card can put three things here: the leading icon tile, a
              // trend chip and the tooltip button. On a narrow card the three
              // together outgrow the space, so exactly one of them is allowed
              // to give ground: the chip, whose text can be shortened without
              // hiding information. The tile and the tooltip button keep their
              // full size, so the row never overflows its card.
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
                  if (trend != null || tooltip != null)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (trend != null)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: trendColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusXs,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      trendIcon,
                                      size: 12,
                                      color: trendColor,
                                    ),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        trend!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: trendColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (trend != null && tooltip != null)
                            const SizedBox(width: AppSpacing.xs),

                          // tool tip icon
                          if (tooltip != null)
                            Tooltip(
                              message: tooltip!,
                              child: const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

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
                label,
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
