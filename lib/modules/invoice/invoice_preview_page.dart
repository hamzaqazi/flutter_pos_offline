import 'package:ad_shop_pos/modules/cart/cart_controller.dart';
import 'package:ad_shop_pos/modules/sales/sales_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/services/invoice_pdf_service.dart';
import 'package:printing/printing.dart';

class InvoicePreviewPage extends StatelessWidget {
  final List<CartItemModel> items;
  final double total;
  final double cash;
  final double change;

  const InvoicePreviewPage({
    super.key,
    required this.items,
    required this.total,
    required this.cash,
    required this.change,
  });

  Future<void> _printInvoice() async {
    final pdfBytes = await InvoicePdfService.generateInvoice(
      items: items,
      total: total,
      cash: cash,
      change: change,
    );

    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invoice Preview")),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "SHOP RECEIPT",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Divider(),

                  ...items.map(
                    (item) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(item.product.name)),
                        Text("${item.quantity} x ${item.product.price}"),
                      ],
                    ),
                  ),

                  const Divider(),

                  Text("Total: Rs $total"),
                  Text("Cash: Rs $cash"),
                  Text("Change: Rs $change"),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text("Print Invoice"),
                onPressed: () async {
                  await _printInvoice();

                  Get.find<SalesController>().completeSale(
                    cash: cash,
                    change: change,
                  );

                  Get.offAllNamed('/');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
