class Profile {
  final String id;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? driverLicenseNumber;
  final String? driverLicenseExpiry;
  final String? address;
  final String? dateOfBirth;
  final String? avatarUrl;
  final String? email;
  final bool isAdmin;
  final bool isSuspended;

  Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.driverLicenseNumber,
    this.driverLicenseExpiry,
    this.address,
    this.dateOfBirth,
    this.avatarUrl,
    this.email,
    this.isAdmin = false,
    this.isSuspended = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      driverLicenseNumber: json['driverLicenseNumber'] as String?,
      driverLicenseExpiry: json['driverLicenseExpiry'] as String?,
      address: json['address'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      email: json['email'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isSuspended: json['isSuspended'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'driverLicenseNumber': driverLicenseNumber,
      'driverLicenseExpiry': driverLicenseExpiry,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'avatarUrl': avatarUrl,
      'email': email,
      'isAdmin': isAdmin,
      'isSuspended': isSuspended,
    };
  }
}
