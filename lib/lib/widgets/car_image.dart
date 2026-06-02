import 'package:flutter/material.dart';

/// Smart car image widget — tries local asset first, then network URL,
/// then a clean car icon as final fallback.
///
/// Why this exists: the previous Image.network with a generic icon errorBuilder
/// looked ridiculous when the URL failed. This widget picks the best available
/// image source automatically without breaking the layout.
class CarImage extends StatelessWidget {
  final Map<String, dynamic> car;
  final double height;
  final double? width;
  final BoxFit fit;
  final Color? iconColor;

  const CarImage({
    super.key,
    required this.car,
    this.height = 80,
    this.width,
    this.fit = BoxFit.contain,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = (car['localAsset'] as String?) ?? '';
    final networkUrl = (car['img'] as String?) ?? '';
    final brand = Theme.of(context).colorScheme.primary;

    Widget iconFallback() => Icon(
          Icons.directions_car_filled_rounded,
          size: height * 0.6,
          color: iconColor ?? brand,
        );

    // 1. Try local asset (won't trigger network)
    if (assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        height: height,
        width: width,
        fit: fit,
        // If asset is the 70-byte placeholder, treat it as missing
        errorBuilder: (_, __, ___) => _NetworkOrIcon(
          url: networkUrl,
          height: height,
          width: width,
          fit: fit,
          fallback: iconFallback,
        ),
      );
    }

    // 2. Fall back to network
    return _NetworkOrIcon(
      url: networkUrl,
      height: height,
      width: width,
      fit: fit,
      fallback: iconFallback,
    );
  }
}

class _NetworkOrIcon extends StatelessWidget {
  final String url;
  final double height;
  final double? width;
  final BoxFit fit;
  final Widget Function() fallback;

  const _NetworkOrIcon({
    required this.url,
    required this.height,
    required this.width,
    required this.fit,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return fallback();
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback(),
      loadingBuilder: (ctx, child, p) =>
          p == null ? child : SizedBox(height: height, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }
}
