DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
        CREATE SCHEMA auth;
    END IF;
END $EF$;


CREATE TYPE auth.aal_level AS ENUM ('aal1', 'aal2', 'aal3');
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
        CREATE SCHEMA auth;
    END IF;
END $EF$;


CREATE TYPE auth.code_challenge_method AS ENUM ('s256', 'plain');
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
        CREATE SCHEMA auth;
    END IF;
END $EF$;


CREATE TYPE auth.factor_status AS ENUM ('unverified', 'verified');
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
        CREATE SCHEMA auth;
    END IF;
END $EF$;


CREATE TYPE auth.factor_type AS ENUM ('totp', 'webauthn', 'phone');
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
        CREATE SCHEMA auth;
    END IF;
END $EF$;


CREATE TYPE auth.oauth_authorization_status AS ENUM ('pending', 'approved', 'denied', 'expired');
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
        CREATE SCHEMA auth;
    END IF;
END $EF$;


CREATE TYPE auth.oauth_client_type AS ENUM ('public', 'confidential');
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
        CREATE SCHEMA auth;
    END IF;
END $EF$;


CREATE TYPE auth.oauth_registration_type AS ENUM ('dynamic', 'manual');
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
        CREATE SCHEMA auth;
    END IF;
END $EF$;


CREATE TYPE auth.oauth_response_type AS ENUM ('code');
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
        CREATE SCHEMA auth;
    END IF;
END $EF$;


CREATE TYPE auth.one_time_token_type AS ENUM ('confirmation_token', 'reauthentication_token', 'recovery_token', 'email_change_token_new', 'email_change_token_current', 'phone_change_token');
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'realtime') THEN
        CREATE SCHEMA realtime;
    END IF;
END $EF$;


CREATE TYPE realtime.action AS ENUM ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'ERROR');
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'realtime') THEN
        CREATE SCHEMA realtime;
    END IF;
END $EF$;


CREATE TYPE realtime.equality_op AS ENUM ('eq', 'neq', 'lt', 'lte', 'gt', 'gte', 'in');
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'storage') THEN
        CREATE SCHEMA storage;
    END IF;
END $EF$;


CREATE TYPE storage.buckettype AS ENUM ('STANDARD', 'ANALYTICS', 'VECTOR');
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'extensions') THEN
        CREATE SCHEMA extensions;
    END IF;
END $EF$;


CREATE EXTENSION IF NOT EXISTS pg_stat_statements SCHEMA extensions;
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'extensions') THEN
        CREATE SCHEMA extensions;
    END IF;
END $EF$;


CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA extensions;
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'extensions') THEN
        CREATE SCHEMA extensions;
    END IF;
END $EF$;


CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA extensions;
DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'vault') THEN
        CREATE SCHEMA vault;
    END IF;
END $EF$;


CREATE EXTENSION IF NOT EXISTS supabase_vault SCHEMA vault;


CREATE TABLE admin_notifications (
    id uuid NOT NULL,
    title text NOT NULL,
    message text NOT NULL,
    type text NOT NULL,
    is_read boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    booking_id uuid,
    CONSTRAINT "PK_admin_notifications" PRIMARY KEY (id)
);


CREATE TABLE locations (
    id uuid NOT NULL DEFAULT (gen_random_uuid()),
    name text NOT NULL,
    address text NOT NULL,
    contact_phone text,
    latitude numeric(9,6),
    longitude numeric(9,6),
    created_at timestamp with time zone DEFAULT (now()),
    CONSTRAINT locations_pkey PRIMARY KEY (id)
);


CREATE TABLE profiles (
    id uuid NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    phone_number text,
    driver_license_number text,
    driver_license_expiry date NOT NULL,
    address text,
    date_of_birth date NOT NULL,
    avatar_url text,
    created_at timestamp with time zone DEFAULT (now()),
    CONSTRAINT profiles_pkey PRIMARY KEY (id)
);


CREATE TABLE cars (
    id uuid NOT NULL DEFAULT (gen_random_uuid()),
    make text NOT NULL,
    model text NOT NULL,
    year integer NOT NULL,
    license_plate text NOT NULL,
    vin text,
    transmission text NOT NULL,
    fuel_type text NOT NULL,
    seats integer NOT NULL,
    daily_rate_zmw numeric(10,2) NOT NULL,
    daily_rate_usd numeric(10,2),
    features text[],
    image_urls text[],
    current_odometer integer NOT NULL,
    status text NOT NULL DEFAULT ('Available'::text),
    insurance_expiry_date date,
    road_tax_expiry_date date,
    location_id uuid,
    "IsShuttleOnly" boolean NOT NULL,
    created_at timestamp with time zone DEFAULT (now()),
    updated_at timestamp with time zone DEFAULT (now()),
    CONSTRAINT cars_pkey PRIMARY KEY (id),
    CONSTRAINT cars_location_id_fkey FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE SET NULL
);


