import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  const PaymentScreen({super.key, required this.amount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedMethod = "Visa";
  static const Color joRideAccent = Color(0xFF13366B);

  @override
  Widget build(BuildContext context) {
    // حسابات توضيحية للفاتورة
    double serviceFee = 1.50;
    double tax = widget.amount * 0.05; // 5% VAT
    double totalToPay = widget.amount + serviceFee + tax;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Confirmation"),
        backgroundColor: joRideAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- قسم الفاتورة (Invoice Card) ---
            const Text("Billing Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: joRideAccent)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ??
                    Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _invoiceRow("Rental Subtotal", "${widget.amount.toStringAsFixed(2)} JOD"),
                  _invoiceRow("Service Fee", "${serviceFee.toStringAsFixed(2)} JOD"),
                  _invoiceRow("Tax (VAT 5%)", "${tax.toStringAsFixed(2)} JOD"),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Amount",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("${totalToPay.toStringAsFixed(2)} JOD",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: joRideAccent)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- قسم طرق الدفع ---
            const Text("Select Payment Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: joRideAccent)),
            const SizedBox(height: 12),
            _paymentTile("Apple Pay", Icons.apple, Colors.black),
            _paymentTile("Credit Card", Icons.credit_card, Colors.orange[800]!),
            _paymentTile("PayPal", Icons.paypal, Colors.blue[900]!),

            const SizedBox(height: 40),

            // زر التأكيد النهائي
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: joRideAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                onPressed: () {
                  // هنا نضع منطق النجاح أو الانتقال لصفحة المفتاح
                  _showSuccessDialog();
                },
                child: const Text("Confirm & Pay",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _paymentTile(String title, IconData icon, Color color) {
    bool isSelected = selectedMethod == title;
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? joRideAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: joRideAccent),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: Colors.green, size: 70),
            const SizedBox(height: 20),
            const Text("Success!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Payment confirmed. Have a safe trip!", textAlign: TextAlign.center),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("Back to Home"),
            )
          ],
        ),
      ),
    );
  }
}