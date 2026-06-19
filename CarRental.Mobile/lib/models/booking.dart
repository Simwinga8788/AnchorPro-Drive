import 'car.dart';
import 'location.dart';
import 'profile.dart';
import 'payment.dart';

class Booking {
  final String id;
  final String carId;
  final String customerId;
  final String startDate;
  final String endDate;
  final String pickupLocationId;
  final String dropoffLocationId;
  final double totalPriceZmw;
  final double? totalPriceUsd;
  final String status;
  final String paymentStatus;
  final String? bookingType;
  final String? notes;
  final bool? isOutofTown;
  final int? initialOdometer;
  final int? finalOdometer;
  final double? securityDepositAmount;
  final String? securityDepositStatus;
  final String? rentalAgreementUrl;
  final String? createdAt;
  final Car? car;
  final Location? pickupLocation;
  final Location? dropoffLocation;
  final Profile? customer;
  final List<Payment>? payments;

  Booking({
    required this.id,
    required this.carId,
    required this.customerId,
    required this.startDate,
    required this.endDate,
    required this.pickupLocationId,
    required this.dropoffLocationId,
    required this.totalPriceZmw,
    this.totalPriceUsd,
    required this.status,
    required this.paymentStatus,
    this.bookingType,
    this.notes,
    this.isOutofTown,
    this.initialOdometer,
    this.finalOdometer,
    this.securityDepositAmount,
    this.securityDepositStatus,
    this.rentalAgreementUrl,
    this.createdAt,
    this.car,
    this.pickupLocation,
    this.dropoffLocation,
    this.customer,
    this.payments,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String? ?? '',
      carId: json['carId'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      pickupLocationId: json['pickupLocationId'] as String? ?? '',
      dropoffLocationId: json['dropoffLocationId'] as String? ?? '',
      totalPriceZmw: (json['totalPriceZmw'] as num?)?.toDouble() ?? 0.0,
      totalPriceUsd: (json['totalPriceUsd'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'Pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'Pending',
      bookingType: json['bookingType'] as String?,
      notes: json['notes'] as String?,
      isOutofTown: json['isOutofTown'] as bool?,
      initialOdometer: json['initialOdometer'] as int?,
      finalOdometer: json['finalOdometer'] as int?,
      securityDepositAmount: (json['securityDepositAmount'] as num?)?.toDouble(),
      securityDepositStatus: json['securityDepositStatus'] as String?,
      rentalAgreementUrl: json['rentalAgreementUrl'] as String?,
      createdAt: json['createdAt'] as String?,
      car: json['car'] != null ? Car.fromJson(json['car'] as Map<String, dynamic>) : null,
      pickupLocation: json['pickupLocation'] != null ? Location.fromJson(json['pickupLocation'] as Map<String, dynamic>) : null,
      dropoffLocation: json['dropoffLocation'] != null ? Location.fromJson(json['dropoffLocation'] as Map<String, dynamic>) : null,
      customer: json['customer'] != null ? Profile.fromJson(json['customer'] as Map<String, dynamic>) : null,
      payments: json['payments'] != null ? (json['payments'] as List).map((p) => Payment.fromJson(p as Map<String, dynamic>)).toList() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'carId': carId,
      'customerId': customerId,
      'startDate': startDate,
      'endDate': endDate,
      'pickupLocationId': pickupLocationId,
      'dropoffLocationId': dropoffLocationId,
      'totalPriceZmw': totalPriceZmw,
      'totalPriceUsd': totalPriceUsd,
      'status': status,
      'paymentStatus': paymentStatus,
      'bookingType': bookingType,
      'notes': notes,
      'isOutofTown': isOutofTown,
      'initialOdometer': initialOdometer,
      'finalOdometer': finalOdometer,
      'securityDepositAmount': securityDepositAmount,
      'securityDepositStatus': securityDepositStatus,
      'rentalAgreementUrl': rentalAgreementUrl,
      'createdAt': createdAt,
      'car': car?.toJson(),
      'pickupLocation': pickupLocation?.toJson(),
      'dropoffLocation': dropoffLocation?.toJson(),
      'customer': customer?.toJson(),
      'payments': payments?.map((p) => p.toJson()).toList(),
    };
  }
}
