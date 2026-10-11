import 'package:flutter/material.dart';

class PremiumLicenseBanner extends StatelessWidget {
  const PremiumLicenseBanner({
    required this.status,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'Provide both actionLabel and onAction, or neither.',
       );

  final String status;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(22);

    final base = isDark ? const Color(0xFF171A23) : const Color(0xFFFFFFFF);

    // Lighten the accent on dark surfaces for better readability.
    final foreground = isDark
        ? Color.lerp(accent, Colors.white, 0.45)!
        : accent;

    final titleColor = isDark
        ? const Color(0xFFF5F5FA)
        : const Color(0xFF191B2A);

    final secondaryColor = isDark
        ? const Color(0xFFADB3C4)
        : const Color(0xFF62697C);

    final hasAction = actionLabel != null && onAction != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: base,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  accent.withValues(alpha: isDark ? 0.16 : 0.08),
                  base,
                ),
                base,
              ],
            ),
            border: Border.all(
              color: foreground.withValues(alpha: isDark ? 0.20 : 0.14),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: foreground.withValues(alpha: 0.08),
            highlightColor: foreground.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: foreground.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: foreground.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Icon(icon, size: 25, color: foreground),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(top: 9),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: foreground.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 13),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 19,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: titleColor,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryColor,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (hasAction) ...[
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: foreground.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: onAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? foreground : accent,
                          foregroundColor: isDark
                              ? const Color(0xFF141620)
                              : Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(actionLabel!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
