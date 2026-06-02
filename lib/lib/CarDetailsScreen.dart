import 'package:flutter/material.dart';
import 'CarInspectionScreen.dart';
import 'widgets/car_image.dart';

/// Car detail screen — shown when user taps a car on the map.
/// Displays specs, rental plan picker, and brand logo.
class CarDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  const CarDetailsScreen({super.key, required this.car});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  String selectedType = 'min'; // min | hour | day
  int days    = 0;
  int hours   = 0;
  int minutes = 1;

  static const Color joRideAccent = Color(0xFF13366B);

  /// Total booked duration expressed in minutes (for pricing calculation).
  int get totalMinutes => days * 1440 + hours * 60 + minutes;

  /// Dominant unit used for backend DurationType.
  String get dominantType {
    if (days > 0) return 'day';
    if (hours > 0) return 'hour';
    return 'min';
  }

  /// Duration value sent to the backend (in units of dominantType).
  int get backendDuration {
    if (days > 0) {
      // convert to whole days, rounding up for any leftover hours/minutes
      final extra = (hours > 0 || minutes > 0) ? 1 : 0;
      return days + extra;
    }
    if (hours > 0) {
      final extra = minutes > 0 ? 1 : 0;
      return hours + extra;
    }
    return minutes.clamp(1, 99999);
  }

  Map<String, double> get _rates {
    final raw = widget.car['rates'];
    if (raw is Map) {
      return {
        'min':  ((raw['min']  as num?) ?? 0.15).toDouble(),
        'hour': ((raw['hour'] as num?) ?? 8.0).toDouble(),
        'day':  ((raw['day']  as num?) ?? 45.0).toDouble(),
      };
    }
    return const {'min': 0.15, 'hour': 8.0, 'day': 45.0};
  }

  double get totalPrice {
    final r = _rates;
    return (days * (r['day'] ?? 45.0)) +
           (hours * (r['hour'] ?? 8.0)) +
           (minutes * (r['min'] ?? 0.15));
  }

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Container(
              color: bgColor,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(cs),
                  const SizedBox(height: 24),
                  Text('Specifications',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface)),
                  const SizedBox(height: 14),
                  _buildSpecs(cs, isDark),
                  Divider(height: 44, color: cs.onSurface.withAlpha(30)),
                  Text('Select Rental Duration',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface)),
                  const SizedBox(height: 16),
                  _buildFlexiblePicker(context, isDark),
                  const SizedBox(height: 12),
                  _buildDurationSummary(cs),
                  const SizedBox(height: 30),
                  _buildPriceSummary(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// SliverAppBar with car image hero + brand logo overlay + back button.
  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    final brandLogo = (widget.car['brandLogo'] as String?) ?? '';
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: joRideAccent,
      foregroundColor: Colors.white,
      // Back arrow stays visible against the white hero — wrapped in a
      // dark translucent circle so it never blends into the bg.
      leading: Padding(
        padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6),
        child: Material(
          color: Colors.black.withAlpha(110),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              alignment: Alignment.center,
              child: Hero(
                tag: widget.car['id'],
                // CarImage = local asset → network → clean icon (no more
                // giant generic car icon taking the whole hero area).
                child: CarImage(
                  car: widget.car,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Brand logo bottom-left
            if (brandLogo.isNotEmpty)
              Positioned(
                bottom: 12,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(30), blurRadius: 6)
                    ],
                  ),
                  child: Image.network(brandLogo,
                      height: 28,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.car['model'] ?? '',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface)),
              Text(widget.car['category'] ?? '',
                  style: TextStyle(color: cs.onSurface.withAlpha(160),
                      fontSize: 15)),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.green.withAlpha(25),
              borderRadius: BorderRadius.circular(10)),
          child: const Text('Ready',
              style: TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSpecs(ColorScheme cs, bool isDark) {
    final borderColor =
        isDark ? Colors.white.withAlpha(25) : Colors.grey.shade200;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _specItem(Icons.color_lens, 'Color',
            widget.car['color'] ?? '', cs, borderColor),
        _specItem(Icons.local_gas_station, 'Fuel',
            '${widget.car['fuel']}%', cs, borderColor),
        _specItem(Icons.pin, 'Plate',
            (widget.car['plate'] ?? '').toString().split(' ').first,
            cs, borderColor),
      ],
    );
  }

  Widget _specItem(IconData icon, String title, String value,
      ColorScheme cs, Color border) {
    return Container(
      width: 95,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: joRideAccent, size: 20),
          const SizedBox(height: 5),
          Text(title,
              style: TextStyle(
                  color: cs.onSurface.withAlpha(140), fontSize: 11)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: cs.onSurface)),
        ],
      ),
    );
  }

  /// Flexible duration picker: days + hours + minutes sliders.
  Widget _buildFlexiblePicker(BuildContext context, bool isDark) {
    return Column(
      children: [
        _pickerRow('Days', days, 0, 30,
            (v) => setState(() => days = v), isDark),
        const SizedBox(height: 10),
        _pickerRow('Hours', hours, 0, 23,
            (v) => setState(() => hours = v), isDark),
        const SizedBox(height: 10),
        _pickerRow('Minutes', minutes, 0, 59,
            (v) => setState(() => minutes = v.clamp(days == 0 && hours == 0 ? 1 : 0, 59)),
            isDark),
      ],
    );
  }

  Widget _pickerRow(String label, int value, int min, int max,
      ValueChanged<int> onChanged, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: cs.onSurface)),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            activeColor: joRideAccent,
            inactiveColor: isDark
                ? Colors.white.withAlpha(40)
                : Colors.grey.shade200,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildDurationSummary(ColorScheme cs) {
    final parts = <String>[];
    if (days > 0) parts.add('$days day${days > 1 ? 's' : ''}');
    if (hours > 0) parts.add('$hours hr${hours > 1 ? 's' : ''}');
    if (minutes > 0) parts.add('$minutes min');
    final summary = parts.isEmpty ? '0 min' : parts.join(' + ');
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: joRideAccent.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined,
              color: joRideAccent, size: 18),
          const SizedBox(width: 8),
          Text('Duration: $summary',
              style: const TextStyle(
                  color: joRideAccent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estimated Total',
                  style: TextStyle(
                      color: cs.onSurface.withAlpha(150), fontSize: 12)),
              Text('${totalPrice.toStringAsFixed(2)} JOD',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: joRideAccent)),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: joRideAccent,
              padding: const EdgeInsets.symmetric(
                  horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () {
              if (totalMinutes < 1) return;
              // Navigate to inspection before checkout
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CarInspectionScreen(
                    car: widget.car,
                    total: totalPrice,
                    duration: backendDuration,
                    durationType: dominantType,
                  ),
                ),
              );
            },
            child: const Text('Next',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
