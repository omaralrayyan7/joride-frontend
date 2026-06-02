import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'Home Screen.dart';
import 'PostTripInspectionScreen.dart';

class FareMeterScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final String tripId;
  final String rateType;
  final int duration;
  final DateTime? scheduledEndTime;
  final double paidTotal;

  const FareMeterScreen({
    super.key,
    required this.car,
    required this.tripId,
    required this.rateType,
    required this.duration,
    this.scheduledEndTime,
    this.paidTotal = 0,
  });

  @override
  State<FareMeterScreen> createState() => _FareMeterScreenState();
}

class _FareMeterScreenState extends State<FareMeterScreen> {
  static const Color darkBg = Color(0xFF131A2D);
  static const Color joRideAccent = Color(0xFF13366B);

  Timer? _timer;
  bool isCarLocked = true;
  bool _hasKeyAccess = false;
  bool _keyLoading = false;
  bool _endingTrip = false;
  // Independent on/off state for each control — light up the buttons.
  bool _hornOn   = false;
  bool _acOn     = false;
  bool _lightsOn = false;
  late DateTime _scheduledEnd;
  int _remainingSeconds = 0;
  int _overtimeSeconds = 0;

  @override
  void initState() {
    super.initState();
    _scheduledEnd = widget.scheduledEndTime ?? _fallbackScheduledEnd();
    _fetchKeyStatus();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  DateTime _fallbackScheduledEnd() {
    final now = DateTime.now();
    if (widget.rateType == 'hour') return now.add(Duration(hours: widget.duration));
    if (widget.rateType == 'day') return now.add(Duration(days: widget.duration));
    return now.add(Duration(minutes: widget.duration));
  }

  void _tick() {
    final diff = _scheduledEnd.difference(DateTime.now()).inSeconds;
    if (!mounted) return;
    setState(() {
      _remainingSeconds = diff > 0 ? diff : 0;
      _overtimeSeconds = diff < 0 ? diff.abs() : 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(int s) =>
      '${(s ~/ 3600).toString().padLeft(2, '0')}:'
      '${((s % 3600) ~/ 60).toString().padLeft(2, '0')}:'
      '${(s % 60).toString().padLeft(2, '0')}';

  Map<String, double> get _rates {
    final raw = widget.car['rates'];
    if (raw is Map) {
      return {
        'min': ((raw['min'] as num?) ?? 0.15).toDouble(),
        'hour': ((raw['hour'] as num?) ?? 8).toDouble(),
        'day': ((raw['day'] as num?) ?? 45).toDouble(),
      };
    }
    return const {'min': 0.15, 'hour': 8.0, 'day': 45.0};
  }

  int get _overtimeMinutes => _overtimeSeconds <= 0 ? 0 : math.max(1, (_overtimeSeconds / 60).ceil());

  String get _overtimeBillingUnit {
    final mins = _overtimeMinutes;
    if (mins >= 1440) return 'day';
    if (mins >= 60) return 'hour';
    return 'min';
  }

  double get _overtimeCharge {
    final mins = _overtimeMinutes;
    if (mins <= 0) return 0;
    final rates = _rates;
    if (mins >= 1440) return (mins / 1440).ceil() * (rates['day'] ?? 45.0);
    if (mins >= 60) return (mins / 60).ceil() * (rates['hour'] ?? 8.0);
    return mins * (rates['min'] ?? 0.15);
  }

  String get _overtimeLabel {
    final mins = _overtimeMinutes;
    if (mins <= 0) return 'No overtime';
    if (mins >= 1440) return '${(mins / 1440).ceil()} day(s) billed';
    if (mins >= 60) return '${(mins / 60).ceil()} hour(s) billed';
    return '$mins minute(s) billed';
  }

  Future<void> _fetchKeyStatus() async {
    try {
      final status = await ApiService.getKeyStatus(widget.tripId);
      if (!mounted) return;
      setState(() {
        isCarLocked = (status['isLocked'] as bool?) ?? true;
        _hasKeyAccess = (status['hasAccess'] as bool?) ?? false;
      });
    } catch (_) {
      if (mounted) setState(() => _hasKeyAccess = false);
    }
  }

  Future<void> _toggleLock() async {
    if (!_hasKeyAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digital key is unavailable until payment is confirmed.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _keyLoading = true);
    try {
      if (isCarLocked) {
        await ApiService.unlockCar(widget.tripId);
      } else {
        await ApiService.lockCar(widget.tripId);
      }
      if (mounted) setState(() => isCarLocked = !isCarLocked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _keyLoading = false);
    }
  }

  Future<void> _endTrip() async {
    setState(() => _endingTrip = true);
    _timer?.cancel();
    try {
      final trip = await ApiService.endTrip(widget.tripId);
      await ApiService.clearActiveRental();
      if (!mounted) return;
      _showEndTripDialog(
        trip.totalFare ?? (widget.paidTotal + _overtimeCharge),
        trip.overtimeMinutes,
        trip.overtimeFare,
        trip.overtimePaymentStatus,
      );
    } catch (e) {
      if (!mounted) return;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _endingTrip = false);
    }
  }

  void _showEndTripDialog(double finalFare, int overtimeMinutes, double overtimeFare, String overtimeStatus) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 70),
            const SizedBox(height: 16),
            const Text('Trip Ended', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FD), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _summaryRow('Car', widget.car['model'] ?? 'Vehicle'),
                  const SizedBox(height: 8),
                  _summaryRow('Paid Rental', '${widget.duration} ${widget.rateType}'),
                  const SizedBox(height: 8),
                  _summaryRow('Overtime', overtimeMinutes > 0 ? '$overtimeMinutes min / JOD ${overtimeFare.toStringAsFixed(2)}' : 'None'),
                  if (overtimeMinutes > 0) ...[
                    const SizedBox(height: 8),
                    _summaryRow('Overtime Status', overtimeStatus),
                  ],
                  const Divider(height: 20),
                  _summaryRow('Final Amount', 'JOD ${finalFare.toStringAsFixed(2)}', highlight: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: joRideAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                // Close dialog and route to the post-trip inspection page
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostTripInspectionScreen(
                      car: widget.car,
                      finalFare: finalFare,
                    ),
                  ),
                  (route) => false,
                );
              },
              child: const Text('Inspect & Continue',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: highlight ? 15 : 13)),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: highlight ? 18 : 13, color: highlight ? joRideAccent : Colors.black87))),
      ],
    );
  }

  Widget _rateChip(String title, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(999)),
    child: Text('$title: $value', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
  );

  /// Control button that lights up like the door lock when toggled on.
  /// Same glow/halo treatment as the lock circle — different colors per
  /// control (amber Horn, cyan AC, warm yellow Lights). No snackbar — the
  /// visual state IS the feedback.
  Widget _controlBtn({
    required IconData icon,
    required String label,
    required bool isOn,
    required Color onColor,
    required VoidCallback onToggle,
  }) {
    final enabled = _hasKeyAccess;
    return GestureDetector(
      onTap: enabled ? onToggle : null,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isOn
                  ? onColor.withAlpha(38)            // same alpha as lock
                  : Colors.white.withOpacity(enabled ? 0.1 : 0.04),
              shape: BoxShape.circle,
              border: Border.all(
                color: isOn
                    ? onColor
                    : Colors.transparent,
                width: isOn ? 3 : 0,                  // matches lock border
              ),
              boxShadow: isOn
                  ? [
                      BoxShadow(
                        color: onColor.withAlpha(80), // matches lock halo
                        blurRadius: 35,
                        spreadRadius: 2,
                      ),
                    ]
                  : const [],
            ),
            child: Icon(
              icon,
              color: isOn
                  ? onColor
                  : (enabled ? Colors.white : Colors.white24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isOn
                  ? onColor
                  : (enabled ? Colors.white70 : Colors.white24),
              fontSize: 12,
              fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expired = _overtimeSeconds > 0;
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        // Wrap in scrollable to prevent the bottom overflow yellow-stripe error.
        child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 0)), (route) => false),
                    child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Colors.white, size: 22)),
                  ),
                  Expanded(child: Center(child: Text(expired ? 'Overtime Active' : 'Trip Active', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Text(widget.car['model'] ?? 'Vehicle', style: const TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text('Plate: ${widget.car['plate'] ?? '---'}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 24),
            Text(expired ? '+${_format(_overtimeSeconds)}' : _format(_remainingSeconds), style: TextStyle(color: expired ? Colors.redAccent : Colors.white, fontSize: 48, fontWeight: FontWeight.w200, letterSpacing: 4)),
            const SizedBox(height: 8),
            Text(expired ? 'Overtime Running' : 'Time Remaining', style: TextStyle(color: expired ? Colors.redAccent : Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Text('Paid: JOD ${widget.paidTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold)),
            if (expired) ...[
              const SizedBox(height: 8),
              Text('Overtime: JOD ${_overtimeCharge.toStringAsFixed(2)} • $_overtimeLabel', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              _rateChip('Access', _hasKeyAccess ? 'Paid & Active' : 'No Key'),
              _rateChip('Billing', _overtimeSeconds > 0 ? _overtimeBillingUnit : widget.rateType),
            ]),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _keyLoading ? null : _toggleLock,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: isCarLocked ? Colors.red.withOpacity(0.06) : Colors.green.withOpacity(0.06),
                  shape: BoxShape.circle,
                  border: Border.all(color: isCarLocked ? Colors.redAccent : Colors.greenAccent, width: 3),
                  boxShadow: [BoxShadow(color: (isCarLocked ? Colors.redAccent : Colors.greenAccent).withOpacity(0.15), blurRadius: 35, spreadRadius: 2)],
                ),
                child: _keyLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Icon(isCarLocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded, size: 64, color: isCarLocked ? Colors.redAccent : Colors.greenAccent),
              ),
            ),
            const SizedBox(height: 14),
            Text(isCarLocked ? 'DOORS LOCKED' : 'DOORS UNLOCKED', style: TextStyle(color: isCarLocked ? Colors.redAccent : Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlBtn(
                  icon: Icons.volume_up_rounded,
                  label: 'Horn',
                  isOn: _hornOn,
                  onColor: const Color(0xFFFFC857),
                  onToggle: () => setState(() => _hornOn = !_hornOn),
                ),
                _controlBtn(
                  icon: Icons.ac_unit_rounded,
                  label: 'AC',
                  isOn: _acOn,
                  onColor: const Color(0xFF4FC3F7),
                  onToggle: () => setState(() => _acOn = !_acOn),
                ),
                _controlBtn(
                  icon: _lightsOn
                      ? Icons.lightbulb_rounded
                      : Icons.lightbulb_outline_rounded,
                  label: 'Lights',
                  isOn: _lightsOn,
                  onColor: const Color(0xFFFFE082),
                  onToggle: () => setState(() => _lightsOn = !_lightsOn),
                ),
              ],
            ),
            // Replaced Spacer() with fixed gap (Spacer doesn't work inside SingleChildScrollView)
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _endingTrip ? null : _endTrip,
                  child: _endingTrip
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text('End Trip', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        ),  // close SingleChildScrollView
      ),
    );
  }
}
