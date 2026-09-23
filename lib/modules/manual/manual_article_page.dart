import 'package:ad_shop_pos/app/routes/app_routes.dart';
import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/launcher.dart';
import 'package:ad_shop_pos/app/widgets/app_widgets.dart';
import 'package:ad_shop_pos/modules/manual/manual_content.dart';
import 'package:ad_shop_pos/modules/manual/manual_controller.dart';
import 'package:ad_shop_pos/modules/manual/manual_model.dart';
import 'package:ad_shop_pos/modules/manual/manual_nav.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders any single guide.
///
/// The guide id arrives as a route parameter:
///   `Get.toNamed(Routes.manualArticle, parameters: {'id': 'add-product'})`
/// (a plain [String] argument is also accepted, so both deep-link styles
/// work). Unknown ids show a friendly "guide not found" state instead of an
/// empty screen.
class ManualArticlePage extends StatefulWidget {
  const ManualArticlePage({super.key});

  @override
  State<ManualArticlePage> createState() => _ManualArticlePageState();
}

class _ManualArticlePageState extends State<ManualArticlePage> {
  ManualGuide? _guide;

  @override
  void initState() {
    super.initState();
    _guide = ManualGuides.byId(_resolveId());

    // Record for the hub's "Recently viewed" list — after the first frame so
    // we never mutate observable state during a build.
    final guide = _guide;
    if (guide != null && Get.isRegistered<ManualController>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Get.find<ManualController>().recordView(guide.id);
      });
    }
  }

  /// Reads the guide id from the route parameters, falling back to the
  /// route arguments.
  String _resolveId() {
    final fromParams = Get.parameters['id'];
    if (fromParams != null && fromParams.isNotEmpty) return fromParams;
    final args = Get.arguments;
    if (args is String && args.isNotEmpty) return args;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final guide = _guide;
    if (guide == null) return const _MissingGuide();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = guide.category.color;

    return Scaffold(
      appBar: AppBar(
        title: DefaultTextStyle.merge(
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 15,
          ),
          child: Text(
            guide.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primaryContainer, cs.surface],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.huge,
          ),
          children: [
            // ── Header ──
            _ArticleHeader(guide: guide),
            const SizedBox(height: AppSpacing.xl),

            // ── Body ──
            ...guide.blocks.map(_buildBlock),

            // ── Related guides ──
            ..._relatedSection(guide),

            // ── Support footer ──
            _SupportFooter(guide: guide),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  Block renderer
  // ────────────────────────────────────────────────────────────

  Widget _buildBlock(ManualBlock block) {
    final theme = Theme.of(context);

    return switch (block) {
      ManualParagraph p => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Text(
          p.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.55,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      ManualSteps s => _StepsBlock(steps: s.steps, title: s.title),
      ManualCallout c => _CalloutBox(kind: c.kind, text: c.text),
      ManualBullets b => _BulletsBlock(items: b.items),
      ManualFaq f => _FaqBlock(items: f.items),
      ManualAction a => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: () => ManualNav.runAction(a),
            icon: Icon(a.icon, size: 18),
            label: Text(a.label),
          ),
        ),
      ),
    };
  }

  // ────────────────────────────────────────────────────────────
  //  Related guides
  // ────────────────────────────────────────────────────────────

  List<Widget> _relatedSection(ManualGuide guide) {
    final related = ManualGuides.related(guide);
    if (related.isEmpty) return const [];

    return [
      const SizedBox(height: AppSpacing.sm),
      const AppSectionHeader(
        title: 'Related guides',
        subtitle: 'You might need these next',
      ),
      const SizedBox(height: AppSpacing.md),
      Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < related.length; i++) ...[
              AppActionTile(
                icon: related[i].icon,
                title: related[i].title,
                subtitle: related[i].summary,
                color: related[i].category.color,
                onTap: () => ManualNav.openGuide(related[i].id),
              ),
              if (i != related.length - 1)
                const Divider(height: 1, indent: 52),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xxl),
    ];
  }
}

// ────────────────────────────────────────────────────────────
//  Header
// ────────────────────────────────────────────────────────────

class _ArticleHeader extends StatelessWidget {
  const _ArticleHeader({required this.guide});

  final ManualGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = guide.category.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(guide.icon, color: color, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      guide.category.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    guide.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          guide.summary,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Steps
// ────────────────────────────────────────────────────────────

class _StepsBlock extends StatelessWidget {
  const _StepsBlock({required this.steps, this.title});

  final List<ManualStep> steps;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == steps.length - 1 ? 0 : AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        if (steps[i].detail != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            steps[i].detail!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Callout
// ────────────────────────────────────────────────────────────

class _CalloutBox extends StatelessWidget {
  const _CalloutBox({required this.kind, required this.text});

  final ManualCalloutKind kind;
  final String text;

  Color get _color {
    switch (kind) {
      case ManualCalloutKind.tip:
        return AppColors.success;
      case ManualCalloutKind.note:
        return AppColors.info;
      case ManualCalloutKind.warning:
        return AppColors.warning;
    }
  }

  IconData get _icon {
    switch (kind) {
      case ManualCalloutKind.tip:
        return Icons.lightbulb_outline_rounded;
      case ManualCalloutKind.note:
        return Icons.info_outline_rounded;
      case ManualCalloutKind.warning:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Bullets
// ────────────────────────────────────────────────────────────

class _BulletsBlock extends StatelessWidget {
  const _BulletsBlock({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  FAQ
// ────────────────────────────────────────────────────────────

class _FaqBlock extends StatelessWidget {
  const _FaqBlock({required this.items});

  final List<ManualFaqItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              ExpansionTile(
                title: Text(
                  items[i].question,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                childrenPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  Text(
                    items[i].answer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (i != items.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Support footer
// ────────────────────────────────────────────────────────────

class _SupportFooter extends StatelessWidget {
  const _SupportFooter({required this.guide});

  final ManualGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              AppActionTile(
                icon: Icons.support_agent_outlined,
                title: 'Still stuck?',
                subtitle: 'Chat with support on WhatsApp',
                color: AppColors.success,
                onTap: () => Launcher.openWhatsApp(
                  '923153507075',
                  'Hi, I need help with Codynest POS. '
                      'I was reading the "${guide.title}" guide.',
                ),
              ),
              const Divider(height: 1, indent: 52),
              AppActionTile(
                icon: Icons.menu_book_outlined,
                title: 'Back to the manual',
                subtitle: 'Browse all guides',
                color: AppColors.seed,
                onTap: ManualNav.openHub,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            'User manual for version ${ManualGuides.version}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Missing guide
// ────────────────────────────────────────────────────────────

class _MissingGuide extends StatelessWidget {
  const _MissingGuide();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Manual')),
      body: AppEmptyState(
        icon: Icons.help_outline_rounded,
        title: 'Guide not found',
        subtitle:
            'This guide may have been renamed or removed in a newer version '
            'of the app.',
        actionLabel: 'Open the manual',
        onAction: () => Get.offNamed(Routes.manual),
      ),
    );
  }
}
