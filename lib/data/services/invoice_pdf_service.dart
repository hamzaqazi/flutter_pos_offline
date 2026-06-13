import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cart_item_model.dart';
import '../models/shop_settings_model.dart';
import '../services/settings_service.dart';

class InvoicePdfService {
  static Future<Uint8List> generateInvoice({
    required List<CartItemModel> items,
    double subtotal = 0,
    double checkoutDiscount = 0,
    required double total,
    required double cash,
    required double change,
    double totalSavings = 0,
  }) async {
    final pdf = pw.Document();
    final checkoutDiscountAmount = subtotal * checkoutDiscount / 100;
    final productDiscountAmount = totalSavings - checkoutDiscountAmount;

    final settings = SettingsService.getSettings();
    final currency = settings.currencySymbol;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // 🔥 thermal printer size
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ---------- Shop header ----------
              pw.Center(
                child: pw.Text(
                  settings.shopName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (settings.address.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    settings.address,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              if (settings.phone.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    settings.phone,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),

              pw.SizedBox(height: 10),
              pw.Text("Date: ${DateTime.now()}"),
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
                              if (item.product.brand.isNotEmpty)
                                pw.Text(
                                  "  ${item.product.brand}",
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                            ],
                          ),
                        ),
                        pw.Text(
                            "$currency ${item.product.discountedPrice.toStringAsFixed(0)}"),
                      ],
                    ),
                    if (item.product.discount > 0)
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
              if (productDiscountAmount > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Product discounts:"),
                    pw.Text("-$currency ${productDiscountAmount.toStringAsFixed(0)}"),
                  ],
                ),
              ],
              // Checkout discount
              if (checkoutDiscount > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Checkout discount (${checkoutDiscount.toStringAsFixed(0)}%):"),
                    pw.Text("-$currency ${checkoutDiscountAmount.toStringAsFixed(0)}"),
                  ],
                ),
              ],
              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Total:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("$currency ${total.toStringAsFixed(0)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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

              pw.Center(
                child: pw.Text(settings.receiptFooter, style: pw.TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
