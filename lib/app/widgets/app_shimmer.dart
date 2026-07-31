import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Shimmer loading placeholder — shows a subtle animated gradient
/// over placeholder shapes while content is loading.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ??
        (isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.3)
            : AppColors.surfaceLight.withValues(alpha: 0.6));
    final highlight = widget.highlightColor ??
        (isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.8));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A rectangular shimmer placeholder block.
class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A circular shimmer placeholder.
class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    );
  }
}

/// A stat-card-shaped shimmer placeholder.
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBlock(width: 32, height: 32, borderRadius: 8),
              SizedBox(height: AppSpacing.sm),
              ShimmerBlock(width: 60, height: 20),
              SizedBox(height: 4),
              ShimmerBlock(width: 80, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}


/// A list-tile-shaped shimmer placeholder.
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ShimmerCircle(size: 44),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBlock(width: 140, height: 14),
                    SizedBox(height: 6),
                    ShimmerBlock(width: 100, height: 10),
                  ],
                ),
              ),
              ShimmerBlock(width: 60, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// A product-card-shaped shimmer placeholder for grids.
class ShimmerProductCard extends StatelessWidget {
  const ShimmerProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ShimmerBlock(
                height: double.infinity,
                borderRadius: 0,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(width: 80, height: 12),
                  SizedBox(height: 4),
                  ShimmerBlock(width: 60, height: 16),
                  SizedBox(height: 4),
                  ShimmerBlock(width: 40, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A banner-shaped shimmer placeholder for summary banners.
class ShimmerBanner extends StatelessWidget {
  const ShimmerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  ShimmerBlock(width: 60, height: 18),
                  SizedBox(height: 4),
                  ShimmerBlock(width: 40, height: 10),
                ],
              ),
              Column(
                children: [
                  ShimmerBlock(width: 60, height: 18),
                  SizedBox(height: 4),
                  ShimmerBlock(width: 40, height: 10),
                ],
              ),
              Column(
                children: [
                  ShimmerBlock(width: 60, height: 18),
                  SizedBox(height: 4),
                  ShimmerBlock(width: 40, height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A page-level shimmer loading skeleton — shows a list of shimmer tiles.
class ShimmerListPage extends StatelessWidget {
  const ShimmerListPage({super.key, this.tileCount = 6});

  final int tileCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: tileCount,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: ShimmerListTile(),
      ),
    );
  }
}

/// A grid-level shimmer loading skeleton for product grids.
class ShimmerGridPage extends StatelessWidget {
  const ShimmerGridPage({super.key, this.tileCount = 6});

  final int tileCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: tileCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemBuilder: (_, __) => const ShimmerProductCard(),
    );
  }
}
