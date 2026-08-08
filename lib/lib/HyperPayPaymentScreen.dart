import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'widgets/hyperpay_checkout_view.dart';

/// Hosts HyperPay's Copy&Pay checkout page. Pops `true` once the user
/// confirms they completed payment (the backend confirms the actual outcome
/// via webhook — this screen never sees a live result), or `false`/`null`
/// if the user backs out or the gateway isn't ready yet.
class HyperPayPaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final String? tripId;

  const HyperPayPaymentScreen({
    super.key,
    required this.amount,
    this.currency = 'JOD',
    this.tripId,
  });

  @override
  State<HyperPayPaymentScreen> createState() => _HyperPayPaymentScreenState();
}

class _HyperPayPaymentScreenState extends State<HyperPayPaymentScreen> {
  static const Color joRideAccent = Color(0xFF13366B);

  Map<String, dynamic>? _checkout;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() => _error = null);
    try {
      final res = await ApiService.prepareHyperPayCheckout(
        amount: widget.amount,
        currency: widget.currency,
        tripId: widget.tripId,
      );
      if (mounted) setState(() => _checkout = res);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgetUrl = _checkout?['widgetUrl'] as String?;
    final gatewayReady = widgetUrl != null && widgetUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Payment'),
        backgroundColor: joRideAccent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          if (gatewayReady)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("I've completed payment",
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _buildBody(widgetUrl),
    );
  }

  Widget _buildBody(String? widgetUrl) {
    if (_error != null) {
      return _buildMessage(
        icon: Icons.error_outline,
        color: Colors.red,
        message: _error!,
        onRetry: _prepare,
      );
    }
    if (_checkout == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widgetUrl == null || widgetUrl.isEmpty) {
      return _buildMessage(
        icon: Icons.construction_outlined,
        color: Colors.orange,
        message: 'The payment gateway is not yet configured. '
            'Card payments will be available once HyperPay credentials are set up on the backend.',
      );
    }
    return HyperPayCheckoutView(widgetUrl: widgetUrl);
  }

  Widget _buildMessage({
    required IconData icon,
    required Color color,
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(backgroundColor: joRideAccent),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
