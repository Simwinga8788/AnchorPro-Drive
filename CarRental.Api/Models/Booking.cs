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

    public string Status { get; set; } = null!;

    public int? InitialOdometer { get; set; }

    public int? FinalOdometer { get; set; }

    public string PaymentStatus { get; set; } = null!;

    public decimal? SecurityDepositAmount { get; set; }

    public string? SecurityDepositStatus { get; set; }

    public string? RentalAgreementUrl { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Car Car { get; set; } = null!;

    public virtual Profile Customer { get; set; } = null!;

    public virtual ICollection<Damage> Damages { get; set; } = new List<Damage>();

    public virtual Location DropoffLocation { get; set; } = null!;

    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();

    public virtual Location PickupLocation { get; set; } = null!;

    public virtual ICollection<ZraInvoice> ZraInvoices { get; set; } = new List<ZraInvoice>();
}
