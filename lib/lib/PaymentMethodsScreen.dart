import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  static const Color joRideAccent = Color(0xFF13366B);
  static const Color scaffoldBg = Color(0xFFF8F9FD);

  List<Map<String, dynamic>> _methods = [];

  final _cardNumberCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _methods = [
      {
        'type': 'visa',
        'last4': '4242',
        'holder': 'Card Holder',
        'expiry': '12/27',
        'isDefault': true,
      },
      {
        'type': 'mastercard',
        'last4': '5678',
        'holder': 'Card Holder',
        'expiry': '08/26',
        'isDefault': false,
      },
    ];
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _holderCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  void _setDefault(int index) {
    setState(() {
      for (int i = 0; i < _methods.length; i++) {
        _methods[i] = Map<String, dynamic>.from(_methods[i]);
        _methods[i]['isDefault'] = (i == index);
      }
    });
  }

  void _removeMethod(int index) {
    setState(() => _methods.removeAt(index));
  }

  void _showAddCardDialog() {
    _cardNumberCtrl.clear();
    _holderCtrl.clear();
    _expiryCtrl.clear();
    String selectedType = 'visa';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDlgState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Add New Card',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Card type selector
                  Row(
                    children: [
                      _typeChip(
                        label: 'Visa',
                        selected: selectedType == 'visa',
                        onTap: () =>
                            setDlgState(() => selectedType = 'visa'),
                      ),
                      const SizedBox(width: 10),
                      _typeChip(
                        label: 'Mastercard',
                        selected: selectedType == 'mastercard',
                        onTap: () =>
                            setDlgState(() => selectedType = 'mastercard'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cardNumberCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'Last 4 digits',
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _holderCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cardholder Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _expiryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Expiry (MM/YY)',
                      prefixIcon: Icon(Icons.date_range_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: joRideAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final last4 = _cardNumberCtrl.text.trim();
                  final holder = _holderCtrl.text.trim();
                  final expiry = _expiryCtrl.text.trim();
                  if (last4.isEmpty || holder.isEmpty || expiry.isEmpty) {
                    return;
                  }
                  setState(() {
                    _methods.add({
                      'type': selectedType,
                      'last4': last4,
                      'holder': holder,
                      'expiry': expiry,
                      'isDefault': false,
                    });
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Add Card',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _typeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? joRideAccent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('Payment Methods',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: joRideAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddCardDialog,
            tooltip: 'Add Card',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCardDialog,
        backgroundColor: joRideAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add New Card',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _methods.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: _methods.length,
              itemBuilder: (ctx, i) => _buildCardWidget(i),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Payment Methods',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a card.',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWidget(int index) {
    final m = _methods[index];
    final bool isVisa = m['type'] == 'visa';

    final List<Color> gradColors = isVisa
        ? [const Color(0xFF1A3D7C), const Color(0xFF13366B)]
        : [const Color(0xFF1A1A2E), const Color(0xFF16213E)];

    return GestureDetector(
      onLongPress: () => _removeMethod(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 190,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradColors.first.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: chip + type label + default badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Chip simulation
                Container(
                  width: 38,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Row(
                  children: [
                    if (m['isDefault'] == true)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    Text(
                      isVisa ? 'VISA' : 'MASTERCARD',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Card number
            Text(
              '**** **** **** ${m['last4']}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 16),

            // Bottom row: holder + expiry + actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CARD HOLDER',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            letterSpacing: 0.8)),
                    Text(m['holder'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EXPIRES',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            letterSpacing: 0.8)),
                    Text(m['expiry'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                Row(
                  children: [
                    // Set as default
                    if (m['isDefault'] != true)
                      GestureDetector(
                        onTap: () => _setDefault(index),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_border_rounded,
                              color: Colors.white70, size: 18),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Delete
                    GestureDetector(
                      onTap: () => _removeMethod(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white70, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
