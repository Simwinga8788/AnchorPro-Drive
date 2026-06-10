using System;
using System.Collections.Generic;

namespace CarRental.Api.Models;

public partial class Car
{
    public Guid Id { get; set; }

    public string Make { get; set; } = null!;

    public string Model { get; set; } = null!;

    public int? Year { get; set; }

    public string? LicensePlate { get; set; }

    public string? Vin { get; set; }

    public string Transmission { get; set; } = null!;

    public string FuelType { get; set; } = null!;

    public int Seats { get; set; }

    public decimal DailyRateZmw { get; set; }

    public decimal? DailyRateUsd { get; set; }

    public decimal? DailyRateOutofTownZmw { get; set; }

    public decimal? DailyRateOutofTownUsd { get; set; }

    public List<string>? Features { get; set; }

    public List<string>? ImageUrls { get; set; }

    public int CurrentOdometer { get; set; }

    public string Status { get; set; } = null!;

    public DateOnly? InsuranceExpiryDate { get; set; }

    public DateOnly? RoadTaxExpiryDate { get; set; }

    public Guid? LocationId { get; set; }

    public bool IsShuttleOnly { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public virtual ICollection<Damage> Damages { get; set; } = new List<Damage>();

    public virtual Location? Location { get; set; }
}
