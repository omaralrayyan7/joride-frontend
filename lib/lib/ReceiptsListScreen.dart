import 'package:flutter/material.dart';
import 'ReceiptScreen.dart';
import 'services/api_service.dart';

const Color _kBrand = Color(0xFF13366B);

class ReceiptsListScreen extends StatefulWidget {
  const ReceiptsListScreen({super.key});

  @override
  State<ReceiptsListScreen> createState() => _ReceiptsListScreenState();
}

class _ReceiptsListScreenState extends State<ReceiptsListScreen> {
  List<Map<String, dynamic>> _receipts = [];
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
      final data = await ApiService.getUserReceipts();
      if (mounted) setState(() => _receipts = data);
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
        title: const Text('My Receipts'),
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
    if (_receipts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text('No receipts yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text('Completed trips will appear here.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receipts.length,
        itemBuilder: (context, i) => _receiptTile(_receipts[i]),
      ),
    );
  }

  Widget _receiptTile(Map<String, dynamic> r) {
    final billing   = r['billing']  as Map<String, dynamic>? ?? {};
    final tripInfo  = r['trip']     as Map<String, dynamic>? ?? {};
    final vehicle   = r['vehicle']  as Map<String, dynamic>?;
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final status    = (tripInfo['status'] as String?) ?? '';
    final statusColor = status == 'Completed' ? Colors.green : Colors.red;
    final total     = (billing['totalFare'] as num?)?.toStringAsFixed(2) ?? '—';
    final receiptNo = (r['receiptNumber'] as String?) ?? '';
    final issuedAt  = r['issuedAt'] != null
        ? DateTime.parse(r['issuedAt'] as String).toLocal()
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          final tripId = (r['tripId'] as num?)?.toString() ?? '';
          if (tripId.isEmpty) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(tripId: tripId)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _kBrand.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_outlined, color: _kBrand, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(receiptNo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(vehicle != null
                      ? (vehicle['model'] as String? ?? 'Vehicle #${vehicle['id']}')
                      : 'Vehicle',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  if (issuedAt != null)
                    Text('${issuedAt.day}/${issuedAt.month}/${issuedAt.year}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$total JOD',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _kBrand, fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(status,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
