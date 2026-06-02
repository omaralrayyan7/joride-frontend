import 'package:flutter/material.dart';

class IDVerificationScreen extends StatefulWidget {
  final String? idNumber;

  const IDVerificationScreen({super.key, this.idNumber});

  @override
  State<IDVerificationScreen> createState() => _IDVerificationScreenState();
}

class _IDVerificationScreenState extends State<IDVerificationScreen> {
  static const Color joRideAccent = Color(0xFF13366B);
  static const Color scaffoldBg = Color(0xFFF8F9FD);

  bool _whyExpanded = false;

  bool get _isVerified => widget.idNumber != null && widget.idNumber!.isNotEmpty;

  String _maskId(String id) {
    if (id.length <= 5) return id;
    final first = id.substring(0, 3);
    final last = id.substring(id.length - 2);
    final masked = '*' * (id.length - 5);
    return '$first$masked$last';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('ID Verification',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: joRideAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // ─── Shield Icon Section ──────────────────────────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _isVerified
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  Icons.verified_user,
                  size: 72,
                  color: _isVerified ? Colors.green : Colors.orange.shade400,
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              _isVerified ? 'Identity Verified' : 'Pending Verification',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF131A2D),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Status Badge ─────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _isVerified
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isVerified ? 'VERIFIED' : 'PENDING',
                style: TextStyle(
                  color: _isVerified
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ─── ID Number Card ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'National ID Number',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        color: joRideAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isVerified
                            ? _maskId(widget.idNumber!)
                            : 'Not submitted',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isVerified
                              ? const Color(0xFF131A2D)
                              : Colors.grey,
                          letterSpacing: _isVerified ? 2 : 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Why We Need This — Expandable ────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline,
                        color: joRideAccent),
                    title: const Text(
                      'Why we need this',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    trailing: AnimatedRotation(
                      turns: _whyExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.grey),
                    ),
                    onTap: () =>
                        setState(() => _whyExpanded = !_whyExpanded),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Divider(),
                          SizedBox(height: 10),
                          _BulletPoint(
                              text:
                                  'Identity verification helps us keep joRide safe for all users.'),
                          SizedBox(height: 8),
                          _BulletPoint(
                              text:
                                  'We are required by Jordanian law to verify the identity of all drivers.'),
                          SizedBox(height: 8),
                          _BulletPoint(
                              text:
                                  'Your data is encrypted and never shared with third parties.'),
                          SizedBox(height: 8),
                          _BulletPoint(
                              text:
                                  'Verification is a one-time process and keeps your account secure.'),
                        ],
                      ),
                    ),
                    crossFadeState: _whyExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ─── Upload Button (if not verified) ─────────────────────────
            if (!_isVerified)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: joRideAccent,
                    side: const BorderSide(color: joRideAccent, width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Document upload coming soon')),
                    );
                  },
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text(
                    'Upload ID Document',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ',
            style: TextStyle(
                color: Color(0xFF13366B),
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            text,
            style:
                const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }
}
