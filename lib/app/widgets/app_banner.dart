import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Info/warning/danger banner with icon, title, subtitle, and optional action.
/// Used for trial banners, license info, deactivation reasons, etc.
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.type,
    this.actionLabel,
    this.onAction,
    this.margin,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final AppBannerType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? margin;

  /// Convenience constructors
  factory AppBanner.trial({
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      AppBanner(
        title: title,
        subtitle: subtitle,
        type: AppBannerType.trial,
        icon: Icons.celebration_outlined,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  factory AppBanner.warning({
    required String title,
    String? subtitle,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      AppBanner(
        title: title,
        subtitle: subtitle,
        type: AppBannerType.warning,
        icon: icon ?? Icons.warning_amber_rounded,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  factory AppBanner.danger({
    required String title,
    String? subtitle,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      AppBanner(
        title: title,
        subtitle: subtitle,
        type: AppBannerType.danger,
        icon: icon ?? Icons.error_outline_rounded,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  factory AppBanner.success({
    required String title,
    String? subtitle,
    IconData? icon,
  }) =>
      AppBanner(
        title: title,
        subtitle: subtitle,
        type: AppBannerType.success,
        icon: icon ?? Icons.check_circle_outline_rounded,
      );

  factory AppBanner.info({
    required String title,
    String? subtitle,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      AppBanner(
        title: title,
        subtitle: subtitle,
        type: AppBannerType.info,
        icon: icon ?? Icons.info_outline_rounded,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _typeColor;
    final bgColor = _typeBgColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              height: 32,
              child: FilledButton.tonal(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _typeColor {
    switch (type) {
      case AppBannerType.success:
        return AppColors.success;
      case AppBannerType.warning:
        return AppColors.warning;
      case AppBannerType.danger:
        return AppColors.danger;
      case AppBannerType.info:
        return AppColors.info;
      case AppBannerType.trial:
        return AppColors.seed;
    }
  }

  // Tinted from the type color itself (not a fixed pastel swatch) so it
  // adapts to dark mode automatically — a fixed light-mode pastel like
  // warningLight sits as a glaring bright patch on a dark surface.
  Color get _typeBgColor => _typeColor.withValues(alpha: 0.1);
}

enum AppBannerType { success, warning, danger, info, trial }
