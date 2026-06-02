import 'package:flutter/material.dart';

import 'Checkout.dart';
import 'l10n/app_localizations.dart';
import 'widgets/car_image.dart';

const Color _kBrand = Color(0xFF13366B);

/// Shown between CarDetailsScreen and CheckoutScreen.
/// The user documents car condition (4 angles) before confirming the booking.
class CarInspectionScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final double total;
  final int duration;
  final String durationType;

  const CarInspectionScreen({
    super.key,
    required this.car,
    required this.total,
    required this.duration,
    required this.durationType,
  });

  @override
  State<CarInspectionScreen> createState() => _CarInspectionScreenState();
}

class _CarInspectionScreenState extends State<CarInspectionScreen> {
  final _noteCtrl = TextEditingController();
  double _cleanliness = 8; // initial cleanliness rating out of 10

  // Simulated "photos taken" flags for each angle
  final Map<String, bool> _captured = {
    'front_left':  false,
    'front_right': false,
    'rear_left':   false,
    'rear_right':  false,
  };

  /// Map rating value to a color (red < 4 ≤ orange < 7 ≤ green).
  Color _ratingColor(double v) {
    if (v >= 7) return Colors.green;
    if (v >= 4) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _toggleCapture(String key) =>
      setState(() => _captured[key] = !(_captured[key] ?? false));

  void _proceed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          car: widget.car,
          total: widget.total,
          duration: widget.duration,
          type: widget.durationType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('inspection_title')),
        backgroundColor: _kBrand,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car info strip
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kBrand.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CarImage(car: widget.car, height: 52, width: 80),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.car['model'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Plate: ${widget.car['plate'] ?? ''}',
                          style: TextStyle(
                              color: cs.onSurface.withAlpha(150),
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Subtitle — clearly before driving
            Text(l.t('inspection_subtitle_before'),
                style:
                    TextStyle(color: cs.onSurface.withAlpha(170), fontSize: 13)),
            const SizedBox(height: 4),
            Text(l.t('inspection_before'),
                style: const TextStyle(
                    color: _kBrand,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 16),

            // 4-angle photo grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.15,
              children: [
                _photoCard('front_left',  l.t('inspection_front_left'),  isDark, cs),
                _photoCard('front_right', l.t('inspection_front_right'), isDark, cs),
                _photoCard('rear_left',   l.t('inspection_rear_left'),   isDark, cs),
                _photoCard('rear_right',  l.t('inspection_rear_right'),  isDark, cs),
              ],
            ),
            const SizedBox(height: 24),

            // ── Cleanliness rating slider (out of 10) ─────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.t('cleanliness_rating'),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                        fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _ratingColor(_cleanliness).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_cleanliness.toStringAsFixed(0)} / 10',
                      style: TextStyle(
                          color: _ratingColor(_cleanliness),
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(l.t('cleanliness_subtitle'),
                style: TextStyle(
                    color: cs.onSurface.withAlpha(150), fontSize: 12)),
            Slider(
              value: _cleanliness,
              min: 0,
              max: 10,
              divisions: 10,
              activeColor: _ratingColor(_cleanliness),
              label: _cleanliness.toStringAsFixed(0),
              onChanged: (v) => setState(() => _cleanliness = v),
            ),
            const SizedBox(height: 16),

            // Notes field
            Text(l.t('inspection_note'),
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. minor scratch on rear bumper…',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2A2A3E)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 28),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBrand,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _proceed,
                icon: const Icon(Icons.check_circle_outline,
                    color: Colors.white),
                label: Text(l.t('inspection_confirm'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),

            // Skip link
            Center(
              child: TextButton(
                onPressed: _proceed,
                child: Text('Skip inspection',
                    style: TextStyle(
                        color: cs.onSurface.withAlpha(120), fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tappable photo placeholder for one angle of the car.
  Widget _photoCard(
      String key, String label, bool isDark, ColorScheme cs) {
    final taken = _captured[key] ?? false;
    return GestureDetector(
      onTap: () => _toggleCapture(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: taken
              ? Colors.green.withAlpha(20)
              : (isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: taken ? Colors.green : cs.onSurface.withAlpha(40),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              taken ? Icons.check_circle : Icons.camera_alt_outlined,
              size: 36,
              color: taken ? Colors.green : cs.onSurface.withAlpha(120),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: taken ? Colors.green : cs.onSurface)),
            const SizedBox(height: 4),
            Text(taken ? 'Captured ✓' : 'Tap to mark',
                style: TextStyle(
                    fontSize: 10,
                    color: taken
                        ? Colors.green
                        : cs.onSurface.withAlpha(100))),
          ],
        ),
      ),
    );
  }
}