CREATE TABLE notifications (
    id uuid NOT NULL DEFAULT (gen_random_uuid()),
    profile_id uuid NOT NULL,
    type text NOT NULL,
    message text NOT NULL,
    is_read boolean DEFAULT FALSE,
    sent_at timestamp with time zone DEFAULT (now()),
    CONSTRAINT notifications_pkey PRIMARY KEY (id),
    CONSTRAINT notifications_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
);


CREATE TABLE bookings (
    id uuid NOT NULL DEFAULT (gen_random_uuid()),
    car_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    pickup_location_id uuid NOT NULL,
    dropoff_location_id uuid NOT NULL,
    total_price_zmw numeric(10,2) NOT NULL,
    total_price_usd numeric(10,2),
    status text DEFAULT ('Pending'::text),
    initial_odometer integer,
    final_odometer integer,
    payment_status text DEFAULT ('Pending'::text),
    security_deposit_amount numeric(10,2),
    security_deposit_status text,
    rental_agreement_url text,
    created_at timestamp with time zone DEFAULT (now()),
    updated_at timestamp with time zone DEFAULT (now()),
    "LencoReference" text,
    "BookingType" text,
    "Notes" text,
    CONSTRAINT bookings_pkey PRIMARY KEY (id),
    CONSTRAINT bookings_car_id_fkey FOREIGN KEY (car_id) REFERENCES cars (id) ON DELETE RESTRICT,
    CONSTRAINT bookings_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES profiles (id) ON DELETE RESTRICT,
    CONSTRAINT bookings_dropoff_location_id_fkey FOREIGN KEY (dropoff_location_id) REFERENCES locations (id) ON DELETE RESTRICT,
    CONSTRAINT bookings_pickup_location_id_fkey FOREIGN KEY (pickup_location_id) REFERENCES locations (id) ON DELETE RESTRICT
);


CREATE TABLE damages (
    id uuid NOT NULL DEFAULT (gen_random_uuid()),
    car_id uuid NOT NULL,
    booking_id uuid,
    reported_by_profile_id uuid,
    description text NOT NULL,
    severity text,
    image_urls text[],
    repair_cost_estimate numeric(10,2),
    repair_status text DEFAULT ('Pending'::text),
    created_at timestamp with time zone DEFAULT (now()),
    CONSTRAINT damages_pkey PRIMARY KEY (id),
    CONSTRAINT damages_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE SET NULL,
    CONSTRAINT damages_car_id_fkey FOREIGN KEY (car_id) REFERENCES cars (id) ON DELETE RESTRICT,
    CONSTRAINT damages_reported_by_profile_id_fkey FOREIGN KEY (reported_by_profile_id) REFERENCES profiles (id) ON DELETE SET NULL
);


CREATE TABLE payments (
    id uuid NOT NULL DEFAULT (gen_random_uuid()),
    booking_id uuid NOT NULL,
    profile_id uuid NOT NULL,
    amount_zmw numeric(10,2) NOT NULL,
    amount_usd numeric(10,2),
    currency text NOT NULL,
    payment_method text NOT NULL,
    transaction_id text,
    status text NOT NULL,
    type text NOT NULL,
    created_at timestamp with time zone DEFAULT (now()),
    CONSTRAINT payments_pkey PRIMARY KEY (id),
    CONSTRAINT payments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE RESTRICT,
    CONSTRAINT payments_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE RESTRICT
);


CREATE INDEX "IX_bookings_car_id" ON bookings (car_id);


CREATE INDEX "IX_bookings_customer_id" ON bookings (customer_id);


CREATE INDEX "IX_bookings_dropoff_location_id" ON bookings (dropoff_location_id);


CREATE INDEX "IX_bookings_pickup_location_id" ON bookings (pickup_location_id);


CREATE UNIQUE INDEX cars_license_plate_key ON cars (license_plate);


CREATE UNIQUE INDEX cars_vin_key ON cars (vin);


CREATE INDEX "IX_cars_location_id" ON cars (location_id);


CREATE INDEX "IX_damages_booking_id" ON damages (booking_id);


CREATE INDEX "IX_damages_car_id" ON damages (car_id);


CREATE INDEX "IX_damages_reported_by_profile_id" ON damages (reported_by_profile_id);


CREATE UNIQUE INDEX locations_name_key ON locations (name);


CREATE INDEX "IX_notifications_profile_id" ON notifications (profile_id);


CREATE INDEX "IX_payments_booking_id" ON payments (booking_id);


CREATE INDEX "IX_payments_profile_id" ON payments (profile_id);


CREATE UNIQUE INDEX payments_transaction_id_key ON payments (transaction_id);


CREATE UNIQUE INDEX profiles_driver_license_number_key ON profiles (driver_license_number);


CREATE UNIQUE INDEX profiles_phone_number_key ON profiles (phone_number);


