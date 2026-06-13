import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cart_item_model.dart';

class InvoicePdfService {
  static Future<Uint8List> generateInvoice({
    required List<CartItemModel> items,
    required double total,
    required double cash,
    required double change,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // 🔥 thermal printer size
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "SHOP RECEIPT",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 10),

              pw.Text("Date: ${DateTime.now()}"),
              pw.Divider(),

              pw.Text("Items:"),
              pw.SizedBox(height: 5),

              ...items.map(
                (item) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text(item.product.name)),
                    pw.Text("${item.quantity} x ${item.product.price}"),
                  ],
                ),
              ),

              pw.Divider(),

              pw.Text("Total: Rs $total"),
              pw.Text("Cash: Rs $cash"),
              pw.Text("Change: Rs $change"),

              pw.SizedBox(height: 20),

              pw.Center(
                child: pw.Text("Thank you!", style: pw.TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
