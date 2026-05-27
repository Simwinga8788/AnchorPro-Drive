using System;
using System.Collections.Generic;

namespace CarRental.Api.Models;

public partial class Damage
{
    public Guid Id { get; set; }

    public Guid CarId { get; set; }

    public Guid? BookingId { get; set; }

    public Guid? ReportedByProfileId { get; set; }

    public string Description { get; set; } = null!;

    public string? Severity { get; set; }

    public List<string>? ImageUrls { get; set; }

    public decimal? RepairCostEstimate { get; set; }

    public string? RepairStatus { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Booking? Booking { get; set; }

    public virtual Car Car { get; set; } = null!;

    public virtual Profile? ReportedByProfile { get; set; }
}
