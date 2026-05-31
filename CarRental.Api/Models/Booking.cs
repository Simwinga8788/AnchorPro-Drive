using System;
using System.Collections.Generic;

namespace CarRental.Api.Models;

public partial class Booking
{
    public Guid Id { get; set; }

    public Guid CarId { get; set; }

    public Guid CustomerId { get; set; }

    public DateOnly StartDate { get; set; }

    public DateOnly EndDate { get; set; }

    public Guid PickupLocationId { get; set; }

    public Guid DropoffLocationId { get; set; }

    public decimal TotalPriceZmw { get; set; }

    public decimal? TotalPriceUsd { get; set; }

    public string? Status { get; set; }

    public int? InitialOdometer { get; set; }

    public int? FinalOdometer { get; set; }

    public string? PaymentStatus { get; set; }

    public decimal? SecurityDepositAmount { get; set; }

    public string? SecurityDepositStatus { get; set; }

    public string? RentalAgreementUrl { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public string? LencoReference { get; set; }

    public string? BookingType { get; set; } = "Standard";

    public string? Notes { get; set; }

    public virtual Car? Car { get; set; }

    public virtual Profile? Customer { get; set; }

    public virtual ICollection<Damage> Damages { get; set; } = new List<Damage>();



    public virtual Location? DropoffLocation { get; set; }

    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();

    public virtual Location? PickupLocation { get; set; }
}
