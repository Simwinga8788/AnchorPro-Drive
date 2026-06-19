class Damage {
  final String id;
  final String carId;
  final String? bookingId;
  final String? reportedByProfileId;
  final String description;
  final String? severity;
  final List<String>? imageUrls;
  final double? repairCostEstimate;
  final String? repairStatus;
  final String? createdAt;

  Damage({
    required this.id,
    required this.carId,
    this.bookingId,
    this.reportedByProfileId,
    required this.description,
    this.severity,
    this.imageUrls,
    this.repairCostEstimate,
    this.repairStatus,
    this.createdAt,
  });

  factory Damage.fromJson(Map<String, dynamic> json) {
    return Damage(
      id: json['id'] as String? ?? '',
      carId: json['carId'] as String? ?? '',
      bookingId: json['bookingId'] as String?,
      reportedByProfileId: json['reportedByProfileId'] as String?,
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      repairCostEstimate: (json['repairCostEstimate'] as num?)?.toDouble(),
      repairStatus: json['repairStatus'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'carId': carId,
      'bookingId': bookingId,
      'reportedByProfileId': reportedByProfileId,
      'description': description,
      'severity': severity,
      'imageUrls': imageUrls,
      'repairCostEstimate': repairCostEstimate,
      'repairStatus': repairStatus,
      'createdAt': createdAt,
    };
  }
}
