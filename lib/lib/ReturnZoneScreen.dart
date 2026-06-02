import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

const Color _kBrand = Color(0xFF13366B);
const Color _kZone  = Color(0xFF1ABC9C); // teal — matches ekar-style return zone

/// Shown BEFORE ending a trip — confirms the car is parked inside the
/// allowed Amman return zone. The user must tap "Confirm Parking Location"
/// (which pops `true`) to proceed with the actual end-trip flow.
///
/// This is a UI-level geofence check (no real GPS yet). It exists so the
/// flow visually mirrors the ekar reference: a city silhouette + reminder
/// to park inside it before completing the rental.
class ReturnZoneScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  const ReturnZoneScreen({super.key, required this.car});

  @override
  State<ReturnZoneScreen> createState() => _ReturnZoneScreenState();
}

class _ReturnZoneScreenState extends State<ReturnZoneScreen> {
  // Simulated "inside zone" flag. In a real build this would come from
  // comparing live GPS to the Amman polygon. We default to true so the
  // happy path is clear; the toggle lets the user simulate "outside".
  bool _insideZone = true;

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF131A2D) : const Color(0xFFF8F9FD);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l.t('return_zone_title')),
        backgroundColor: _kBrand,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              // Reminder text
              Text(
                l.t('return_zone_msg'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurface.withAlpha(200),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // ── Amman outline map ──────────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E2E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cs.onSurface.withAlpha(30),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Faint grid background to feel "map-like"
                      CustomPaint(
                        size: Size.infinite,
                        painter: _GridPainter(
                          color: cs.onSurface.withAlpha(15),
                        ),
                      ),
                      // The actual Amman silhouette
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: CustomPaint(
                          painter: _AmmanOutlinePainter(),
                          child: const SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      // City label
                      Positioned(
                        top: 12,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kBrand,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_city,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                l.t('amman_city'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Pin in the middle (user's parked car)
                      const Icon(Icons.location_pin,
                          color: Colors.redAccent, size: 36),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Status banner ──────────────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _insideZone = !_insideZone),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _insideZone
                        ? Colors.green.withAlpha(30)
                        : Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _insideZone ? Colors.green : Colors.red,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _insideZone
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        color: _insideZone ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _insideZone
                              ? l.t('return_zone_inside')
                              : l.t('return_zone_outside'),
                          style: TextStyle(
                            color: _insideZone ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Action buttons ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _insideZone ? _kBrand : Colors.grey,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed:
                      _insideZone ? () => Navigator.pop(context, true) : null,
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white),
                  label: Text(
                    l.t('return_zone_confirm'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  l.t('return_zone_cancel'),
                  style: TextStyle(
                    color: cs.onSurface.withAlpha(150),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Light grid lines behind the outline so the panel feels like a map.
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}

/// Stylized Amman silhouette — irregular blob centered in the canvas.
/// Not geographically accurate; the shape conveys "city return zone" the
/// same way the ekar reference does.
class _AmmanOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Normalized control points (0..1) that trace a city-like blob.
    final pts = <Offset>[
      Offset(0.20 * w, 0.30 * h),
      Offset(0.10 * w, 0.45 * h),
      Offset(0.14 * w, 0.62 * h),
      Offset(0.25 * w, 0.78 * h),
      Offset(0.40 * w, 0.85 * h),
      Offset(0.58 * w, 0.83 * h),
      Offset(0.74 * w, 0.74 * h),
      Offset(0.86 * w, 0.60 * h),
      Offset(0.88 * w, 0.42 * h),
      Offset(0.78 * w, 0.26 * h),
      Offset(0.60 * w, 0.18 * h),
      Offset(0.42 * w, 0.16 * h),
      Offset(0.28 * w, 0.22 * h),
    ];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final curr = pts[i];
      final mid  = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    path.close();

    // Fill (semi-transparent teal)
    final fill = Paint()
      ..color = _kZone.withAlpha(80)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    // Outline
    final stroke = Paint()
      ..color = _kZone
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
