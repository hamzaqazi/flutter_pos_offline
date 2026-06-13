import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InvoicePage extends StatelessWidget {
  final double total;
  final double cash;
  final double change;

  const InvoicePage({
    super.key,
    required this.total,
    required this.cash,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invoice")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "SHOP RECEIPT",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Text("Total: Rs $total"),
            Text("Cash: Rs $cash"),
            Text("Change: Rs $change"),

            const Spacer(),

            ElevatedButton(
              onPressed: () => Get.offAllNamed('/'),
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }
}
