import 'package:flutter/material.dart';
import 'models/auth_models.dart';
import 'services/api_service.dart';

const Color _kBrand = Color(0xFF13366B);

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  LoyaltyInfo? _info;
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
      final info = await ApiService.getLoyaltyInfo();
      if (mounted) setState(() => _info = info);
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
        title: const Text('Loyalty Program'),
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
    final info = _info!;
    final tierData = _tierData(info.tier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Progress within the current tier
    double progress = 0;
    int tierTotal = 0;
    int tierStart = 0;
    switch (info.tier) {
      case 'Bronze':
        tierStart = 0; tierTotal = 5;
        progress = info.completedTrips / 5;
      case 'Silver':
        tierStart = 5; tierTotal = 10;
        progress = (info.completedTrips - 5) / 10;
      case 'Gold':
        tierStart = 15; tierTotal = 15;
        progress = (info.completedTrips - 15) / 15;
      case 'Platinum':
        tierStart = 30; tierTotal = 0;
        progress = 1.0;
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Tier badge ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tierData.color.withAlpha(220), tierData.color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: tierData.color.withAlpha(80), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              children: [
                Icon(tierData.icon, color: Colors.white, size: 56),
                const SizedBox(height: 12),
                Text(info.tier,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(tierData.subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Stats ────────────────────────────────────────────────────────
          Row(children: [
            _statCard('Completed Trips', '${info.completedTrips}', Icons.check_circle_outline, isDark),
            const SizedBox(width: 12),
            _statCard('Your Discount', '${info.discountPercent}%', Icons.local_offer_outlined, isDark),
          ]),

          const SizedBox(height: 24),

          // ── Progress to next tier ────────────────────────────────────────
          if (info.tier != 'Platinum') ...[
            Text('Progress to next tier',
                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : _kBrand)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                color: tierData.color,
              ),
            ),
            const SizedBox(height: 6),
            Text('${info.completedTrips - tierStart} / $tierTotal trips completed in this tier  ·  ${info.tripsToNextTier} more to go',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
          ],

          // ── Tier table ───────────────────────────────────────────────────
          Text('All Tiers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : _kBrand)),
          const SizedBox(height: 12),
          ..._allTiers().map((t) => _tierRow(t, info.tier, isDark)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: _kBrand, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _tierRow(_TierMeta t, String currentTier, bool isDark) {
    final isCurrent = t.name == currentTier;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? t.color.withAlpha(20) : (isDark ? const Color(0xFF1E1E2E) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: isCurrent ? Border.all(color: t.color, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
      ),
      child: Row(children: [
        Icon(t.icon, color: t.color, size: 28),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.name, style: TextStyle(fontWeight: FontWeight.bold, color: isCurrent ? t.color : null)),
          Text(t.range, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: t.color.withAlpha(20), borderRadius: BorderRadius.circular(20)),
          child: Text('${t.discount}% off', style: TextStyle(color: t.color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        if (isCurrent) ...[
          const SizedBox(width: 8),
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
        ],
      ]),
    );
  }

  _TierMeta _tierData(String tier) =>
      _allTiers().firstWhere((t) => t.name == tier, orElse: () => _allTiers().first);

  List<_TierMeta> _allTiers() => [
    _TierMeta('Bronze',  '0 – 4 trips',  0,  Icons.shield_outlined,    const Color(0xFFCD7F32)),
    _TierMeta('Silver',  '5 – 14 trips', 5,  Icons.shield,             const Color(0xFF9E9E9E)),
    _TierMeta('Gold',    '15 – 29 trips', 10, Icons.workspace_premium,  const Color(0xFFFFBF00)),
    _TierMeta('Platinum','30+ trips',    15, Icons.diamond_outlined,   const Color(0xFF00ACC1)),
  ];
}

class _TierMeta {
  final String name;
  final String range;
  final int discount;
  final IconData icon;
  final Color color;
  const _TierMeta(this.name, this.range, this.discount, this.icon, this.color);
  String get subtitle => discount > 0 ? '$discount% off every trip' : 'No discount yet';
}
