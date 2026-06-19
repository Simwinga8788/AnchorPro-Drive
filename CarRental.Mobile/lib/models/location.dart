class Location {
  final String id;
  final String name;
  final String address;
  final String? contactPhone;
  final double? latitude;
  final double? longitude;

  Location({
    required this.id,
    required this.name,
    required this.address,
    this.contactPhone,
    this.latitude,
    this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      contactPhone: json['contactPhone'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contactPhone': contactPhone,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
