import 'package:flutter/material.dart';

/// Responsive layout breakpoints.
class Breakpoints {
  /// Phone: width < 600
  static const double phone = 600;

  /// Compact tablet / foldable: 600–840
  static const double tablet = 840;

  /// Full tablet / desktop: > 840
  static const double desktop = 840;
}

/// Utility for responsive layout decisions.
class Responsive {
  final MediaQueryData _mediaQuery;

  Responsive(this._mediaQuery);

  /// Current screen width.
  double get width => _mediaQuery.size.width;

  /// Current screen height.
  double get height => _mediaQuery.size.height;

  /// True if the screen is phone-sized (< 600dp).
  bool get isPhone => width < Breakpoints.phone;

  /// True if the screen is a compact tablet (600–840dp).
  bool get isSmallTablet =>
      width >= Breakpoints.phone && width < Breakpoints.tablet;

  /// True if the screen is a full tablet or desktop (>= 840dp).
  bool get isTablet => width >= Breakpoints.tablet;

  /// True if the screen is any tablet size (>= 600dp).
  bool get isTabletOrLarger => width >= Breakpoints.phone;

  /// Number of grid columns for stat cards.
  int get statGridColumns {
    if (width >= 1200) return 4;
    if (width >= 840) return 3;
    if (width >= 600) return 3;
    return 2;
  }

  /// Number of grid columns for product cards.
  int get productGridColumns {
    if (width >= 1200) return 6;
    if (width >= 840) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  /// Content max width for centered layouts.
  double get contentMaxWidth {
    if (width >= 1200) return 1100;
    if (width >= 840) return 800;
    return width;
  }

  /// Horizontal padding for content.
  double get horizontalPadding {
    if (width >= 1200) return 48;
    if (width >= 840) return 32;
    return 16;
  }

  /// Get [Responsive] from BuildContext.
  static Responsive of(BuildContext context) {
    return Responsive(MediaQuery.of(context));
  }
}

/// Widget that shows different layouts based on screen size.
/// Provides phone, tablet, and desktop variants.
class ResponsiveLayout extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    if (responsive.isTablet) {
      return desktop ?? tablet ?? phone;
    }
    if (responsive.isSmallTablet) {
      return tablet ?? phone;
    }
    return phone;
  }
}
