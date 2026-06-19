import 'location.dart';

class Car {
  final String id;
  final String make;
  final String model;
  final int? year;
  final String? licensePlate;
  final String? vin;
  final String transmission;
  final String fuelType;
  final int seats;
  final double dailyRateZmw;
  final double? dailyRateUsd;
  final double? dailyRateOutofTownZmw;
  final double? dailyRateOutofTownUsd;
  final List<String>? features;
  final List<String>? imageUrls;
  final int currentOdometer;
  final String status;
  final String? insuranceExpiryDate;
  final String? roadTaxExpiryDate;
  final String? locationId;
  final bool isShuttleOnly;
  final Location? location;

  Car({
    required this.id,
    required this.make,
    required this.model,
    this.year,
    this.licensePlate,
    this.vin,
    required this.transmission,
    required this.fuelType,
    required this.seats,
    required this.dailyRateZmw,
    this.dailyRateUsd,
    this.dailyRateOutofTownZmw,
    this.dailyRateOutofTownUsd,
    this.features,
    this.imageUrls,
    required this.currentOdometer,
    required this.status,
    this.insuranceExpiryDate,
    this.roadTaxExpiryDate,
    this.locationId,
    this.isShuttleOnly = false,
    this.location,
  });

  bool get available => status.toLowerCase() == 'available';

  String get primaryImage {
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      return imageUrls!.first;
    }
    return 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=600'; // Fallback
  }

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as String? ?? '',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int?,
      licensePlate: json['licensePlate'] as String?,
      vin: json['vin'] as String?,
      transmission: json['transmission'] as String? ?? 'Automatic',
      fuelType: json['fuelType'] as String? ?? 'Petrol',
      seats: json['seats'] as int? ?? 5,
      dailyRateZmw: (json['dailyRateZmw'] as num?)?.toDouble() ?? 0.0,
      dailyRateUsd: (json['dailyRateUsd'] as num?)?.toDouble(),
      dailyRateOutofTownZmw: (json['dailyRateOutofTownZmw'] as num?)?.toDouble(),
      dailyRateOutofTownUsd: (json['dailyRateOutofTownUsd'] as num?)?.toDouble(),
      features: (json['features'] as List<dynamic>?)?.map((e) => e as String).toList(),
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      currentOdometer: json['currentOdometer'] as int? ?? 0,
      status: json['status'] as String? ?? 'Available',
      insuranceExpiryDate: json['insuranceExpiryDate'] as String?,
      roadTaxExpiryDate: json['roadTaxExpiryDate'] as String?,
      locationId: json['locationId'] as String?,
      isShuttleOnly: json['isShuttleOnly'] as bool? ?? false,
      location: json['location'] != null ? Location.fromJson(json['location'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'vin': vin,
      'transmission': transmission,
      'fuelType': fuelType,
      'seats': seats,
      'dailyRateZmw': dailyRateZmw,
      'dailyRateUsd': dailyRateUsd,
      'dailyRateOutofTownZmw': dailyRateOutofTownZmw,
      'dailyRateOutofTownUsd': dailyRateOutofTownUsd,
      'features': features,
      'imageUrls': imageUrls,
      'currentOdometer': currentOdometer,
      'status': status,
      'insuranceExpiryDate': insuranceExpiryDate,
      'roadTaxExpiryDate': roadTaxExpiryDate,
      'locationId': locationId,
      'isShuttleOnly': isShuttleOnly,
      'location': location?.toJson(),
    };
  }
}
