using System.ComponentModel.DataAnnotations;

namespace CarRental.Api.Models;

public class SiteSetting
{
    [Key]
    public string Key { get; set; } = null!;
    
    public string Value { get; set; } = null!;
}
