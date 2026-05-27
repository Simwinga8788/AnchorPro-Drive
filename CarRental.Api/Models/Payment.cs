using System;
using System.Collections.Generic;

namespace CarRental.Api.Models;

public partial class Payment
{
    public Guid Id { get; set; }

    public Guid BookingId { get; set; }

    public Guid ProfileId { get; set; }

    public decimal AmountZmw { get; set; }

    public decimal? AmountUsd { get; set; }

    public string Currency { get; set; } = null!;

    public string PaymentMethod { get; set; } = null!;

    public string? TransactionId { get; set; }

    public string Status { get; set; } = null!;

    public string Type { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public virtual Booking Booking { get; set; } = null!;

    public virtual Profile Profile { get; set; } = null!;
}
