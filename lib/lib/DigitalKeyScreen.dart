import 'package:flutter/material.dart';
import 'Home Screen.dart';
import 'PostTripInspectionScreen.dart';
import 'ReturnZoneScreen.dart';
import 'services/api_service.dart';
import 'widgets/end_trip_dialog.dart';

class DigitalKeyScreen extends StatefulWidget {
  final Map<String, dynamic>? car;
  final String? tripId;
  const DigitalKeyScreen({super.key, this.car, this.tripId});

  @override
  State<DigitalKeyScreen> createState() => _DigitalKeyScreenState();
}

class _DigitalKeyScreenState extends State<DigitalKeyScreen> {
  bool isLocked = true;
  bool _hasAccess = false;
  bool _keyLoading = false;
  // On/off state of each control — used to light up the buttons.
  bool _hornOn   = false;
  bool _acOn     = false;
  bool _lightsOn = false;
  Map<String, dynamic>? _car;
  String? _tripId;
  static const Color darkBg = Color(0xFF131A2D);
  static const Color joRideAccent = Color(0xFF13366B);

  @override
  void initState() {
    super.initState();
    _car = widget.car;
    _tripId = widget.tripId;
    _restoreAndFetch();
  }

  Future<void> _restoreAndFetch() async {
    if (_car == null || _tripId == null) {
      final saved = await ApiService.getSavedActiveRental();
      if (saved != null) {
        _car = Map<String, dynamic>.from(saved['car'] as Map);
        _tripId = saved['tripId']?.toString();
      }
    }
    if (_car == null || _tripId == null) {
      final activeTrip = await ApiService.getActiveTrip();
      if (activeTrip != null) {
        final vehicle = await ApiService.getVehicle(activeTrip.vehicleId.toString());
        _car = vehicle.toMap();
        _tripId = activeTrip.id;
        await ApiService.saveActiveRental(car: _car!, trip: activeTrip);
      }
    }
    if (_tripId != null) await _fetchKeyStatus();
    if (mounted) setState(() {});
  }

