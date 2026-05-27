using System;
using System.Collections.Generic;

namespace CarRental.Api.Models;

public partial class Location
{
    public Guid Id { get; set; }

    public string Name { get; set; } = null!;

    public string Address { get; set; } = null!;

    public string? ContactPhone { get; set; }

    public decimal? Latitude { get; set; }

    public decimal? Longitude { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual ICollection<Booking> BookingDropoffLocations { get; set; } = new List<Booking>();

    public virtual ICollection<Booking> BookingPickupLocations { get; set; } = new List<Booking>();

    public virtual ICollection<Car> Cars { get; set; } = new List<Car>();
}
