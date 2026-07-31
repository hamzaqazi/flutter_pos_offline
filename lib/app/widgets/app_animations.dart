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

// ── Page Transitions ──

/// Fade-through page transition for non-tab routes.
/// Usage: GetPage(customTransition: AppPageTransition(), transition: Transition.fadeIn)
Widget fadeThroughTransition(Widget child, Animation<double> animation) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: child,
  );
}

/// Slide-up page transition for non-tab routes.
Widget slideUpTransition(Widget child, Animation<double> animation) {
  final offsetAnimation = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

  final fadeAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOut,
  );

  return SlideTransition(
    position: offsetAnimation,
    child: FadeTransition(opacity: fadeAnimation, child: child),
  );
}

/// Shared axis (horizontal) transition — like Material shared axis.
Widget sharedAxisTransition(Widget child, Animation<double> animation) {
  final offsetAnimation = Tween<Offset>(
    begin: const Offset(0.05, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

  final fadeAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOut,
  );

  return SlideTransition(
    position: offsetAnimation,
    child: FadeTransition(opacity: fadeAnimation, child: child),
  );
}

// ── Delay wrapper ──

class _DelayAnimation extends StatefulWidget {
  const _DelayAnimation({required this.delay, required this.child});

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

// ═══════════════════════════════════════════════════════════════
//  MICRO-INTERACTIONS — Tap scale, press feedback, etc.
// ═══════════════════════════════════════════════════════════════

/// A tap-scale wrapper — scales down slightly on press and springs back.
/// Use for cards, tiles, and interactive elements that need tactile feedback.
class TapScale extends StatefulWidget {
  const TapScale({
    super.key,
    required this.child,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final double scale;
  final Duration duration;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: Duration(
        milliseconds: (widget.duration.inMilliseconds * 0.6).round(),
      ),
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _animation, child: widget.child),
    );
  }
}

/// An animated container that fades in its child with a subtle slide.
/// Use for cards and tiles appearing in lists.
class AnimatedEntry extends ImplicitlyAnimatedWidget {
  const AnimatedEntry({
    super.key,
    required this.child,
    this.animate = true,
    super.duration = AppDuration.normal,
    super.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final bool animate;

  @override
  ImplicitlyAnimatedWidgetState<AnimatedEntry> createState() =>
      _AnimatedEntryState();
}

class _AnimatedEntryState extends ImplicitlyAnimatedWidgetState<AnimatedEntry> {
  DoubleTween? _opacityTween;
  Tween<Offset>? _offsetTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _opacityTween =
        visitor(
              _opacityTween,
              widget.animate ? 1.0 : 1.0,
              (dynamic value) => DoubleTween(begin: value as double? ?? 0.0),
            )
            as DoubleTween?;
    _offsetTween =
        visitor(
              _offsetTween,
              widget.animate ? Offset.zero : Offset.zero,
              (dynamic value) => Tween<Offset>(
                begin: value as Offset? ?? const Offset(0, 0.03),
              ),
            )
            as Tween<Offset>?;
  }

  @override
  Widget build(BuildContext context) {
    final animation = this.animation;
    final opacity = _opacityTween?.evaluate(animation) ?? 1.0;
    final offset = _offsetTween?.evaluate(animation) ?? Offset.zero;

    return Transform.translate(
      offset: Offset(offset.dx * 20, offset.dy * 20),
      child: Opacity(opacity: opacity, child: widget.child),
    );
  }
}

class DoubleTween extends Tween<double> {
  DoubleTween({double? begin, double? end}) : super(begin: begin, end: end);
}
