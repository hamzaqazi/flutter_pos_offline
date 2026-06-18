import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cart_item_model.dart';
import '../models/receipt_settings_model.dart';
import '../models/shop_settings_model.dart';
import '../services/settings_service.dart';

class InvoicePdfService {
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
    final currency = settings.currencySymbol;

    pdf.addPage(
      pw.Page(
        pageFormat: receiptSettings.paperWidth == 58
            ? PdfPageFormat.roll57
            : PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- Logo ---
              if (receiptSettings.showLogo && receiptSettings.hasLogo)
                pw.Center(
                  child: pw.Builder(
                    builder: (context) {
                      // Logo will be handled via image bytes if available
                      return pw.SizedBox(height: 0);
                    },
                  ),
                ),

              // --- Shop header ---
              if (receiptSettings.showShopName)
                pw.Center(
                  child: pw.Text(
                    settings.shopName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              if (receiptSettings.showAddress && settings.address.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    settings.address,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              if (receiptSettings.showPhone && settings.phone.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    settings.phone,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),

              pw.SizedBox(height: 10),

              // Invoice number
              if (invoiceNumber.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    invoiceNumber,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

              if (receiptSettings.showDate) pw.Text("Date: ${DateTime.now()}"),
              if (receiptSettings.showCustomer && customerName.isNotEmpty)
                pw.Text("Customer: $customerName"),
              if (receiptSettings.showCashier && cashierName.isNotEmpty)
                pw.Text("Cashier: $cashierName"),
              pw.Divider(),

              pw.Text("Items:"),
              pw.SizedBox(height: 5),

              ...items.map(
                (item) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(item.product.name),
                              if (receiptSettings.showBrand &&
                                  item.product.brand.isNotEmpty)
                                pw.Text(
                                  "  ${item.product.brand}",
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                              if (receiptSettings.showSku &&
                                  item.product.sku.isNotEmpty)
                                pw.Text(
                                  "  SKU: ${item.product.sku}",
                                  style: const pw.TextStyle(fontSize: 7),
                                ),
                              if (receiptSettings.showBarcode &&
                                  item.product.barcode.isNotEmpty)
                                pw.Text(
                                  "  Barcode: ${item.product.barcode}",
                                  style: const pw.TextStyle(fontSize: 7),
                                ),
                            ],
                          ),
                        ),
                        pw.Text(
                          "$currency ${item.product.discountedPrice.toStringAsFixed(0)}",
                        ),
                      ],
                    ),
                    if (receiptSettings.showDiscountDetails &&
                        item.product.discount > 0)
                      pw.Text(
                        "  Orig: $currency ${item.product.price.toStringAsFixed(0)} (-${item.product.discount.toStringAsFixed(0)}%)",
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                  ],
                ),
              ),

              pw.Divider(),

              // Subtotal
              if (subtotal > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Subtotal:"),
                    pw.Text("$currency ${subtotal.toStringAsFixed(0)}"),
                  ],
                ),
              ],
              // Product discounts
              if (receiptSettings.showDiscountDetails &&
                  productDiscountAmount > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Product discounts:"),
                    pw.Text(
                      "-$currency ${productDiscountAmount.toStringAsFixed(0)}",
                    ),
                  ],
                ),
              ],
              // Checkout discount
              if (checkoutDiscount > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Checkout discount (${checkoutDiscount.toStringAsFixed(0)}%):",
                    ),
                    pw.Text(
                      "-$currency ${checkoutDiscountAmount.toStringAsFixed(0)}",
                    ),
                  ],
                ),
              ],
              // Tax
              if (receiptSettings.showTaxDetails && taxAmount > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      taxInclusive
                          ? "Tax incl. (${taxRate.toStringAsFixed(1)}%):"
                          : "Tax (${taxRate.toStringAsFixed(1)}%):",
                    ),
                    pw.Text("$currency ${taxAmount.toStringAsFixed(0)}"),
                  ],
                ),
              ],
              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Total:",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    "$currency ${total.toStringAsFixed(0)}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Cash:"),
                  pw.Text("$currency ${cash.toStringAsFixed(0)}"),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Change:"),
                  pw.Text("$currency ${change.toStringAsFixed(0)}"),
                ],
              ),

              pw.SizedBox(height: 20),

              if (receiptSettings.showFooter)
                pw.Center(
                  child: pw.Text(
                    settings.receiptFooter,
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
