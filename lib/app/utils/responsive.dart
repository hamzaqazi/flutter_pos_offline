import 'package:flutter/material.dart';

/// Breakpoints and responsive utilities for adaptive layouts.
class Responsive {
  /// Phone: width < 600
  static const double phone = 600;

  /// Tablet: width >= 600 and < 840
  static const double tablet = 840;

  /// Desktop: width >= 840
  static const double desktop = 840;

  /// Check if the current width is phone-sized.
  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < phone;

  /// Check if the current width is tablet-sized.
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= phone &&
      MediaQuery.of(context).size.width < desktop;

  /// Check if the current width is desktop-sized.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  /// Get the current breakpoint name.
  static String breakpoint(BuildContext context) {
    if (isPhone(context)) return 'phone';
    if (isTablet(context)) return 'tablet';
    return 'desktop';
  }
}

/// Adaptive layout — shows different widgets based on screen width.
/// Phone: shows [phone] widget
/// Tablet: shows [tablet] widget (falls back to [phone] if null)
/// Desktop: shows [desktop] widget (falls back to [tablet] then [phone])
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return desktop ?? tablet ?? phone;
    }
    if (Responsive.isTablet(context)) {
      return tablet ?? phone;
    }
    return phone;
  }
}
