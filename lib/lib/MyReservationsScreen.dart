import 'package:flutter/material.dart';
import 'dart:async';

import 'FareMeterScreen.dart';
import 'PostTripInspectionScreen.dart';
import 'ReturnZoneScreen.dart';
import 'models/auth_models.dart';
import 'services/api_service.dart';
import 'widgets/car_image.dart';
import 'widgets/end_trip_dialog.dart';

class MyReservationsScreen extends StatefulWidget {
  final Map<String, dynamic>? bookedCar;
  final int? duration;
  final String? type;
  final String? tripId;

  const MyReservationsScreen({
    super.key,
    this.bookedCar,
    this.duration,
    this.type,
    this.tripId,
  });

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  Map<String, dynamic>? _activeCar;
  Trip? _activeTrip;
  List<Trip> _pastTrips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  Future<void> _loadReservations() async {
    setState(() => _loading = true);
    try {
      final trips = await ApiService.getMyTrips();
      final active = trips.where((t) => t.isActivePaid).toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
      final saved = await ApiService.getSavedActiveRental();

      Map<String, dynamic>? car = widget.bookedCar;
      Trip? trip = active.isNotEmpty ? active.first : null;

      if (saved != null && trip != null && saved['tripId'].toString() == trip.id) {
        car = Map<String, dynamic>.from(saved['car'] as Map);
      }

      if (car == null && trip != null) {
        final vehicle = await ApiService.getVehicle(trip.vehicleId.toString());
        car = vehicle.toMap();
      }

      if (mounted) {
        setState(() {
          _activeTrip = trip;
          _activeCar = car;
          _pastTrips = trips.where((t) => t.isCompleted).toList()
            ..sort((a, b) => b.startTime.compareTo(a.startTime));
          _loading = false;
        });
        _updateCountdown();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updateCountdown() {
    final end = _activeTrip?.scheduledEndTime;
    if (end == null || !mounted) return;
    final seconds = end.difference(DateTime.now()).inSeconds;
    setState(() => _remainingSeconds = seconds);
  }

  String _formatDuration(int totalSeconds) {
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (days > 0) return "${days}d ${hours}h ${minutes}m ${seconds}s";
    if (hours > 0) return "${hours}h ${minutes}m ${seconds}s";
    return "${minutes}m ${seconds}s";
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Ends the current active trip directly from My Reservations.
  /// Flow: pretty confirmation → Amman return-zone check → backend end-trip
  /// → post-trip inspection page.
  Future<void> _endActiveTrip() async {
    final trip = _activeTrip;
    final car  = _activeCar;
    if (trip == null || car == null) return;

    // 1) Beautiful confirmation dialog (shared widget).
    final confirmed = await showEndTripConfirmation(context);
    if (!confirmed || !mounted) return;

    // 2) Geofence check — must be parked inside Amman.
    final insideZone = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReturnZoneScreen(car: car)),
    );
    if (insideZone != true || !mounted) return;

    _timer?.cancel();
    try {
      final ended = await ApiService.endTrip(trip.id);
      await ApiService.clearActiveRental();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PostTripInspectionScreen(
            car: car,
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
        // Restart countdown if end failed
        _timer = Timer.periodic(
            const Duration(seconds: 1), (_) => _updateCountdown());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final joRideAccent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadReservations,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 30),
            Text('My Reservations', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: joRideAccent)),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_activeTrip != null && _activeCar != null)
              _buildActiveReservationCard(joRideAccent)
            else
              const Padding(padding: EdgeInsets.symmetric(vertical: 50), child: Center(child: Text('No active reservations', style: TextStyle(color: Colors.grey)))),
            const SizedBox(height: 30),
            const Text('Past History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            if (_pastTrips.isEmpty)
              const Text('No past trips yet.', style: TextStyle(color: Colors.grey))
            else
              ..._pastTrips.map((trip) => _buildPastReservationItem('Vehicle #${trip.vehicleId}', trip.status, _formatDate(trip.startTime), trip.totalFare != null ? '${trip.totalFare!.toStringAsFixed(2)} JOD' : '')).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveReservationCard(Color accent) {
    final trip = _activeTrip!;
    final car = _activeCar!;
    final totalSeconds = trip.scheduledEndTime?.difference(trip.startTime).inSeconds ?? _remainingSeconds;
    final remainingPositive = _remainingSeconds > 0 ? _remainingSeconds : 0;
    final overtimeSeconds = _remainingSeconds < 0 ? _remainingSeconds.abs() : 0;
    final progress = totalSeconds <= 0 ? 0.0 : (remainingPositive / totalSeconds).clamp(0.0, 1.0);
    final cardColor = Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10)],
          border: Border.all(color: accent.withAlpha(25))),
      child: Column(
        children: [
          Row(children: [
            CarImage(car: car, width: 80, height: 60),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(car['model'] ?? 'Vehicle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('Paid · Digital Key Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              Text('Until: ${_formatDate(trip.scheduledEndTime ?? DateTime.now())}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
          ]),
          const Divider(height: 30),
          Text(overtimeSeconds > 0 ? 'Overtime Running' : 'Time Remaining', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 5),
          Text(overtimeSeconds > 0 ? '+${_formatDuration(overtimeSeconds)}' : _formatDuration(remainingPositive), style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: overtimeSeconds > 0 ? Colors.redAccent : accent, letterSpacing: 1)),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], color: accent, borderRadius: BorderRadius.circular(10)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FareMeterScreen(
                            car: car,
                            tripId: trip.id,
                            rateType: trip.durationType,
                            duration: trip.duration,
                            scheduledEndTime: trip.scheduledEndTime,
                            paidTotal: trip.totalFare ?? 0)));
              },
              icon: const Icon(Icons.vpn_key, color: Colors.white),
              label: const Text('Open Digital Key & Timer',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          // ── End Trip button — works directly from My Reservations ──
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _endActiveTrip,
              icon: const Icon(Icons.flag, color: Colors.red),
              label: const Text('End Trip',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastReservationItem(String model, String status, String date, String fare) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(leading: const Icon(Icons.history, color: Colors.grey), title: Text(model), subtitle: Text('$date${fare.isNotEmpty ? '  ·  $fare' : ''}'), trailing: Text(status, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
    );
  }
}
