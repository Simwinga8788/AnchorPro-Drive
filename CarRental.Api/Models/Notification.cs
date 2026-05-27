using System;
using System.Collections.Generic;

namespace CarRental.Api.Models;

public partial class Notification
{
    public Guid Id { get; set; }

    public Guid ProfileId { get; set; }

    public string Type { get; set; } = null!;

    public string Message { get; set; } = null!;

    public bool? IsRead { get; set; }

    public DateTime? SentAt { get; set; }

    public virtual Profile Profile { get; set; } = null!;
}
