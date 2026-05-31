using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace CarRental.Api.Models;

public partial class AppDbContext : DbContext
{
    public AppDbContext()
    {
    }

    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Booking> Bookings { get; set; }

    public virtual DbSet<Car> Cars { get; set; }

    public virtual DbSet<Damage> Damages { get; set; }

    public virtual DbSet<Location> Locations { get; set; }

    public virtual DbSet<Notification> Notifications { get; set; }

    public virtual DbSet<Payment> Payments { get; set; }

    public virtual DbSet<Profile> Profiles { get; set; }



    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder
            .HasPostgresEnum("auth", "aal_level", new[] { "aal1", "aal2", "aal3" })
            .HasPostgresEnum("auth", "code_challenge_method", new[] { "s256", "plain" })
            .HasPostgresEnum("auth", "factor_status", new[] { "unverified", "verified" })
            .HasPostgresEnum("auth", "factor_type", new[] { "totp", "webauthn", "phone" })
            .HasPostgresEnum("auth", "oauth_authorization_status", new[] { "pending", "approved", "denied", "expired" })
            .HasPostgresEnum("auth", "oauth_client_type", new[] { "public", "confidential" })
            .HasPostgresEnum("auth", "oauth_registration_type", new[] { "dynamic", "manual" })
            .HasPostgresEnum("auth", "oauth_response_type", new[] { "code" })
            .HasPostgresEnum("auth", "one_time_token_type", new[] { "confirmation_token", "reauthentication_token", "recovery_token", "email_change_token_new", "email_change_token_current", "phone_change_token" })
            .HasPostgresEnum("realtime", "action", new[] { "INSERT", "UPDATE", "DELETE", "TRUNCATE", "ERROR" })
            .HasPostgresEnum("realtime", "equality_op", new[] { "eq", "neq", "lt", "lte", "gt", "gte", "in" })
            .HasPostgresEnum("storage", "buckettype", new[] { "STANDARD", "ANALYTICS", "VECTOR" })
            .HasPostgresExtension("extensions", "pg_stat_statements")
            .HasPostgresExtension("extensions", "pgcrypto")
            .HasPostgresExtension("extensions", "uuid-ossp")
            .HasPostgresExtension("vault", "supabase_vault");

        modelBuilder.Entity<Booking>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("bookings_pkey");

