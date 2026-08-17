import 'package:flutter/material.dart';
import 'Home Screen.dart';
import 'services/api_service.dart';

const Color _kBrand = Color(0xFF13366B);

class RateTripScreen extends StatefulWidget {
  final String tripId;
  final String vehicleModel;

  const RateTripScreen({
    super.key,
    required this.tripId,
    this.vehicleModel = 'Vehicle',
  });

  @override
  State<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends State<RateTripScreen> {
  int _stars = 0;
  final _commentCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _photoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.submitRating(
        tripId: widget.tripId,
        stars: _stars,
        comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
        conditionPhotoUrl: _photoUrlCtrl.text.trim().isEmpty ? null : _photoUrlCtrl.text.trim(),
      );
      if (!mounted) return;
      _showSuccess();
    } on ApiException catch (e) {
      if (!mounted) return;
      // 409 = already rated — treat as success
      if (e.statusCode == 409) {
        _showSuccess(alreadyRated: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccess({bool alreadyRated = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 64),
            const SizedBox(height: 14),
            Text(
              alreadyRated ? 'Already Rated' : 'Thank You!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              alreadyRated
                  ? 'You already submitted a rating for this trip.'
                  : 'Your rating helps us improve the experience.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBrand,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pushAndRemoveUntil(
                ctx,
                MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 0)),
                (_) => false,
              ),
              child: const Text('Back to Home',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Trip'),
        backgroundColor: _kBrand,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Vehicle label ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kBrand.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.directions_car, color: _kBrand, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.vehicleModel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ]),
            ),

            const SizedBox(height: 28),

            // ── Stars ────────────────────────────────────────────────────
            const Text('Overall Experience',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _stars;
                return GestureDetector(
                  onTap: () => setState(() => _stars = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 48,
                      color: filled ? Colors.amber : Colors.grey.shade400,
                    ),
                  ),
                );
              }),
            ),
            if (_stars > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(_starLabel(_stars),
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ),

            const SizedBox(height: 28),

            // ── Comment ──────────────────────────────────────────────────
            const Text('Comments (optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Anything to add about the car or your experience?',
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 16),

            // ── Photo URL ────────────────────────────────────────────────
            const Text('Car Condition Photo URL (optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Upload your photo to Firebase Storage and paste the URL here.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: _photoUrlCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://storage.googleapis.com/...',
                prefixIcon: const Icon(Icons.photo_camera_outlined, color: _kBrand),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 32),

            // ── Submit ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBrand,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(_submitting ? 'Submitting…' : 'Submit Rating',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 0)),
                  (_) => false,
                ),
                child: const Text('Skip for now', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _starLabel(int stars) => switch (stars) {
        1 => 'Poor',
        2 => 'Fair',
        3 => 'Good',
        4 => 'Very Good',
        5 => 'Excellent',
        _ => '',
      };
}
