import 'package:flutter/material.dart';
import 'package:ad_shop_pos/app/theme/app_theme.dart';

/// A label with an info tooltip icon. Used to explain financial terms.
class TooltipLabel extends StatelessWidget {
  final String label;
  final String tooltip;
  final TextStyle? style;
  final Color? iconColor;

  const TooltipLabel({
    super.key,
    required this.label,
    required this.tooltip,
    this.style,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: tooltip,
          preferBelow: true,
          decoration: BoxDecoration(
            color: cs.inverseSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            color: cs.onInverseSurface,
            fontSize: 13,
            height: 1.4,
          ),
          child: Icon(
            Icons.info_outline,
            size: 16,
            color: iconColor ?? cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// Tooltip definitions for financial terms used across the app.
class FinancialTooltips {
  static const String revenue =
      'Revenue is the total money received from all sales after product discounts are applied. It does not include expenses or refunds.';

  static const String grossProfit =
      'Gross Profit = Revenue minus Cost of Goods Sold (COGS). This is the profit before deducting expenses like rent, salaries, and refunds.';

  static const String netProfit =
      'Net Profit = Gross Profit minus Expenses and Refunds. This is your actual take-home profit after all costs are deducted.';

  static const String netMargin =
      'Net Margin = (Net Profit / Revenue) x 100. Shows what percentage of each rupee of revenue is actual profit.';

  static const String subtotal =
      'Subtotal is the cart total before checkout discount and tax are applied.';

  static const String cogs =
      'COGS (Cost of Goods Sold) is the total purchase price you paid to buy the products that were sold.';

  static const String avgSale =
      'Average Sale = Total Revenue / Number of Transactions. Shows how much a typical customer spends.';

  static const String refunds =
      'Total money returned to customers for returned items.';

  static const String expenses =
      'Total business expenses (rent, salaries, utilities, etc.) in the selected period.';

  static const String lowStock =
      'Products at or below the alert threshold. These may run out soon and need restocking.';

  static const String todaySales =
      'Number of sales transactions completed today.';

  static const String todayRevenue =
      'Total money received from all sales completed today.';

  static const String todayProfit =
      'Profit earned from sales completed today (after discounts and returns).';

  static const String discount =
      'Discount reduces the selling price. Product discount is per-item, checkout discount applies to the whole cart.';

  static const String tax =
      'Tax applied on sales. If inclusive, tax is already in the selling price. If exclusive, tax is added on top.';
}
