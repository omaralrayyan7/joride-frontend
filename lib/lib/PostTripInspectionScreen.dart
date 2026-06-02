import 'package:flutter/material.dart';

import 'Home Screen.dart';
import 'l10n/app_localizations.dart';
import 'widgets/car_image.dart';

const Color _kBrand = Color(0xFF13366B);

/// Shown after a user ends their trip — collects 4-angle photos, cleanliness
/// rating (out of 10), and optional notes. UI-only return-condition record.
class PostTripInspectionScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final double finalFare;

  const PostTripInspectionScreen({
    super.key,
    required this.car,
    required this.finalFare,
  });

  @override
  State<PostTripInspectionScreen> createState() =>
      _PostTripInspectionScreenState();
}

class _PostTripInspectionScreenState extends State<PostTripInspectionScreen> {
  final _noteCtrl = TextEditingController();
  double _cleanliness = 8; // out of 10

  final Map<String, bool> _captured = {
    'front_left':  false,
    'front_right': false,
    'rear_left':   false,
    'rear_right':  false,
  };

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _toggle(String key) =>
      setState(() => _captured[key] = !(_captured[key] ?? false));

  void _submit() {
    // UI-only — show success then return home
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 70),
            const SizedBox(height: 14),
            const Text('Inspection Submitted',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'Cleanliness rating: ${_cleanliness.toStringAsFixed(0)} / 10',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(170)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBrand,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pushAndRemoveUntil(
                ctx,
                MaterialPageRoute(
                    builder: (_) => const HomeScreen(initialIndex: 0)),
                (_) => false,
              ),
              child: const Text('Back to Home',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
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
        title: Text('${l.t('inspection_after')} — ${l.t('inspection_title')}'),
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
            // Trip summary card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kBrand.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CarImage(car: widget.car, height: 56, width: 80),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.car['model'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Plate: ${widget.car['plate'] ?? ''}',
                            style: TextStyle(
                                color: cs.onSurface.withAlpha(150),
                                fontSize: 12)),
                        Text(
                            'Final fare: ${widget.finalFare.toStringAsFixed(2)} JOD',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Photo grid — clearly after driving
            Text(l.t('inspection_subtitle_after'),
                style: TextStyle(
                    color: cs.onSurface.withAlpha(170), fontSize: 13)),
            const SizedBox(height: 12),
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

            // Cleanliness slider
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
                  child: Text(
                    '${_cleanliness.toStringAsFixed(0)} / 10',
                    style: TextStyle(
                        color: _ratingColor(_cleanliness),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(l.t('cleanliness_subtitle'),
                style: TextStyle(
                    color: cs.onSurface.withAlpha(150), fontSize: 12)),
            const SizedBox(height: 8),
            Slider(
              value: _cleanliness,
              min: 0,
              max: 10,
              divisions: 10,
              activeColor: _ratingColor(_cleanliness),
              label: _cleanliness.toStringAsFixed(0),
              onChanged: (v) => setState(() => _cleanliness = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0',
                    style: TextStyle(
                        color: cs.onSurface.withAlpha(120), fontSize: 11)),
                Text('10',
                    style: TextStyle(
                        color: cs.onSurface.withAlpha(120), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 22),

            // Notes
            Text(l.t('inspection_note'),
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. new scratch on rear door...',
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBrand,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_outline,
                    color: Colors.white),
                label: Text(l.t('inspection_confirm'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _ratingColor(double v) {
    if (v >= 7) return Colors.green;
    if (v >= 4) return Colors.orange;
    return Colors.red;
  }

  Widget _photoCard(
      String key, String label, bool isDark, ColorScheme cs) {
    final taken = _captured[key] ?? false;
    return GestureDetector(
      onTap: () => _toggle(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: taken
              ? Colors.green.withAlpha(20)
              : (isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: taken ? Colors.green : cs.onSurface.withAlpha(40),
              width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(taken ? Icons.check_circle : Icons.camera_alt_outlined,
                size: 36,
                color: taken ? Colors.green : cs.onSurface.withAlpha(120)),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: taken ? Colors.green : cs.onSurface)),
          ],
        ),
      ),
    );
  }
}
