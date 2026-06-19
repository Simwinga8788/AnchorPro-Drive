class Payment {
  final String id;
  final String bookingId;
  final double amountZmw;
  final double? amountUsd;
  final String method;
  final String status;
  final String type;
  final String? reference;
  final String? createdAt;

  Payment({
    required this.id,
    required this.bookingId,
    required this.amountZmw,
    this.amountUsd,
    required this.method,
    required this.status,
    required this.type,
    this.reference,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      amountZmw: (json['amountZmw'] as num?)?.toDouble() ?? 0.0,
      amountUsd: (json['amountUsd'] as num?)?.toDouble(),
      method: json['method'] as String? ?? '',
      status: json['status'] as String? ?? '',
      type: json['type'] as String? ?? 'Rental',
      reference: json['reference'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'amountZmw': amountZmw,
      'amountUsd': amountUsd,
      'method': method,
      'status': status,
      'type': type,
      'reference': reference,
      'createdAt': createdAt,
    };
  }
}
