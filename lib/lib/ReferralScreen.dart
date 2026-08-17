import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';

const Color _kBrand = Color(0xFF13366B);

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  ReferralInfo? _info;
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
      final info = await ApiService.getReferralInfo();
      if (mounted) setState(() => _info = info);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copyCode() {
    if (_info == null) return;
    Clipboard.setData(ClipboardData(text: _info!.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Program'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Hero explanation ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF13366B), Color(0xFF2A5298)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.redeem, color: Colors.amber, size: 48),
                const SizedBox(height: 12),
                const Text('Invite Friends, Earn Rewards',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Share your code. When a friend signs up, you earn 1.00 JOD instantly.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Code box ─────────────────────────────────────────────────────
          Text('Your Code', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : _kBrand)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBrand.withAlpha(50)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(info.code,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4, color: _kBrand)),
                ElevatedButton.icon(
                  onPressed: _copyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBrand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                  label: const Text('Copy', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Stats row ────────────────────────────────────────────────────
          Row(children: [
            _statCard('Referrals', '${info.totalReferrals}', Icons.people_alt_outlined, isDark),
            const SizedBox(width: 12),
            _statCard('Total Earned', '${info.totalEarned.toStringAsFixed(2)} JOD', Icons.wallet_outlined, isDark),
          ]),

          const SizedBox(height: 24),

          // ── History list ─────────────────────────────────────────────────
          Text('Referral History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : _kBrand)),
          const SizedBox(height: 12),
          if (info.referrals.isEmpty)
            const Text('No referrals yet. Share your code to get started!',
                style: TextStyle(color: Colors.grey))
          else
            ...info.referrals.map((r) => _historyTile(r, isDark)),
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
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: _kBrand, size: 26),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _historyTile(Referral r, bool isDark) {
    final date = '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_alt_1, color: Colors.green, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('User #${r.referredUserId} joined',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          Text('+${r.rewardAmount.toStringAsFixed(2)} JOD',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
