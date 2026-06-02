import 'package:flutter/material.dart';

import 'Home Screen.dart';
import 'FareMeterScreen.dart';
import 'models/auth_models.dart';
import 'services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final double total;
  final int duration;
  final String type;

  const CheckoutScreen({
    super.key,
    required this.car,
    required this.total,
    required this.duration,
    required this.type,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedPayment = "Credit Card";
  bool _paying = false;
  static const Color joRideAccent = Color(0xFF13366B);

  @override
  Widget build(BuildContext context) {
    double tax = widget.total * 0.05;
    double bookingFee = 1.50;
    double finalTotal = widget.total + tax + bookingFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout & Payment"),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 25),

            const Text("Invoice Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _invoiceRow("Rental Duration", "${widget.duration} ${widget.type}"),
                  _invoiceRow("Base Price", "${widget.total.toStringAsFixed(2)} JOD"),
                  _invoiceRow("Booking Fees", "${bookingFee.toStringAsFixed(2)} JOD"),
                  _invoiceRow("Tax (VAT 5%)", "${tax.toStringAsFixed(2)} JOD"),
                  const Divider(height: 30),
                  _invoiceRow("Total Amount", "${finalTotal.toStringAsFixed(2)} JOD", isTotal: true),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text("Select Payment Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            _paymentOption("Apple Pay", Icons.apple, Colors.black),
            _paymentOption("PayPal", Icons.paypal, Colors.blue[800]!),
            _paymentOption("Credit Card", Icons.credit_card, Colors.orange[800]!),
            _paymentOption("joRide Wallet", Icons.account_balance_wallet, Colors.green[700]!),

            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: joRideAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                onPressed: _paying ? null : _pay,
                child: _paying
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text("Pay & Get Access",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    Trip? trip;
    try {
      final tax = widget.total * 0.05;
      const bookingFee = 1.50;
      final finalTotal = widget.total + tax + bookingFee;
      trip = await ApiService.startTrip(
        vehicleId: widget.car['id'] as String,
        duration: widget.duration,
        durationType: widget.type,
        baseFare: widget.total,
        bookingFee: bookingFee,
        tax: tax,
        totalFare: finalTotal,
        paymentMethod: selectedPayment,
      );
      await ApiService.saveActiveRental(car: widget.car, trip: trip);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start trip: $e'), backgroundColor: Colors.red),
      );
      setState(() => _paying = false);
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e'), backgroundColor: Colors.red),
      );
      setState(() => _paying = false);
      return;
    } finally {
      if (mounted && _paying) setState(() => _paying = false);
    }

    if (!mounted) return;
    _showSuccessDialog(context, trip!);
  }

  Widget _invoiceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isTotal ? Colors.black : Colors.grey[600],
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 18 : 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTotal ? 18 : 14,
                  color: isTotal ? joRideAccent : Colors.black)),
        ],
      ),
    );
  }

  Widget _paymentOption(String title, IconData icon, Color color) {
    bool isSelected = selectedPayment == title;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? joRideAccent : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: joRideAccent)
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              widget.car['img'],
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 50),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.car['model'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Color: ${widget.car['color']}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, Trip trip) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("Success!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Payment processed. Your digital key is ready.",
                textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: joRideAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FareMeterScreen(
                      car: widget.car,
                      tripId: trip.id,
                      rateType: widget.type,
                      duration: widget.duration,
                      scheduledEndTime: trip.scheduledEndTime,
                      paidTotal: trip.totalFare ?? (widget.total + (widget.total * 0.05) + 1.50),
                    ),
                  ),
                  (route) => false,
                );
              },
              child: const Text("Access Your Key",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