  Future<void> _fetchKeyStatus() async {
    try {
      final status = await ApiService.getKeyStatus(_tripId!);
      if (mounted) {
        setState(() {
          isLocked = (status['isLocked'] as bool?) ?? true;
          _hasAccess = (status['hasAccess'] as bool?) ?? false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasAccess = false);
    }
  }

  /// Ends the current trip from the Your Key tab.
  /// Flow: pretty confirmation dialog → Amman return-zone check → backend
  /// end-trip call → post-trip inspection.
  Future<void> _endTrip() async {
    if (_tripId == null || _car == null) return;

    // 1) Beautiful confirmation dialog (shared widget).
    final confirmed = await showEndTripConfirmation(context);
    if (!confirmed || !mounted) return;

    // 2) Geofence check — make sure the car is parked inside Amman.
    final insideZone = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReturnZoneScreen(car: _car!)),
    );
    if (insideZone != true || !mounted) return;

    try {
      final ended = await ApiService.endTrip(_tripId!);
      await ApiService.clearActiveRental();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PostTripInspectionScreen(
            car: _car!,
            finalFare: ended.totalFare ?? 0,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleLock() async {
    if (!_hasAccess || _tripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digital key appears only after successful payment.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _keyLoading = true);
    try {
      if (isLocked) {
        await ApiService.unlockCar(_tripId!);
      } else {
        await ApiService.lockCar(_tripId!);
      }
      if (mounted) setState(() => isLocked = !isLocked);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _keyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_car == null || !_hasAccess) return _noKeyScreen();
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: SingleChildScrollView(               // ← fixes the 63 px overflow
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Stack(
                children: [
                  Positioned(top: 15, left: 15, child: _homeButton()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        const Text('Smart Digital Key',
                            style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.5)),
                        const SizedBox(height: 8),
                        Text(_car!['model'] ?? 'Active Vehicle',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        // Brand logo if available
                        if ((_car!['brandLogo'] as String? ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Image.network(
                            _car!['brandLogo'] as String,
                            height: 32,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _statusIndicator(),
                        const SizedBox(height: 40),
                        GestureDetector(
                          onTap: _keyLoading ? null : _toggleLock,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                                color: isLocked
                                    ? Colors.red.withAlpha(13)
                                    : Colors.green.withAlpha(13),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isLocked ? Colors.redAccent : Colors.greenAccent,
                                    width: 4),
                                boxShadow: [
                                  BoxShadow(
                                      color: (isLocked ? Colors.redAccent : Colors.greenAccent)
                                          .withAlpha(38),
                                      blurRadius: 40,
                                      spreadRadius: 2)
                                ]),
                            child: _keyLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 3))
                                : Icon(
                                    isLocked
                                        ? Icons.lock_outline_rounded
                                        : Icons.lock_open_rounded,
                                    size: 80,
                                    color: isLocked ? Colors.redAccent : Colors.greenAccent),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(isLocked ? 'DOORS LOCKED' : 'DOORS UNLOCKED',
                            style: TextStyle(
                                color: isLocked ? Colors.redAccent : Colors.greenAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
                        const SizedBox(height: 40),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _controlBtn(
                                  icon: Icons.volume_up_rounded,
                                  label: 'Horn',
                                  isOn: _hornOn,
                                  onColor: const Color(0xFFFFC857),
                                  onTap: () => setState(() => _hornOn = !_hornOn)),
                              _controlBtn(
                                  icon: Icons.ac_unit_rounded,
                                  label: _acOn ? 'AC On' : 'AC',
                                  isOn: _acOn,
                                  onColor: const Color(0xFF4FC3F7),
                                  onTap: () => setState(() => _acOn = !_acOn)),
                              _controlBtn(
                                  icon: Icons.lightbulb_rounded,
                                  label: 'Lights',
                                  isOn: _lightsOn,
                                  onColor: const Color(0xFFFFE082),
                                  onTap: () => setState(() => _lightsOn = !_lightsOn)),
                            ]),
                        const SizedBox(height: 36),
                        // ── End Trip button — works directly from Your Key ──
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _endTrip,
                            icon: const Icon(Icons.flag, color: Colors.white),
                            label: const Text('End Trip',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noKeyScreen() {
    return Scaffold(
      backgroundColor: darkBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.vpn_key_outlined, size: 100, color: Colors.white10),
            const SizedBox(height: 20),
            const Text('No Active Key Found', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('The digital key is shown only after payment is confirmed and while the rental is active.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: joRideAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0), onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 0)), (route) => false), icon: const Icon(Icons.map_rounded, color: Colors.white), label: const Text('Book a Car Now', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
          ]),
        ),
      ),
    );
  }

  Widget _homeButton() => InkWell(onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 0)), (route) => false), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle), child: const Icon(Icons.home_rounded, color: Colors.white, size: 28)));

  Widget _statusIndicator() => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(radius: 4, backgroundColor: Colors.greenAccent), SizedBox(width: 8), Text('Paid & Online', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600))]));

  /// Control button that visibly lights up when [isOn] is true:
  /// the background glows, the icon takes the [onColor], and an outer
  /// halo shadow appears for a "powered on" feel.
  Widget _controlBtn({
    required IconData icon,
    required String label,
    required bool isOn,
    required Color onColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOn ? '$label turned OFF' : '$label turned ON'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isOn
                  ? onColor.withAlpha(55)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOn ? onColor : Colors.white10,
                width: isOn ? 2 : 1,
              ),
              boxShadow: isOn
                  ? [
                      BoxShadow(
                        color: onColor.withAlpha(140),
                        blurRadius: 22,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isOn ? onColor : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: isOn ? onColor : Colors.white60,
              fontSize: 12,
              fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
