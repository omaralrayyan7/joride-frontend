import 'package:flutter/material.dart';

class DrivingLicenseScreen extends StatefulWidget {
  final String? licenseNumber;

  const DrivingLicenseScreen({super.key, this.licenseNumber});

  @override
  State<DrivingLicenseScreen> createState() => _DrivingLicenseScreenState();
}

class _DrivingLicenseScreenState extends State<DrivingLicenseScreen> {
  static const Color joRideAccent = Color(0xFF13366B);
  static const Color scaffoldBg = Color(0xFFF8F9FD);

  bool get _hasLicense =>
      widget.licenseNumber != null && widget.licenseNumber!.isNotEmpty;

  String _maskLicense(String num) {
    if (num.length <= 4) return num;
    final first = num.substring(0, 2);
    final last = num.substring(num.length - 2);
    final masked = '*' * (num.length - 4);
    return '$first$masked$last';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('Driving License',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: joRideAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _hasLicense ? _buildLicenseView() : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_membership_outlined,
              size: 90, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'No License on File',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your driving license details will appear here\nonce they have been verified.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // ─── License Card ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            height: 210,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D1B3E), Color(0xFF1A3D7C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D1B3E).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: country + car icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HASHEMITE KINGDOM OF JORDAN',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.directions_car_rounded,
                        color: Colors.white54, size: 20),
                  ],
                ),

                const SizedBox(height: 18),

                // License number
                Text(
                  _maskLicense(widget.licenseNumber!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 10),

                // License class
                const Text(
                  'License Class: B',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                // Valid until
                const Text(
                  'Valid Until: 2027-06-01',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),

                const Spacer(),

                // Bottom row: status
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ─── Info Tiles ───────────────────────────────────────────────
          const Text(
            'License Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: joRideAccent,
            ),
          ),
          const SizedBox(height: 14),

          _infoTile(
            icon: Icons.class_outlined,
            title: 'License Class',
            value: 'B - Private Vehicle',
          ),
          _infoTile(
            icon: Icons.account_balance_outlined,
            title: 'Issued By',
            value: 'Traffic Department, Jordan',
          ),
          _infoTile(
            icon: Icons.check_circle_outline,
            title: 'Status',
            value: 'Active & Valid',
            valueColor: Colors.green,
          ),
          _infoTile(
            icon: Icons.calendar_month_outlined,
            title: 'Expiry Date',
            value: 'June 1, 2027',
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: joRideAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: joRideAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF131A2D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
