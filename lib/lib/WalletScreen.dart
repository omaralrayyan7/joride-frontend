import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/auth_models.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const Color joRideAccent = Color(0xFF13366B);
  static const Color scaffoldBg = Color(0xFFF8F9FD);

  double _balance = 0.0;
  List<WalletTransaction> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getWallet();
      if (mounted) {
        setState(() {
          _balance = data['balance'] as double;
          _transactions = data['transactions'] as List<WalletTransaction>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showTopUpDialog() async {
    final amountCtrl = TextEditingController();
    String selectedMethod = 'Credit Card';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Top Up Wallet',
                style: TextStyle(
                    color: joRideAccent, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (JOD)',
                      prefixIcon: const Icon(Icons.attach_money,
                          color: joRideAccent),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Payment Method',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Credit Card', 'PayPal'].map((method) {
                      final selected = selectedMethod == method;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedMethod = method),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? joRideAccent
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? joRideAccent
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                method,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: joRideAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final raw = amountCtrl.text.trim();
                    final amount = double.tryParse(raw);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a valid amount.')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    await _topUp(amount, selectedMethod);
                  },
                  child: const Text('Confirm',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
    amountCtrl.dispose();
  }

  Future<void> _topUp(double amount, String paymentMethod) async {
    try {
      await ApiService.topUp(amount, paymentMethod);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully added ${amount.toStringAsFixed(2)} JOD to your wallet.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadWallet();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildBody(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWallet,
              style: ElevatedButton.styleFrom(backgroundColor: joRideAccent),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadWallet,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Wallet',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: joRideAccent),
                  ),
                  const SizedBox(height: 20),
                  // بطاقة الرصيد
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [joRideAccent, Color(0xFF2A5298)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: joRideAccent.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Balance',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_balance.toStringAsFixed(2)} JOD',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: joRideAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _showTopUpDialog,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text(
                              'Top Up',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Transaction History',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // قائمة المعاملات
          _transactions.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 70, color: Colors.black12),
                        SizedBox(height: 12),
                        Text('No transactions yet.',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = _transactions[index];
                      return _buildTransactionTile(tx);
                    },
                    childCount: _transactions.length,
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction tx) {
    final isCredit = tx.type == 'topup' || tx.type == 'credit';
    final amountColor = isCredit ? Colors.green.shade700 : Colors.red.shade700;
    final amountPrefix = isCredit ? '+' : '-';

    IconData txIcon;
    Color txIconBg;
    switch (tx.type) {
      case 'topup':
      case 'credit':
        txIcon = Icons.add_circle_outline;
        txIconBg = Colors.green.shade50;
        break;
      case 'debit':
      case 'payment':
        txIcon = Icons.directions_car_outlined;
        txIconBg = Colors.blue.shade50;
        break;
      default:
        txIcon = Icons.swap_horiz;
        txIconBg = Colors.grey.shade100;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration:
                BoxDecoration(color: txIconBg, shape: BoxShape.circle),
            child: Icon(txIcon,
                color: isCredit
                    ? Colors.green.shade700
                    : Colors.blue.shade700,
                size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isNotEmpty ? tx.description : tx.type,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(tx.createdAt),
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix${tx.amount.toStringAsFixed(2)} JOD',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: amountColor),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}  '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
