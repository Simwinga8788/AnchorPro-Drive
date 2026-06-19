import 'booking.dart';
import 'profile.dart';

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
  final Profile? profile;
  final Booking? booking;

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
    this.profile,
    this.booking,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      amountZmw: (json['amountZmw'] as num?)?.toDouble() ?? 0.0,
      amountUsd: (json['amountUsd'] as num?)?.toDouble(),
      method: (json['paymentMethod'] ?? json['method']) as String? ?? '',
      status: json['status'] as String? ?? '',
      type: json['type'] as String? ?? 'Rental',
      reference: (json['transactionId'] ?? json['reference']) as String?,
      createdAt: json['createdAt'] as String?,
      profile: json['profile'] != null ? Profile.fromJson(json['profile'] as Map<String, dynamic>) : null,
      booking: json['booking'] != null ? Booking.fromJson(json['booking'] as Map<String, dynamic>) : null,
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
      'profile': profile?.toJson(),
      'booking': booking?.toJson(),
    };
  }
}
