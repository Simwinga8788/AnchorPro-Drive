using System;
using System.Collections.Generic;

namespace CarRental.Api.Models;

public partial class Profile
{
    public Guid Id { get; set; }

    public string FirstName { get; set; } = null!;

    public string LastName { get; set; } = null!;

    public string? PhoneNumber { get; set; }

    public string? DriverLicenseNumber { get; set; }

    public DateOnly DriverLicenseExpiry { get; set; }

    public string? Address { get; set; }

    public DateOnly DateOfBirth { get; set; }

    public string? AvatarUrl { get; set; }

    public string? Email { get; set; }

    public bool IsAdmin { get; set; } = false;

    public bool IsSuspended { get; set; } = false;

    public DateTime? CreatedAt { get; set; }

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public virtual ICollection<Damage> Damages { get; set; } = new List<Damage>();

    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();

    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();
}
