import 'package:ad_shop_pos/app/routes/app_routes.dart';
import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const _completeKey = 'onboarding_complete';

  static bool get isComplete =>
      Hive.box('settings').get(_completeKey, defaultValue: false) as bool;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  late final AnimationController _gradientController;
  int _page = 0;

  static const _slides = [
    _OnboardingSlide(
      eyebrow: 'Your counter, simplified',
      title: 'Sell',
      animatedWords: ['faster', 'smarter', 'easier'],
      description:
          'Manage products, carts, sales, and receipts in a few quick taps.',
      icon: Icons.shopping_bag_outlined,
      accent: AppColors.info,
      gradientPartner: Colors.blueAccent,
      highlights: ['Quick checkout', 'Clear receipts'],
    ),
    _OnboardingSlide(
      eyebrow: 'Stay in control',
      title: 'Manage',
      animatedWords: ['inventory', 'stock', 'products', 'items'],
      description:
          'Keep products and stock organized, with low-stock items easy to spot.',
      icon: Icons.inventory_2_outlined,
      accent: AppColors.warning,
      gradientPartner: Colors.lime,
      highlights: ['Stock at a glance', 'Low-stock alerts'],
    ),
    _OnboardingSlide(
      eyebrow: 'Make better decisions',
      title: 'Know your',
      animatedWords: ['sales', 'profit', 'expense', 'reports'],
      description:
          'See sales, profit, expenses, and reports without digging through spreadsheets.',
      icon: Icons.insights_outlined,
      accent: AppColors.violet,
      gradientPartner: AppColors.info,
      highlights: ['Daily numbers', 'Simple reports'],
    ),
    _OnboardingSlide(
      eyebrow: 'Built for real shop days',
      title: 'Offline',
      animatedWords: ['first', 'always', 'ready', 'anytime'],
      description:
          'Keep selling without internet. Your data stays on this device, with sync and backup available when you are online.',
      icon: Icons.cloud_off_outlined,
      accent: AppColors.seed,
      gradientPartner: AppColors.accentLight,
      highlights: ['Works without internet', 'Backup when online'],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  Future<void> _finish() async {
    await Hive.box('settings').put(OnboardingPage._completeKey, true);
    if (mounted) Get.offAllNamed(_startRoute());
  }

  /// Where to land once onboarding is done, based on the current license /
  /// trial state rather than assuming a fresh install. Onboarding can
  /// reappear after a backup restore, so an activated shop (or one on a free
  /// trial) must go back into the app — only a genuinely un-activated device
  /// is sent to activation.
  String _startRoute() {
    if (LicenseService.isTrialActive && !LicenseService.isActivated) {
      return LicenseService.isPinEnabled ? Routes.pinLock : Routes.dashboard;
    }
    if (!LicenseService.isActivated) {
      return Routes.activation;
    }
    return LicenseService.isPinEnabled ? Routes.pinLock : Routes.dashboard;
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: AppDuration.normal,
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_page > 0) {
      _pageController.previousPage(
        duration: AppDuration.normal,
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _skip() => _finish();

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    final baseTheme = Theme.of(context);
    final onboardingTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
    );
    final cs = onboardingTheme.colorScheme;

    return Theme(
      data: onboardingTheme,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            final slide = _slides[_page];
            final value = _gradientController.value;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    slide.accent.withValues(alpha: 0.18),
                    slide.gradientPartner.withValues(alpha: 0.1),
                    onboardingTheme.colorScheme.surface,
                  ],
                  begin: Alignment(-1 + value * 0.6, -1),
                  end: Alignment(1, 1 - value * 0.6),
                ),
              ),
              child: child,
            );
          },
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.sm,
                    AppSpacing.xxl,
                    0,
                  ),
                  child: Row(
                    children: [
                      const _BrandMark(),
                      const Spacer(),
                      TextButton(onPressed: _skip, child: const Text('Skip')),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (value) => setState(() => _page = value),
                    itemBuilder: (context, index) =>
                        _SlideView(slide: _slides[index]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    0,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (index) => AnimatedContainer(
                            duration: AppDuration.fast,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: index == _page ? 24 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: index == _page
                                  ? cs.primary
                                  : cs.outlineVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          if (_page > 0)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _back,
                                icon: const Icon(Icons.arrow_back_rounded),
                                label: const Text('Back'),
                              ),
                            ),
                          if (_page > 0) const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: _page > 0 ? 2 : 1,
                            child: FilledButton.icon(
                              onPressed: _next,
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(isLast ? 'Get Started' : 'Next'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Image.asset(
          'lib/assets/images/cn_pos_logo_rm.png',
          width: 58,
          height: 58,
          color: cs.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Codynest POS',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 580;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: compact ? AppSpacing.lg : AppSpacing.huge),
                _Illustration(slide: slide),
                SizedBox(height: compact ? AppSpacing.xl : AppSpacing.xxxl),
                Text(
                  slide.eyebrow.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: slide.accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 48,
                  child: _AnimatedSlideTitle(
                    slide: slide,
                    theme: theme,
                    colorScheme: cs,
                  ),
                  //  AnimatedTextKit(
                  //   key: ValueKey(slide.title),
                  //   isRepeatingAnimation: true,
                  //   animatedTexts: [
                  //     FadeAnimatedText(
                  //       slide.title,
                  //       textAlign: TextAlign.center,
                  //       duration: const Duration(milliseconds: 650),
                  //       textStyle: theme.textTheme.displaySmall?.copyWith(
                  //         color: cs.onSurface,
                  //         fontWeight: FontWeight.w900,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Text(
                    slide.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: slide.highlights
                      .map(
                        (text) => Chip(
                          avatar: Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: slide.accent,
                          ),
                          label: Text(text),
                          side: BorderSide.none,
                          backgroundColor: slide.accent.withValues(alpha: 0.1),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: compact ? AppSpacing.lg : AppSpacing.huge),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedSlideTitle extends StatelessWidget {
  const _AnimatedSlideTitle({
    required this.slide,
    required this.theme,
    required this.colorScheme,
  });

  final _OnboardingSlide slide;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final titleStyle = theme.textTheme.displaySmall?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w900,
    );

    // Normal title
    if (slide.animatedWords.isEmpty) {
      return Text(slide.title, textAlign: TextAlign.center, style: titleStyle);
    }

    // Animated title
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${slide.title} ', style: titleStyle),
        DefaultTextStyle(
          style: titleStyle!.copyWith(color: slide.accent),
          child: AnimatedTextKit(
            repeatForever: true,
            animatedTexts: slide.animatedWords
                .map(
                  (word) => TyperAnimatedText(
                    word,
                    speed: const Duration(milliseconds: 150),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        color: slide.accent.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 122,
          height: 122,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: slide.accent.withValues(alpha: 0.18)),
            boxShadow: AppElevation.shadow(4),
          ),
          child: Icon(slide.icon, size: 58, color: slide.accent),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.gradientPartner,
    required this.highlights,
    this.animatedWords = const [],
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final Color gradientPartner;
  final List<String> highlights;
  final List<String> animatedWords;
}
