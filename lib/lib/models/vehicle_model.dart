import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Maps a vehicle ID to a local PNG asset path (for the 5 seeded cars).
/// Returns empty string if no specific asset is configured.
String localCarAssetForId(String id) {
  switch (id) {
    case '1': return 'assets/cars/car_1_toyota_corolla.png';
    case '2': return 'assets/cars/car_2_bmw_320i.png';
    case '3': return 'assets/cars/car_3_landcruiser.png';
    case '4': return 'assets/cars/car_4_tesla_model3.png';
    case '5': return 'assets/cars/car_5_hyundai_elantra.png';
    default:  return '';
  }
}

/// Maps a car model/brand keyword to a Clearbit brand logo URL.
/// Falls back gracefully if the image fails to load.
String brandLogoFromModel(String model) {
  final m = model.toLowerCase();
  if (m.contains('toyota'))  return 'https://logo.clearbit.com/toyota.com';
  if (m.contains('bmw'))     return 'https://logo.clearbit.com/bmw.com';
  if (m.contains('tesla'))   return 'https://logo.clearbit.com/tesla.com';
  if (m.contains('hyundai')) return 'https://logo.clearbit.com/hyundai.com';
  if (m.contains('honda'))   return 'https://logo.clearbit.com/honda.com';
  if (m.contains('nissan'))  return 'https://logo.clearbit.com/nissan.com';
  if (m.contains('kia'))     return 'https://logo.clearbit.com/kia.com';
  if (m.contains('ford'))    return 'https://logo.clearbit.com/ford.com';
  if (m.contains('chevrolet') || m.contains('chevy'))
                              return 'https://logo.clearbit.com/chevrolet.com';
  if (m.contains('mercedes') || m.contains('benz'))
                              return 'https://logo.clearbit.com/mercedes-benz.com';
  if (m.contains('audi'))    return 'https://logo.clearbit.com/audi.com';
  if (m.contains('lexus'))   return 'https://logo.clearbit.com/lexus.com';
  return '';
}

class Vehicle {
  final String id;
  final String licensePlate;
  final String model;
  final String status;
  final double latitude;
  final double longitude;
  final String category;
  final String color;
  final int fuelLevel;
  final String imageUrl;
  final String brandLogoUrl; // manufacturer logo (Clearbit)
  final bool isVisible;      // admin can hide/show on map

  const Vehicle({
    required this.id,
    required this.licensePlate,
    required this.model,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.color,
    required this.fuelLevel,
    required this.imageUrl,
    this.brandLogoUrl = '',
    this.isVisible = true,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final model = (json['model'] as String?) ?? '';
    final rawBrand = (json['brandLogoUrl'] as String?) ?? '';
    return Vehicle(
      id: json['id'].toString(),
      licensePlate: (json['licensePlate'] as String?) ?? '',
      model: model,
      status: (json['status'] as String?) ?? 'Available',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      category: (json['category'] as String?) ?? 'Standard',
      color: (json['color'] as String?) ?? 'Unknown',
      fuelLevel: (json['fuelLevel'] as num?)?.toInt() ?? 100,
      imageUrl: (json['imageUrl'] as String?)?.isNotEmpty == true
          ? json['imageUrl'] as String
          : 'https://img.icons8.com/color/144/car--v1.png',
      // Use backend value if provided, otherwise infer from model name
      brandLogoUrl: rawBrand.isNotEmpty ? rawBrand : brandLogoFromModel(model),
      isVisible: (json['isVisible'] as bool?) ?? true,
    );
  }

  LatLng get position => LatLng(latitude, longitude);

  Map<String, double> get rates {
    switch (category.toLowerCase()) {
      case 'luxury':
        return const {'min': 0.30, 'hour': 16.0, 'day': 90.0};
      case 'suv':
        return const {'min': 0.25, 'hour': 12.0, 'day': 70.0};
      case 'electric':
        return const {'min': 0.20, 'hour': 10.0, 'day': 60.0};
      case 'economy':
      default:
        return const {'min': 0.15, 'hour': 8.0, 'day': 45.0};
    }
  }

  /// Local asset path for this vehicle (used preferentially over network image).
  String get localAsset => localCarAssetForId(id);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model': model,
      'plate': licensePlate,
      'status': status,
      'pos': position,
      'fuel': fuelLevel,
      'rates': rates,
      'category': category,
      'img': imageUrl,
      'localAsset': localAsset,       // local PNG path (may be empty)
      'brandLogo': brandLogoUrl,      // brand manufacturer logo (Clearbit URL)
      'color': color,
      'isVisible': isVisible,
    };
  }
}
