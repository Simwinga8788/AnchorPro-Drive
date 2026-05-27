export interface Car {
  id: string;
  make: string;
  model: string;
  year: number;
  licensePlate: string;
  vin: string;
  transmission: string;
  fuelType: string;
  seats: number;
  dailyRateZmw: number;
  dailyRateUsd?: number;
  features?: string[];
  imageUrls?: string[];
  currentOdometer: number;
  status: 'Available' | 'Rented' | 'Maintenance' | 'Unavailable';
  insuranceExpiryDate?: string;
  roadTaxExpiryDate?: string;
  locationId?: string;
  location?: Location;
  createdAt?: string;
}

export interface Location {
  id: string;
  name: string;
  address: string;
  contactPhone?: string;
  latitude?: number;
  longitude?: number;
}

export interface Booking {
  id: string;
  carId: string;
  customerId: string;
  startDate: string;
  endDate: string;
  pickupLocationId: string;
  dropoffLocationId: string;
  totalPriceZmw: number;
  totalPriceUsd?: number;
  status: 'Confirmed' | 'Active' | 'Completed' | 'Cancelled';
  paymentStatus: 'Pending' | 'Paid' | 'Refunded';
  initialOdometer?: number;
  finalOdometer?: number;
  securityDepositAmount?: number;
  securityDepositStatus?: string;
  rentalAgreementUrl?: string;
  createdAt?: string;
  car?: Car;
  pickupLocation?: Location;
  dropoffLocation?: Location;
}

export interface Payment {
  id: string;
  bookingId: string;
  profileId: string;
  amountZmw: number;
  amountUsd?: number;
  currency: string;
  paymentMethod: string;
  transactionId?: string;
  status: 'Pending' | 'Completed' | 'Failed' | 'Refunded';
  type: string;
  createdAt?: string;
  booking?: Booking;
}

export interface Damage {
  id: string;
  bookingId?: string;
  carId: string;
  reportedBy?: string;
  description: string;
  severity: 'Minor' | 'Moderate' | 'Severe';
  repairStatus: 'Pending' | 'InProgress' | 'Repaired';
  estimatedCostZmw?: number;
  actualCostZmw?: number;
  photoUrls?: string[];
  createdAt?: string;
  car?: Car;
}

export interface Notification {
  id: string;
  profileId: string;
  type: string;
  message: string;
  isRead: boolean;
  createdAt?: string;
}

export interface ZraInvoice {
  id: string;
  bookingId: string;
  invoiceNumber: string;
  submissionStatus: 'Pending' | 'Submitted' | 'Accepted' | 'Rejected';
  taxAmountZmw?: number;
  totalAmountZmw?: number;
  submittedAt?: string;
  createdAt?: string;
  booking?: Booking;
}

export interface Profile {
  id: string;
  firstName: string;
  lastName: string;
  phoneNumber?: string;
  driverLicenseNumber?: string;
  driverLicenseExpiry?: string;
  address?: string;
  dateOfBirth?: string;
  avatarUrl?: string;
}

export type Currency = 'ZMW' | 'USD';
