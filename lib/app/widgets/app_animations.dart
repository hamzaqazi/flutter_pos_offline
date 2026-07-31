import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Reusable animation utilities for consistent UI transitions.
///
/// Usage:
///   AppAnimations.fadeIn(child: MyWidget())
///   AppAnimations.staggerItem(index: 2, child: MyWidget())
class AppAnimations {
  AppAnimations._();

  // ── Fade In ──

  /// Fade-in animation with optional delay.
  static Widget fadeIn({
    required Widget child,
    Duration duration = AppDuration.normal,
    Duration delay = Duration.zero,
    double begin = 0.0,
  }) {
    return _DelayAnimation(
      delay: delay,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: begin, end: 1.0),
        duration: duration,
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(opacity: value, child: child);
        },
        child: child,
      ),
    );
  }

  // ── Slide Up ──

  /// Slide-up animation with fade.
  static Widget slideUp({
    required Widget child,
    Duration duration = AppDuration.normal,
    Duration delay = Duration.zero,
    double offsetY = 24.0,
  }) {
    return _DelayAnimation(
      delay: delay,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(begin: Offset(0, offsetY), end: Offset.zero),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, offset, child) {
          return Transform.translate(
            offset: offset,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: duration,
              curve: Curves.easeOut,
              builder: (context, opacity, child) {
                return Opacity(opacity: opacity, child: child);
              },
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }

  // ── Scale In ──

  /// Scale-in animation with fade.
  static Widget scaleIn({
    required Widget child,
    Duration duration = AppDuration.normal,
    Duration delay = Duration.zero,
    double beginScale = 0.9,
  }) {
    return _DelayAnimation(
      delay: delay,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: beginScale, end: 1.0),
        duration: duration,
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: duration,
          curve: Curves.easeOut,
          builder: (context, opacity, child) {
            return Opacity(opacity: opacity, child: child);
          },
          child: child,
        ),
      ),
    );
  }

  // ── Stagger ──

  /// Stagger animation for list items — each item gets a delay based on its index.
  /// Use in a list of items to create a cascading entrance effect.
  static Widget staggerItem({
    required int index,
    required Widget child,
    Duration staggerDuration = const Duration(milliseconds: 60),
    Duration itemDuration = AppDuration.normal,
  }) {
    return slideUp(
      child: child,
      duration: itemDuration,
      delay: staggerDuration * index,
    );
  }

  // ── Stagger Grid ──

  /// Wrap a list of widgets with stagger animation.
  static List<Widget> staggerList({
    required List<Widget> children,
    Duration staggerDuration = const Duration(milliseconds: 60),
    Duration itemDuration = AppDuration.normal,
  }) {
    return children.asMap().entries.map((entry) {
      return staggerItem(
        index: entry.key,
        child: entry.value,
        staggerDuration: staggerDuration,
        itemDuration: itemDuration,
      );
    }).toList();
  }
}

// ── Delay wrapper ──

class _DelayAnimation extends StatefulWidget {
  const _DelayAnimation({
    required this.delay,
    required this.child,
  });

  final Duration delay;
  final Widget child;

  @override
  State<_DelayAnimation> createState() => _DelayAnimationState();
}

class _DelayAnimationState extends State<_DelayAnimation> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _visible = true;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return widget.child;
  }
}
