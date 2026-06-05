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
  dailyRateOutofTownZmw?: number;
  dailyRateOutofTownUsd?: number;
  features?: string[];
  imageUrls?: string[];
  currentOdometer: number;
  isShuttleOnly?: boolean;
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
  status: 'Pending' | 'Draft' | 'Confirmed' | 'Active' | 'Completed' | 'Cancelled';
  paymentStatus: 'Pending' | 'Paid' | 'Refunded';
  bookingType?: string;
  notes?: string;
  isOutofTown?: boolean;
  initialOdometer?: number;
  finalOdometer?: number;
  securityDepositAmount?: number;
  securityDepositStatus?: string;
  rentalAgreementUrl?: string;
  createdAt?: string;
  car?: Car;
  pickupLocation?: Location;
  dropoffLocation?: Location;
  customer?: Profile;
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
  reportedByProfileId?: string;
  description: string;
  severity: 'Minor' | 'Moderate' | 'Severe';
  repairStatus: 'Pending' | 'InProgress' | 'Repaired';
  repairCostEstimate?: number;
  imageUrls?: string[];
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
  isAdmin?: boolean;
}

export type Currency = 'ZMW' | 'USD';
