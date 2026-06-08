-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Locations Table (Must be created before Cars and Bookings)
CREATE TABLE public.locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    address TEXT NOT NULL,
    contact_phone TEXT,
    latitude DECIMAL(9, 6),
    longitude DECIMAL(9, 6),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Profiles Table (Extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone_number TEXT UNIQUE,
    driver_license_number TEXT UNIQUE,
    driver_license_expiry DATE,
    address TEXT,
    date_of_birth DATE NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 3. Cars Table (Fleet Inventory)
CREATE TABLE public.cars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    make TEXT NOT NULL,
    model TEXT NOT NULL,
    year INT NOT NULL,
    license_plate TEXT NOT NULL UNIQUE,
    vin TEXT NOT NULL UNIQUE,
    transmission TEXT NOT NULL CHECK (transmission IN ('Automatic', 'Manual')),
    fuel_type TEXT NOT NULL CHECK (fuel_type IN ('Petrol', 'Diesel', 'Electric')),
    seats INT NOT NULL,
    daily_rate_zmw DECIMAL(10, 2) NOT NULL,
    daily_rate_usd DECIMAL(10, 2),
    features TEXT[],
    image_urls TEXT[],
    current_odometer INT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('Available', 'Rented', 'In Maintenance', 'Damaged', 'Unavailable')) DEFAULT 'Available',
    insurance_expiry_date DATE,
    road_tax_expiry_date DATE,
    location_id UUID REFERENCES public.locations(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 4. Bookings Table (Rental Reservations)
CREATE TABLE public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    car_id UUID NOT NULL REFERENCES public.cars(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    pickup_location_id UUID NOT NULL REFERENCES public.locations(id) ON DELETE RESTRICT,
    dropoff_location_id UUID NOT NULL REFERENCES public.locations(id) ON DELETE RESTRICT,
    total_price_zmw DECIMAL(10, 2) NOT NULL,
    total_price_usd DECIMAL(10, 2),
    status TEXT NOT NULL CHECK (status IN ('Pending', 'Confirmed', 'Active', 'Completed', 'Cancelled', 'Picked Up', 'Returned')) DEFAULT 'Pending',
    initial_odometer INT,
    final_odometer INT,
    payment_status TEXT NOT NULL CHECK (payment_status IN ('Pending', 'Paid', 'Refunded', 'Partially Paid')) DEFAULT 'Pending',
    security_deposit_amount DECIMAL(10, 2),
    security_deposit_status TEXT CHECK (security_deposit_status IN ('Pending', 'Paid', 'Refunded', 'Withheld')),
    rental_agreement_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 5. Payments Table (Transaction History)
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE RESTRICT,
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    amount_zmw DECIMAL(10, 2) NOT NULL,
    amount_usd DECIMAL(10, 2),
    currency TEXT NOT NULL CHECK (currency IN ('ZMW', 'USD')),
    payment_method TEXT NOT NULL CHECK (payment_method IN ('Credit Card', 'Mobile Money', 'Bank Transfer')),
    transaction_id TEXT UNIQUE,
    status TEXT NOT NULL CHECK (status IN ('Pending', 'Completed', 'Failed', 'Refunded')),
    type TEXT NOT NULL CHECK (type IN ('Rental', 'Deposit', 'Penalty', 'Refund')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 6. Damages Table (Vehicle Damage Tracking)
CREATE TABLE public.damages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    car_id UUID NOT NULL REFERENCES public.cars(id) ON DELETE RESTRICT,
    booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
    reported_by_profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    severity TEXT CHECK (severity IN ('Minor', 'Moderate', 'Major')),
    image_urls TEXT[],
    repair_cost_estimate DECIMAL(10, 2),
    repair_status TEXT CHECK (repair_status IN ('Pending', 'In Progress', 'Completed')) DEFAULT 'Pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 7. Notifications Table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('Booking Confirmation', 'Payment Due', 'Vehicle Ready', 'Reminder', 'Alert')),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 8. ZRA Invoices Table (ZRA Smart Invoice Compliance)
CREATE TABLE public.zra_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE RESTRICT,
    invoice_number TEXT NOT NULL UNIQUE,
    zra_reference_number TEXT UNIQUE,
    submission_status TEXT NOT NULL CHECK (submission_status IN ('Pending', 'Submitted', 'Failed', 'Validated')),
    submission_payload JSONB,
    zra_response JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 9. Setup Auto-Update Triggers for updated_at columns
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_cars_modtime BEFORE UPDATE ON public.cars FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER update_bookings_modtime BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER update_zra_invoices_modtime BEFORE UPDATE ON public.zra_invoices FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
