using System;
using System.Collections.Generic;

namespace CarRental.Api.Models;

public partial class ZraInvoice
{
    public Guid Id { get; set; }

    public Guid BookingId { get; set; }

    public string InvoiceNumber { get; set; } = null!;

    public string? ZraReferenceNumber { get; set; }

    public string SubmissionStatus { get; set; } = null!;

    public string? SubmissionPayload { get; set; }

    public string? ZraResponse { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Booking Booking { get; set; } = null!;
}
