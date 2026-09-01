import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../app/utils/formatters.dart';
import '../models/cart_item_model.dart';
import '../services/settings_service.dart';

/// Generates the receipt/invoice PDF.
///
/// The layout mirrors the in-app Invoice Preview page: centered shop
/// header, invoice-number badge, dashed section dividers, item rows with
/// "qty × price" and bold line totals, colored discount/tax rows and an
/// emphasized grand total — so what the user shares/prints matches what
/// they see on screen.
class InvoicePdfService {
  // ── Palette (mirrors AppColors) ──
  static const _emerald = PdfColor.fromInt(0xFF10B981); // AppColors.seed
  static const _emeraldDark = PdfColor.fromInt(0xFF064E3B); // AppColors.accent
  static const _emeraldBg = PdfColor.fromInt(
    0xFFECFDF5,
  ); // AppColors.successLight
  static const _red = PdfColor.fromInt(0xFFDC2626); // AppColors.danger
  static const _grey = PdfColor.fromInt(0xFF6B7280); // secondary text
  static const _lineGrey = PdfColor.fromInt(0xFFD1D5DB); // dividers
  static const _ink = PdfColor.fromInt(0xFF111827); // primary text

  static Future<Uint8List> generateInvoice({
    required List<CartItemModel> items,
    double subtotal = 0,
    double checkoutDiscount = 0,
    double taxRate = 0,
    bool taxInclusive = false,
    double taxAmount = 0,
    required double total,
    required double cash,
    required double change,
    double totalSavings = 0,
    String customerName = '',
    String cashierName = '',
    String invoiceNumber = '',
  }) async {
    final pdf = pw.Document();
    final checkoutDiscountAmount = subtotal * checkoutDiscount / 100;
    final productDiscountAmount = totalSavings - checkoutDiscountAmount;

    final settings = SettingsService.getSettings();
    final receiptSettings = SettingsService.getReceiptSettings();

    // ── Shop logo (optional) ──
    pw.MemoryImage? logoImage;
    if (!kIsWeb && receiptSettings.showLogo && receiptSettings.hasLogo) {
      try {
        final file = File(receiptSettings.logoPath);
        if (file.existsSync()) {
          logoImage = pw.MemoryImage(file.readAsBytesSync());
        }
      } catch (_) {
        // Logo unreadable — render without it.
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: receiptSettings.paperWidth == 58
            ? PdfPageFormat.roll57
            : PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ═══════════ Header ═══════════
              if (logoImage != null)
                pw.Center(
                  child: pw.Container(
                    height: 44,
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                ),
              if (receiptSettings.showShopName)
                pw.Center(
                  child: pw.Text(
                    settings.shopName.toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1,
                      color: _ink,
                    ),
                  ),
                ),
              if (receiptSettings.showAddress && settings.address.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Center(
                    child: pw.Text(
                      settings.address,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 7.5, color: _grey),
                    ),
                  ),
                ),
              if (receiptSettings.showPhone && settings.phone.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1),
                  child: pw.Center(
                    child: pw.Text(
                      settings.phone,
                      style: const pw.TextStyle(fontSize: 7.5, color: _grey),
                    ),
                  ),
                ),

              // Invoice number badge
              if (invoiceNumber.isNotEmpty)
                pw.Center(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.only(top: 6),
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _emeraldBg,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      invoiceNumber,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1,
                        color: _emeraldDark,
                      ),
                    ),
                  ),
                ),
              if (receiptSettings.showDate)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Center(
                    child: pw.Text(
                      Formatters.dateTime(DateTime.now()),
                      style: const pw.TextStyle(fontSize: 7.5, color: _grey),
                    ),
                  ),
                ),

              _dashedDivider(),

              // ═══════════ Customer / Cashier ═══════════
              if (receiptSettings.showCustomer && customerName.isNotEmpty) ...[
                _metaRow('Customer', customerName),
                _dashedDivider(),
              ],
              if (receiptSettings.showCashier && cashierName.isNotEmpty) ...[
                _metaRow('Cashier', cashierName),
                _dashedDivider(),
              ],

              // ═══════════ Items ═══════════
              if (items.isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Center(
                    child: pw.Text(
                      'Item details not available',
                      style: const pw.TextStyle(fontSize: 7.5, color: _grey),
                    ),
                  ),
                )
              else
                ...items.map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    item.product.name,
                                    style: const pw.TextStyle(
                                      fontSize: 8.5,
                                      color: _ink,
                                    ),
                                  ),
                                  if (receiptSettings.showBrand &&
                                      item.product.brand.isNotEmpty)
                                    pw.Text(
                                      item.product.brand,
                                      style: const pw.TextStyle(
                                        fontSize: 7,
                                        color: _grey,
                                      ),
                                    ),
                                  if (receiptSettings.showSku &&
                                      item.product.sku.isNotEmpty)
                                    pw.Text(
                                      'SKU: ${item.product.sku}',
                                      style: pw.TextStyle(
                                        fontSize: 6.5,
                                        color: _grey,
                                        font: pw.Font.courier(),
                                      ),
                                    ),
                                  if (receiptSettings.showBarcode &&
                                      item.product.barcode.isNotEmpty)
                                    pw.Text(
                                      item.product.barcode,
                                      style: pw.TextStyle(
                                        fontSize: 6.5,
                                        color: _grey,
                                        font: pw.Font.courier(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            pw.Text(
                              '${item.quantity} \u00d7 ${Formatters.currency(item.product.discountedPrice)}',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: _grey,
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Text(
                              Formatters.currency(item.total),
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                        if (receiptSettings.showDiscountDetails &&
                            item.product.discount > 0)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 1, left: 2),
                            child: pw.Text(
                              'Original: ${Formatters.currency(item.product.price)} each (-${item.product.discount.toStringAsFixed(0)}%)',
                              style: const pw.TextStyle(
                                fontSize: 6.5,
                                color: _emerald,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              _dashedDivider(),

              // ═══════════ Totals ═══════════
              _totalRow('Subtotal', Formatters.currency(subtotal)),
              if (receiptSettings.showDiscountDetails &&
                  productDiscountAmount > 0)
                _totalRow(
                  'Product discounts',
                  '-${Formatters.currency(productDiscountAmount)}',
                  valueColor: _emerald,
                ),
              if (checkoutDiscount > 0)
                _totalRow(
                  'Checkout discount (${checkoutDiscount.toStringAsFixed(0)}%)',
                  '-${Formatters.currency(checkoutDiscountAmount)}',
                  valueColor: _red,
                ),
              if (receiptSettings.showTaxDetails && taxAmount > 0)
                _totalRow(
                  taxInclusive
                      ? 'Tax incl. (${taxRate.toStringAsFixed(1)}%)'
                      : 'Tax (${taxRate.toStringAsFixed(1)}%)',
                  Formatters.currency(taxAmount),
                  valueColor: _emeraldDark,
                ),

              pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 4),
                height: 0.8,
                color: _lineGrey,
              ),

              // Grand total — emphasized like the preview
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    pw.Text(
                      Formatters.currency(total),
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: _emerald,
                      ),
                    ),
                  ],
                ),
              ),
              _totalRow('Cash', Formatters.currency(cash)),
              _totalRow('Change', Formatters.currency(change)),

              // ═══════════ Footer ═══════════
              if (receiptSettings.showFooter &&
                  settings.receiptFooter.isNotEmpty) ...[
                _dashedDivider(),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Center(
                    child: pw.Text(
                      settings.receiptFooter,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8, color: _grey),
                    ),
                  ),
                ),
              ],

              // ═══════════ Powered by Codynest ═══════════
              _dashedDivider(),

              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Powered by Codynest.com',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    pw.SizedBox(height: 2),

                    pw.Text(
                      'Support & WhatsApp:',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 7),
                    ),

                    pw.SizedBox(height: 1),

                    pw.Text(
                      '0315-3507075 / 0345-3333316',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── Helpers ──

  /// Dashed section divider, like _DashedDivider on the preview page.
  static pw.Widget _dashedDivider() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 7),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: _lineGrey,
            width: 0.7,
            style: pw.BorderStyle.dashed,
          ),
        ),
      ),
    );
  }

  /// "Customer: Name" / "Cashier: Name" row.
  static pw.Widget _metaRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: const pw.TextStyle(fontSize: 8, color: _grey),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ],
    );
  }

  /// Label-left / value-right totals row.
  static pw.Widget _totalRow(
    String label,
    String value, {
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _grey)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: valueColor ?? _ink,
            ),
          ),
        ],
      ),
    );
  }
}
