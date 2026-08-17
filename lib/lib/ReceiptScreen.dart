import 'package:flutter/material.dart';
import 'services/api_service.dart';

const Color _kBrand = Color(0xFF13366B);

class ReceiptScreen extends StatefulWidget {
  final String tripId;

  const ReceiptScreen({super.key, required this.tripId});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  Map<String, dynamic>? _receipt;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getTripReceipt(widget.tripId);
      if (mounted) setState(() => _receipt = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        backgroundColor: _kBrand,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(backgroundColor: _kBrand),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );

  Widget _buildBody() {
    final r = _receipt!;
    final billing  = r['billing']  as Map<String, dynamic>? ?? {};
    final tripInfo = r['trip']     as Map<String, dynamic>? ?? {};
    final vehicle  = r['vehicle']  as Map<String, dynamic>?;
    final user     = r['user']     as Map<String, dynamic>?;
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    final issuedAt = r['issuedAt'] != null
        ? DateTime.parse(r['issuedAt'] as String).toLocal()
        : null;
    final status = (tripInfo['status'] as String?) ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF13366B), Color(0xFF2A5298)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              const Icon(Icons.receipt_long, color: Colors.white70, size: 40),
              const SizedBox(height: 10),
              Text(r['receiptNumber'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 4),
              if (issuedAt != null)
                Text(_formatDate(issuedAt), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              _statusBadge(status),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Vehicle + User ───────────────────────────────────────────────
          _section('Trip Details', isDark, [
            if (vehicle != null) ...[
              _row('Vehicle', vehicle['model'] as String? ?? 'Vehicle #${vehicle['id']}'),
              _row('Plate', (vehicle['licensePlate'] as String?) ?? '—'),
              _row('Category', (vehicle['category'] as String?) ?? '—'),
            ],
            _row('Duration', '${tripInfo['duration'] ?? '—'} ${tripInfo['durationType'] ?? ''}'),
            if (tripInfo['startTime'] != null)
              _row('Start', _formatDate(DateTime.parse(tripInfo['startTime'] as String).toLocal())),
            if (tripInfo['endTime'] != null)
              _row('End', _formatDate(DateTime.parse(tripInfo['endTime'] as String).toLocal())),
            if (user != null)
              _row('Customer', user['name'] as String? ?? '—'),
          ]),

          const SizedBox(height: 16),

          // ── Billing breakdown ────────────────────────────────────────────
          _section('Billing', isDark, [
            _row('Base Fare', _jod(billing['baseFare'])),
            _row('Booking Fee', _jod(billing['bookingFee'])),
            _row('Tax', _jod(billing['tax'])),
            if ((billing['discountPercent'] as num? ?? 0) > 0)
              _row('Loyalty Discount (${billing['discountPercent']}%)', '− ${_jod(billing['discountAmount'])}',
                  valueColor: Colors.green),
            if ((billing['overtimeFare'] as num? ?? 0) > 0)
              _row('Overtime Charge', _jod(billing['overtimeFare']), valueColor: Colors.orange),
            const Divider(height: 20),
            _row('Total Charged', _jod(billing['totalFare']),
                bold: true, valueColor: _kBrand),
            _row('Payment Method', (billing['paymentMethod'] as String?) ?? '—'),
            _row('Payment Status', (billing['paymentStatus'] as String?) ?? '—',
                valueColor: (billing['paymentStatus'] == 'Paid') ? Colors.green : Colors.orange),
          ]),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _section(String title, bool isDark, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _kBrand)),
        const SizedBox(height: 12),
        ...rows,
      ]),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                fontSize: bold ? 15 : 13,
                color: valueColor,
              )),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == 'Completed'
        ? Colors.green
        : status == 'Cancelled'
            ? Colors.red
            : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(40), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  String _jod(dynamic v) => v != null ? '${(v as num).toStringAsFixed(2)} JOD' : '—';

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
