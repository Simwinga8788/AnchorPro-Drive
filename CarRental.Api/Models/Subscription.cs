using System;
using System.Collections.Generic;

namespace CarRental.Api.Models;

public partial class Subscription
{
    public long Id { get; set; }

    public Guid SubscriptionId { get; set; }

    public string Claims { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public string? ActionFilter { get; set; }
}
