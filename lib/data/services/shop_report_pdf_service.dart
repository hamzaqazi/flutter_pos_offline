import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../app/utils/formatters.dart';
import '../models/shop_settings_model.dart';
import 'settings_service.dart';

/// A top-selling product row in the shop report.
class ShopTopProduct {
  final String name;
  final String category;
  final int quantity;
  final double revenue;
  final double profit;

  const ShopTopProduct({
    required this.name,
    required this.category,
    required this.quantity,
    required this.revenue,
    required this.profit,
  });
}

/// A category summary row in the shop report.
class ShopCategory {
  final String name;
  final int quantity;
  final double revenue;
  final double profit;

  const ShopCategory({
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.profit,
  });
}

/// An expense-by-category row in the shop report.
class ShopExpenseLine {
  final String category;
  final double amount;

  const ShopExpenseLine({required this.category, required this.amount});
}

/// Everything the report PDF needs, gathered by [ReportsController].
class ShopReportData {
  final DateTime start;
  final DateTime end;
  final String rangeLabel;

  // Financial summary.
  final double revenue;
  final double grossProfit;
  final double discounts;
  final double tax;
  final double cogs;
  final double totalExpenses;
  final double netProfit;
  final double netMargin;

  // Sales activity.
  final int transactions;
  final int itemsSold;
  final double averageTransaction;
  final double margin;

  // Returns & refunds.
  final double refunds;
  final int returnTransactions;
  final double profitReversed;

  // Breakdowns.
  final List<ShopCategory> categories;
  final List<ShopTopProduct> topProducts;
  final List<ShopExpenseLine> expenses;

  // Inventory snapshot.
  final double inventoryRetailValue;
  final double inventoryCostValue;
  final double inventoryPotentialProfit;
  final int stockUnits;
  final int lowStockCount;
  final int outOfStockCount;

  const ShopReportData({
    required this.start,
    required this.end,
    required this.rangeLabel,
    required this.revenue,
    required this.grossProfit,
    required this.discounts,
    required this.tax,
    required this.cogs,
    required this.totalExpenses,
    required this.netProfit,
    required this.netMargin,
    required this.transactions,
    required this.itemsSold,
    required this.averageTransaction,
    required this.margin,
    required this.refunds,
    required this.returnTransactions,
    required this.profitReversed,
    required this.categories,
    required this.topProducts,
    required this.expenses,
    required this.inventoryRetailValue,
    required this.inventoryCostValue,
    required this.inventoryPotentialProfit,
    required this.stockUnits,
    required this.lowStockCount,
    required this.outOfStockCount,
  });
}

/// Builds a beautiful, multi-section A4 shop report PDF.
///
/// Layout mirrors the emerald design language of the invoice PDF: a
/// colored header band, KPI cards, a highlighted net-profit line, and
/// zebra-striped tables for categories / products / expenses.
class ShopReportPdfService {
  // Palette (mirrors AppColors / the invoice PDF).
  static const _emerald = PdfColor.fromInt(0xFF10B981);
  static const _emeraldDark = PdfColor.fromInt(0xFF064E3B);
  static const _emeraldBg = PdfColor.fromInt(0xFFECFDF5);
  static const _ink = PdfColor.fromInt(0xFF111827);
  static const _grey = PdfColor.fromInt(0xFF6B7280);
  static const _lineGrey = PdfColor.fromInt(0xFFE5E7EB);
  static const _zebra = PdfColor.fromInt(0xFFF8FAFC);
  static const _red = PdfColor.fromInt(0xFFDC2626);
  static const _white70 = PdfColor.fromInt(0xB3FFFFFF);

  static String _money(double v) => Formatters.currency(v);

  static String _trunc(String s, int n) =>
      s.length > n ? '${s.substring(0, n)}…' : s;

