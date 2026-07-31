import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Status badge — compact label with semantic color.
/// Used for plan types, active/inactive, trial status, etc.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.color,
    this.type = AppBadgeType.neutral,
    this.icon,
  });

  final String label;
  final Color? color;
  final AppBadgeType type;
  final IconData? icon;

  /// Convenience constructors
  factory AppBadge.success({required String label, IconData? icon}) =>
      AppBadge(label: label, type: AppBadgeType.success, icon: icon);
  factory AppBadge.warning({required String label, IconData? icon}) =>
      AppBadge(label: label, type: AppBadgeType.warning, icon: icon);
  factory AppBadge.danger({required String label, IconData? icon}) =>
      AppBadge(label: label, type: AppBadgeType.danger, icon: icon);
  factory AppBadge.info({required String label, IconData? icon}) =>
      AppBadge(label: label, type: AppBadgeType.info, icon: icon);
  factory AppBadge.trial({required String label, IconData? icon}) =>
      AppBadge(label: label, type: AppBadgeType.trial, icon: icon);

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? _typeColor;
    final bgColor = resolvedColor.withValues(alpha: 0.1);
    final fgColor = resolvedColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fgColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Color get _typeColor {
    switch (type) {
      case AppBadgeType.success:
        return AppColors.success;
      case AppBadgeType.warning:
        return AppColors.warning;
      case AppBadgeType.danger:
        return AppColors.danger;
      case AppBadgeType.info:
        return AppColors.info;
      case AppBadgeType.trial:
        return AppColors.seed;
      case AppBadgeType.neutral:
        return AppColors.textSecondary;
    }
  }
}

enum AppBadgeType { success, warning, danger, info, trial, neutral }