            entity.ToTable("bookings");

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.CarId).HasColumnName("car_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.CustomerId).HasColumnName("customer_id");
            entity.Property(e => e.DropoffLocationId).HasColumnName("dropoff_location_id");
            entity.Property(e => e.EndDate).HasColumnName("end_date");
            entity.Property(e => e.FinalOdometer).HasColumnName("final_odometer");
            entity.Property(e => e.InitialOdometer).HasColumnName("initial_odometer");
            entity.Property(e => e.PaymentStatus)
                .HasDefaultValueSql("'Pending'::text")
                .HasColumnName("payment_status");
            entity.Property(e => e.PickupLocationId).HasColumnName("pickup_location_id");
            entity.Property(e => e.RentalAgreementUrl).HasColumnName("rental_agreement_url");
            entity.Property(e => e.SecurityDepositAmount)
                .HasPrecision(10, 2)
                .HasColumnName("security_deposit_amount");
            entity.Property(e => e.SecurityDepositStatus).HasColumnName("security_deposit_status");
            entity.Property(e => e.StartDate).HasColumnName("start_date");
            entity.Property(e => e.Status)
                .HasDefaultValueSql("'Pending'::text")
                .HasColumnName("status");
            entity.Property(e => e.TotalPriceUsd)
                .HasPrecision(10, 2)
                .HasColumnName("total_price_usd");
            entity.Property(e => e.TotalPriceZmw)
                .HasPrecision(10, 2)
                .HasColumnName("total_price_zmw");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Car).WithMany(p => p.Bookings)
                .HasForeignKey(d => d.CarId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("bookings_car_id_fkey");

            entity.HasOne(d => d.Customer).WithMany(p => p.Bookings)
                .HasForeignKey(d => d.CustomerId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("bookings_customer_id_fkey");

            entity.HasOne(d => d.DropoffLocation).WithMany(p => p.BookingDropoffLocations)
                .HasForeignKey(d => d.DropoffLocationId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("bookings_dropoff_location_id_fkey");

            entity.HasOne(d => d.PickupLocation).WithMany(p => p.BookingPickupLocations)
                .HasForeignKey(d => d.PickupLocationId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("bookings_pickup_location_id_fkey");
        });

        modelBuilder.Entity<Car>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("cars_pkey");

            entity.ToTable("cars");

            entity.HasIndex(e => e.LicensePlate, "cars_license_plate_key").IsUnique();

            entity.HasIndex(e => e.Vin, "cars_vin_key").IsUnique();

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.CurrentOdometer).HasColumnName("current_odometer");
            entity.Property(e => e.DailyRateUsd)
                .HasPrecision(10, 2)
                .HasColumnName("daily_rate_usd");
            entity.Property(e => e.DailyRateZmw)
                .HasPrecision(10, 2)
                .HasColumnName("daily_rate_zmw");
            entity.Property(e => e.Features).HasColumnName("features");
            entity.Property(e => e.FuelType).HasColumnName("fuel_type");
            entity.Property(e => e.ImageUrls).HasColumnName("image_urls");
            entity.Property(e => e.InsuranceExpiryDate).HasColumnName("insurance_expiry_date");
            entity.Property(e => e.LicensePlate).HasColumnName("license_plate");
            entity.Property(e => e.LocationId).HasColumnName("location_id");
            entity.Property(e => e.Make).HasColumnName("make");
            entity.Property(e => e.Model).HasColumnName("model");
            entity.Property(e => e.RoadTaxExpiryDate).HasColumnName("road_tax_expiry_date");
            entity.Property(e => e.Seats).HasColumnName("seats");
            entity.Property(e => e.Status)
                .HasDefaultValueSql("'Available'::text")
                .HasColumnName("status");
            entity.Property(e => e.Transmission).HasColumnName("transmission");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("updated_at");
            entity.Property(e => e.Vin).HasColumnName("vin");
            entity.Property(e => e.Year).HasColumnName("year");

            entity.HasOne(d => d.Location).WithMany(p => p.Cars)
                .HasForeignKey(d => d.LocationId)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("cars_location_id_fkey");
        });

        modelBuilder.Entity<Damage>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("damages_pkey");

            entity.ToTable("damages");

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.BookingId).HasColumnName("booking_id");
            entity.Property(e => e.CarId).HasColumnName("car_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.ImageUrls).HasColumnName("image_urls");
            entity.Property(e => e.RepairCostEstimate)
                .HasPrecision(10, 2)
                .HasColumnName("repair_cost_estimate");
            entity.Property(e => e.RepairStatus)
                .HasDefaultValueSql("'Pending'::text")
                .HasColumnName("repair_status");
            entity.Property(e => e.ReportedByProfileId).HasColumnName("reported_by_profile_id");
            entity.Property(e => e.Severity).HasColumnName("severity");

            entity.HasOne(d => d.Booking).WithMany(p => p.Damages)
                .HasForeignKey(d => d.BookingId)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("damages_booking_id_fkey");

            entity.HasOne(d => d.Car).WithMany(p => p.Damages)
                .HasForeignKey(d => d.CarId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("damages_car_id_fkey");

            entity.HasOne(d => d.ReportedByProfile).WithMany(p => p.Damages)
                .HasForeignKey(d => d.ReportedByProfileId)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("damages_reported_by_profile_id_fkey");
        });

        modelBuilder.Entity<Location>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("locations_pkey");

            entity.ToTable("locations");

            entity.HasIndex(e => e.Name, "locations_name_key").IsUnique();

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.Address).HasColumnName("address");
            entity.Property(e => e.ContactPhone).HasColumnName("contact_phone");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.Latitude)
                .HasPrecision(9, 6)
                .HasColumnName("latitude");
            entity.Property(e => e.Longitude)
                .HasPrecision(9, 6)
                .HasColumnName("longitude");
            entity.Property(e => e.Name).HasColumnName("name");
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("notifications_pkey");

            entity.ToTable("notifications");

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.IsRead)
                .HasDefaultValue(false)
                .HasColumnName("is_read");
            entity.Property(e => e.Message).HasColumnName("message");
            entity.Property(e => e.ProfileId).HasColumnName("profile_id");
            entity.Property(e => e.SentAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("sent_at");
            entity.Property(e => e.Type).HasColumnName("type");

            entity.HasOne(d => d.Profile).WithMany(p => p.Notifications)
                .HasForeignKey(d => d.ProfileId)
                .HasConstraintName("notifications_profile_id_fkey");
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("payments_pkey");

            entity.ToTable("payments");

            entity.HasIndex(e => e.TransactionId, "payments_transaction_id_key").IsUnique();

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.AmountUsd)
                .HasPrecision(10, 2)
                .HasColumnName("amount_usd");
            entity.Property(e => e.AmountZmw)
                .HasPrecision(10, 2)
                .HasColumnName("amount_zmw");
            entity.Property(e => e.BookingId).HasColumnName("booking_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.Currency).HasColumnName("currency");
            entity.Property(e => e.PaymentMethod).HasColumnName("payment_method");
            entity.Property(e => e.ProfileId).HasColumnName("profile_id");
            entity.Property(e => e.Status).HasColumnName("status");
            entity.Property(e => e.TransactionId).HasColumnName("transaction_id");
            entity.Property(e => e.Type).HasColumnName("type");

            entity.HasOne(d => d.Booking).WithMany(p => p.Payments)
                .HasForeignKey(d => d.BookingId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("payments_booking_id_fkey");

            entity.HasOne(d => d.Profile).WithMany(p => p.Payments)
                .HasForeignKey(d => d.ProfileId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("payments_profile_id_fkey");
        });

        modelBuilder.Entity<Profile>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("profiles_pkey");

            entity.ToTable("profiles");

            entity.HasIndex(e => e.DriverLicenseNumber, "profiles_driver_license_number_key").IsUnique();

            entity.HasIndex(e => e.PhoneNumber, "profiles_phone_number_key").IsUnique();

            entity.Property(e => e.Id)
                .ValueGeneratedNever()
                .HasColumnName("id");
            entity.Property(e => e.Address).HasColumnName("address");
            entity.Property(e => e.AvatarUrl).HasColumnName("avatar_url");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.DateOfBirth).HasColumnName("date_of_birth");
            entity.Property(e => e.DriverLicenseExpiry).HasColumnName("driver_license_expiry");
            entity.Property(e => e.DriverLicenseNumber).HasColumnName("driver_license_number");
            entity.Property(e => e.FirstName).HasColumnName("first_name");
            entity.Property(e => e.LastName).HasColumnName("last_name");
            entity.Property(e => e.PhoneNumber).HasColumnName("phone_number");
        });



        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