  static Future<Uint8List> generate(ShopReportData d) async {
    final settings = SettingsService.getSettings();
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: 30,
          marginRight: 30,
          marginTop: 14,
          marginBottom: 44,
        ),
        header: (context) =>
            context.pageNumber == 1 ? _header(d, settings) : _slimHeader(d),
        footer: (context) =>
            _footer(context.pageNumber, context.pagesCount),
        build: (context) => [
          _kpiGrid(d),
          const pw.SizedBox(height: 18),
          _section('Financial summary', _financialSummary(d)),
          const pw.SizedBox(height: 18),
          _section('Sales by category', _categoryTable(d.categories)),
          const pw.SizedBox(height: 18),
          _section('Top products', _topProductsTable(d.topProducts)),
          const pw.SizedBox(height: 18),
          _section('Expenses by category', _expenses(d)),
          const pw.SizedBox(height: 18),
          _section('Returns & refunds', _returns(d)),
          const pw.SizedBox(height: 18),
          _section('Inventory snapshot', _inventory(d)),
        ],
      ),
    );
    return pdf.save();
  }

  // ── Header / footer ──

  static pw.Widget _header(ShopReportData d, ShopSettingsModel s) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: pw.BoxDecoration(
        color: _emeraldDark,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                s.shopName.isEmpty ? 'My Shop' : s.shopName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.white,
                  letterSpacing: 0.4,
                ),
              ),
              if (s.address.isNotEmpty) ...[
                const pw.SizedBox(height: 3),
                pw.Text(_trunc(s.address, 64),
                    style: const pw.TextStyle(
                        fontSize: 8.5, color: _white70)),
              ],
              if (s.phone.isNotEmpty)
                pw.Text(s.phone,
                    style:
                        const pw.TextStyle(fontSize: 8.5, color: _white70)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('BUSINESS REPORT',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _emeraldBg,
                    letterSpacing: 2,
                  )),
              const pw.SizedBox(height: 5),
              pw.Text(
                '${Formatters.dateShort(d.start)} – '
                '${Formatters.dateShort(d.end)}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.white,
                ),
              ),
              const pw.SizedBox(height: 2),
              pw.Text(d.rangeLabel,
                  style: const pw.TextStyle(fontSize: 8, color: _white70)),
              const pw.SizedBox(height: 2),
              pw.Text(
                'Generated '
                '${Formatters.dateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 7, color: _white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _slimHeader(ShopReportData d) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _emeraldDark,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Business report',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.white,
                  letterSpacing: 1)),
          pw.Text(
            '${Formatters.dateShort(d.start)} – '
            '${Formatters.dateShort(d.end)}',
            style: const pw.TextStyle(fontSize: 8.5, color: _white70),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(int page, int total) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(0, 8, 0, 0),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _lineGrey, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Codynest POS · '
            '${Formatters.dateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 7.5, color: _grey),
          ),
          pw.Text('Page $page of $total',
              style: const pw.TextStyle(fontSize: 7.5, color: _grey)),
        ],
      ),
    );
  }

  // ── Section scaffolding ──

  static pw.Widget _section(String title, pw.Widget body) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 20,
              height: 3,
              decoration: const pw.BoxDecoration(color: _emerald),
            ),
            const pw.SizedBox(width: 8),
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const pw.SizedBox(height: 10),
        body,
      ],
    );
  }

  /// A label-left / value-right line with a hairline underneath.
  static pw.Widget _kv(String label, String value, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _lineGrey, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 9, color: _grey)),
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: color ?? _ink,
              )),
        ],
      ),
    );
  }

  static pw.Widget _kpi(String label, String value, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: pw.BoxDecoration(
        color: _emeraldBg,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _lineGrey, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: _grey,
              letterSpacing: 0.4,
            ),
          ),
          const pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: color ?? _ink,
              )),
        ],
      ),
    );
  }

  static pw.Widget _kpiRow(pw.Widget a, pw.Widget b) {
    return pw.Row(children: [
      pw.Expanded(child: a),
      const pw.SizedBox(width: 12),
      pw.Expanded(child: b),
    ]);
  }

  static pw.Widget _kpiGrid(ShopReportData d) {
    final neg = d.netProfit < 0;
    return pw.Column(children: [
      _kpiRow(
        _kpi('Revenue', _money(d.revenue)),
        _kpi('Net profit', _money(d.netProfit),
            color: neg ? _red : _emeraldDark),
      ),
      const pw.SizedBox(height: 10),
      _kpiRow(
        _kpi('Gross profit', _money(d.grossProfit)),
        _kpi('Expenses', _money(d.totalExpenses), color: _red),
      ),
      const pw.SizedBox(height: 10),
      _kpiRow(
        _kpi('Transactions', '${d.transactions}'),
        _kpi('Items sold', '${d.itemsSold}'),
      ),
      const pw.SizedBox(height: 10),
      _kpiRow(
        _kpi('Net margin', '${d.netMargin.toStringAsFixed(1)}%'),
        _kpi('Avg. order', _money(d.averageTransaction)),
      ),
    ]);
  }

  // ── Tables (flexible left column + fixed right columns) ────

  static pw.TextStyle _cellStyle(bool header, {bool first = false}) {
    return pw.TextStyle(
      fontSize: header ? 8.0 : 8.5,
      fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: header ? PdfColor.white : (first ? _ink : _grey),
    );
  }

  /// A table row. [label] is the flexible left column; [values] are
  /// right-aligned fixed-width columns of [widths] pt each.
  static pw.Widget _trow({
    required String label,
    required List<String> values,
    required List<double> widths,
    required bool header,
    bool zebra = false,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: header ? _emeraldDark : (zebra ? _zebra : PdfColor.white),
        border: header
            ? null
            : const pw.Border(
                bottom: pw.BorderSide(color: _lineGrey, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(_trunc(label, 40),
                style: _cellStyle(header, first: true)),
          ),
          for (var i = 0; i < values.length; i++)
            pw.SizedBox(
              width: widths[i],
              child: pw.Text(
                _trunc(values[i], 16),
                textAlign: pw.TextAlign.right,
                style: _cellStyle(header),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _empty(String msg) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(msg,
          style: const pw.TextStyle(fontSize: 8.5, color: _grey)),
    );
  }

  static pw.Widget _categoryTable(List<ShopCategory> cats) {
    if (cats.isEmpty) return _empty('No sales in this period.');
    const widths = [44.0, 86.0, 82.0];
    return pw.Column(children: [
      _trow(
        label: 'Category',
        values: ['Qty', 'Revenue', 'Profit'],
        widths: widths,
        header: true,
      ),
      for (var i = 0; i < cats.length; i++)
        _trow(
          label: cats[i].name,
          values: [
            '${cats[i].quantity}',
            _money(cats[i].revenue),
            _money(cats[i].profit),
          ],
          widths: widths,
          zebra: i.isOdd,
        ),
    ]);
  }

  static pw.Widget _topProductsTable(List<ShopTopProduct> prods) {
    if (prods.isEmpty) return _empty('No items sold in this period.');
    const widths = [44.0, 86.0, 82.0];
    final rows = prods.length > 10 ? prods.sublist(0, 10) : prods;
    return pw.Column(children: [
      _trow(
        label: 'Product',
        values: ['Qty', 'Revenue', 'Profit'],
        widths: widths,
        header: true,
      ),
      for (var i = 0; i < rows.length; i++)
        _trow(
          label: rows[i].name,
          values: [
            '${rows[i].quantity}',
            _money(rows[i].revenue),
            _money(rows[i].profit),
          ],
          widths: widths,
          zebra: i.isOdd,
        ),
    ]);
  }

  static pw.Widget _expenses(ShopReportData d) {
    if (d.expenses.isEmpty) return _empty('No expenses in this period.');
    final max = d.expenses.fold<double>(
      0,
      (m, e) => e.amount > m ? e.amount : m,
    );
    return pw.Column(children: [
      for (final e in d.expenses)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 9),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(_trunc(e.category, 44),
                      style: const pw.TextStyle(fontSize: 9, color: _ink)),
                  pw.Text(
                    _money(e.amount),
                    style: const pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              const pw.SizedBox(height: 4),
              pw.Container(
                height: 4,
                width: max > 0 ? (e.amount / max) * 330 : 0.0,
                decoration: const pw.BoxDecoration(
                  color: _emerald,
                  borderRadius: pw.BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
    ]);
  }

  // ── Simple sections ──

  static pw.Widget _financialSummary(ShopReportData d) {
    final neg = d.netProfit < 0;
    return pw.Column(children: [
      _kv('Gross revenue', _money(d.revenue)),
      _kv('Discounts', '-${_money(d.discounts)}', color: _red),
      _kv('Tax (net of refunds)', _money(d.tax)),
      _kv('Cost of goods sold', _money(d.cogs)),
      _kv('Gross profit', _money(d.grossProfit)),
      _kv('Refunds & returns', '-${_money(d.refunds)}', color: _red),
      _kv('Expenses', '-${_money(d.totalExpenses)}', color: _red),
      const pw.SizedBox(height: 12),
      pw.Container(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: pw.BoxDecoration(
          color: _emeraldBg,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: _emerald, width: 1),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'NET PROFIT',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _emeraldDark,
                letterSpacing: 0.5,
              ),
            ),
            pw.Text(
              _money(d.netProfit),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: neg ? _red : _emeraldDark,
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  static pw.Widget _returns(ShopReportData d) {
    return pw.Column(children: [
      _kv('Total refunds', _money(d.refunds), color: _red),
      _kv('Return transactions', '${d.returnTransactions}'),
      _kv('Profit reversed', _money(d.profitReversed), color: _red),
    ]);
  }

  static pw.Widget _inventory(ShopReportData d) {
    return pw.Column(children: [
      _kpiRow(
        _kpi('Retail value', _money(d.inventoryRetailValue)),
        _kpi('Cost value', _money(d.inventoryCostValue)),
      ),
      const pw.SizedBox(height: 10),
      _kpiRow(
        _kpi('Potential profit', _money(d.inventoryPotentialProfit)),
        _kpi('Stock units', '${d.stockUnits}'),
      ),
      const pw.SizedBox(height: 10),
      _kpiRow(
        _kpi(
          'Low stock',
          '${d.lowStockCount}',
          color: d.lowStockCount > 0 ? _red : _emeraldDark,
        ),
        _kpi(
          'Out of stock',
          '${d.outOfStockCount}',
          color: d.outOfStockCount > 0 ? _red : _emeraldDark,
        ),
      ),
    ]);
  }
}
