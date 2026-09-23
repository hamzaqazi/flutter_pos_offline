import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
///  USER MANUAL — content model
///
///  A guide is plain data: a title, a category, and a list of
///  [ManualBlock]s. The UI never hard-codes a guide — it renders
///  whatever blocks a guide declares, so adding documentation is a
///  content change, not a UI change.
///
///  Everything is `const`-constructible so the whole manual compiles
///  into the app binary and works fully offline.
/// ═══════════════════════════════════════════════════════════════

/// ── Categories ──
/// Groups guides in the manual hub. Each category doubles as a filter
/// chip and as the accent colour used on that category's guide cards.
enum ManualCategory {
  gettingStarted(
    'Getting Started',
    Icons.rocket_launch_outlined,
    AppColors.seed,
  ),
  selling('Selling', Icons.point_of_sale_outlined, AppColors.warning),
  inventory('Inventory', Icons.inventory_2_outlined, AppColors.accent),
  money('Money & Reports', Icons.insights_outlined, AppColors.violet),
  printing('Receipts & Printing', Icons.print_outlined, AppColors.info),
  data('Data & Backup', Icons.cloud_sync_outlined, AppColors.success),
  security('Security & Plan', Icons.shield_outlined, AppColors.danger),
  support(
    'Help & Troubleshooting',
    Icons.support_agent_outlined,
    AppColors.rose,
  );

  const ManualCategory(this.label, this.icon, this.color);

  /// Human-readable name shown on headers and filter chips.
  final String label;

  /// Icon representing the category.
  final IconData icon;

  /// Accent colour for the category (design-system token, never a raw hex).
  final Color color;
}

/// ── Blocks ──
/// A block is one piece of a guide's body. The renderer switches on the
/// concrete type, so adding a new block type means adding one subclass
/// here plus one case in `manual_article_page.dart`.
sealed class ManualBlock {
  const ManualBlock();
}

/// A plain paragraph of body text.
class ManualParagraph extends ManualBlock {
  const ManualParagraph(this.text);

  final String text;
}

/// An ordered, numbered set of steps — the backbone of most guides.
class ManualSteps extends ManualBlock {
  const ManualSteps(this.steps, {this.title});

  final List<ManualStep> steps;

  /// Optional heading above the steps (e.g. "To make a sale").
  final String? title;
}

/// One numbered step: a short imperative title plus optional detail.
class ManualStep {
  const ManualStep(this.title, {this.detail});

  final String title;

  /// Extra explanation shown under the step title in smaller text.
  final String? detail;
}

/// Visual weight of a [ManualCallout].
enum ManualCalloutKind { tip, note, warning }

/// A highlighted tip / note / warning box.
class ManualCallout extends ManualBlock {
  const ManualCallout(this.kind, this.text);

  final ManualCalloutKind kind;
  final String text;
}

/// A simple bulleted list, for things that aren't ordered steps.
class ManualBullets extends ManualBlock {
  const ManualBullets(this.items);

  final List<String> items;
}

/// A collapsible question & answer, used for "Common questions".
class ManualFaq extends ManualBlock {
  const ManualFaq(this.items);

  final List<ManualFaqItem> items;
}

class ManualFaqItem {
  const ManualFaqItem(this.question, this.answer);

  final String question;
  final String answer;
}

/// A button inside a guide that jumps the user to the feature it
/// describes — this is what makes it a manual rather than a help article.
///
/// Either [tabIndex] (switch a bottom-nav tab) or [route] (push a named
/// route) may be set. [tabIndex] wins if both are provided.
class ManualAction extends ManualBlock {
  const ManualAction(
    this.label, {
    this.route,
    this.tabIndex,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final String? route;
  final int? tabIndex;
  final IconData icon;
}

/// ── Guide ──
/// A single manual entry.
class ManualGuide {
  const ManualGuide({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.icon,
    required this.blocks,
    this.keywords = const [],
    this.relatedIds = const [],
  });

  /// Stable identifier — also the deep-link parameter
  /// (`/manual/article?id=make-a-sale`).
  final String id;

  final String title;

  /// One-line description shown on cards and in search results.
  final String summary;

  final ManualCategory category;

  /// Icon shown on cards and the article header.
  final IconData icon;

  final List<ManualBlock> blocks;

  /// Extra search terms that don't appear in the title or summary
  /// (e.g. "refund" for the returns guide).
  final List<String> keywords;

  /// Ids of guides offered as "Related guides" at the end of the article.
  final List<String> relatedIds;
}
