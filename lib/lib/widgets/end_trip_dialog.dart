import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

const Color _kBrand = Color(0xFF13366B);

/// Shows a polished "are you sure you want to end this trip?" dialog.
/// Returns `true` if the user confirms, `false` / `null` otherwise.
///
/// Used by DigitalKeyScreen and MyReservationsScreen — keeps the look
/// consistent across every End Trip entry point.
Future<bool> showEndTripConfirmation(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _EndTripDialog(l: l),
  );
  return result == true;
}

class _EndTripDialog extends StatelessWidget {
  final AppLocalizations l;
  const _EndTripDialog({required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Gradient header with flag icon ─────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _kBrand,
                    Color(0xFFE74C3C),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(45),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(120),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.t('end_trip'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body message ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
              child: Text(
                l.t('end_trip_confirm'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurface.withAlpha(210),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),

            // Helpful note
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC857).withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFFB8860B), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The car will be locked and your final fare calculated.',
                        style: TextStyle(
                          color: cs.onSurface.withAlpha(180),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── Action buttons ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(
                            color: cs.onSurface.withAlpha(60)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        l.t('cancel'),
                        style: TextStyle(
                          color: cs.onSurface.withAlpha(200),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        l.t('yes_end_it'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
