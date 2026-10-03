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

/// The manual hub — search, quick-start cards and guides grouped by topic.
///
/// Every guide lives in `manual_content.dart`; this screen only decides how
/// to present them. Adding a guide never requires touching this file.
class ManualHomePage extends GetView<ManualController> {
  const ManualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: DefaultTextStyle.merge(
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 15,
          ),
          child: const Text('User Manual'),
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
        child: Obx(() {
          final isSearching = controller.isSearching;
          final guides = controller.visibleGuides;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.huge,
            ),
            children: [
              // ── Search ──
              AppSearchBar(
                controller: controller.searchController,
                hint: 'Search the manual...',
                onChanged: controller.onQueryChanged,
                onClear: controller.clearSearch,
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Search results, or the browse view ──
              if (isSearching)
                ..._searchResults(guides)
              else
                ..._browse(),
            ],
          );
        }),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  Search results
  // ────────────────────────────────────────────────────────────

  List<Widget> _searchResults(List<ManualGuide> guides) {
    if (guides.isEmpty) {
      return [
        AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No guides found',
          subtitle:
              'Try a different word — for example "refund", "printer", '
              '"stock" or "backup".',
          actionLabel: 'Clear search',
          onAction: controller.clearSearch,
        ),
      ];
    }

    final count = guides.length;
    return [
      AppSectionHeader(
        title: '$count ${count == 1 ? 'result' : 'results'}',
        subtitle: 'for "${controller.query.value.trim()}"',
      ),
      const SizedBox(height: AppSpacing.md),
      _GuideListCard(guides: guides),
    ];
  }

  // ────────────────────────────────────────────────────────────
  //  Browse view
  // ────────────────────────────────────────────────────────────

  List<Widget> _browse() {
    final theme = Get.theme;
    final quickStart = ManualGuides.quickStart();
    final recent = controller.recentGuides;

    final children = <Widget>[
      // ── Quick start ──
      const AppSectionHeader(
        title: 'Quick start',
        subtitle: 'The essentials, in order',
      ),
      const SizedBox(height: AppSpacing.md),
      SizedBox(
        height: 196,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: quickStart.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, index) => AppAnimations.staggerItem(
            index: index,
            child: _QuickCard(guide: quickStart[index]),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xxl),
    ];

    // ── Recently viewed (only once something has been opened) ──
    if (recent.isNotEmpty) {
      children.addAll([
        const AppSectionHeader(
          title: 'Recently viewed',
          subtitle: 'Pick up where you left off',
        ),
        const SizedBox(height: AppSpacing.md),
        _GuideListCard(guides: recent),
        const SizedBox(height: AppSpacing.xxl),
      ]);
    }

    // ── Browse by topic ──
    children.add(
      const AppSectionHeader(
        title: 'Browse by topic',
        subtitle: 'Every feature, explained',
      ),
    );
    children.add(const SizedBox(height: AppSpacing.md));

    var index = 0;
    for (final category in ManualCategory.values) {
      final guides = ManualGuides.inCategory(category);
      if (guides.isEmpty) continue;
      children.add(
        AppAnimations.staggerItem(
          index: index++,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: _CategorySection(category: category, guides: guides),
          ),
        ),
      );
    }

    // ── Support + version ──
    children.addAll([
      _SupportCard(),
      const SizedBox(height: AppSpacing.lg),
      Center(
        child: Text(
          'User manual for version ${ManualGuides.version}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ),
    ]);

    return children;
  }
}

// ────────────────────────────────────────────────────────────
//  Quick-start card
// ────────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.guide});

  final ManualGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = guide.category.color;

    return SizedBox(
      width: 200,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => ManualNav.openGuide(guide.id),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(guide.icon, color: color, size: 22),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  guide.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Expanded so the card can never overflow its fixed height —
                // the summary absorbs whatever space is left.
                Expanded(
                  child: Text(
                    guide.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

// ────────────────────────────────────────────────────────────
//  Category section
// ────────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.guides});

  final ManualCategory category;
  final List<ManualGuide> guides;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(category.icon, size: 18, color: category.color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                category.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${guides.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _GuideListCard(guides: guides, accent: category.color),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Guide list card — the grouped-list row style used across the app
// ────────────────────────────────────────────────────────────

class _GuideListCard extends StatelessWidget {
  const _GuideListCard({required this.guides, this.accent});

  final List<ManualGuide> guides;

  /// Colour for the row icons; falls back to each guide's own category.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < guides.length; i++) ...[
            AppActionTile(
              icon: guides[i].icon,
              title: guides[i].title,
              subtitle: guides[i].summary,
              color: accent ?? guides[i].category.color,
              onTap: () => ManualNav.openGuide(guides[i].id),
            ),
            if (i != guides.length - 1)
              const Divider(height: 1, indent: 52),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Support card
// ────────────────────────────────────────────────────────────

class _SupportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          AppActionTile(
            icon: Icons.support_agent_outlined,
            title: 'Still need help?',
            subtitle: 'Chat with the support team on WhatsApp',
            color: AppColors.success,
            onTap: () => Launcher.openWhatsApp(
              '923153507075',
              'Hi, I need help with Codynest POS',
            ),
          ),
          const Divider(height: 1, indent: 52),
          AppActionTile(
            icon: Icons.build_outlined,
            title: 'Troubleshooting',
            subtitle: 'Fixes for the most common problems',
            color: AppColors.warning,
            onTap: () => ManualNav.openGuide('troubleshooting'),
          ),
        ],
      ),
    );
  }
}
