using Microsoft.AspNetCore.Mvc;

namespace CarRental.Api.Controllers;

/// <summary>
/// Manages site-wide settings stored server-side (e.g. hero images).
/// Settings are persisted to a simple JSON file so they survive restarts
/// without needing a DB migration.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class SettingsController : ControllerBase
{
    private static readonly string SettingsPath =
        Path.Combine(AppContext.BaseDirectory, "site_settings.json");

    [HttpGet("hero-images")]
    public IActionResult GetHeroImages()
    {
        var images = Load();
        return Ok(images);
    }

    [HttpPut("hero-images")]
    public IActionResult UpdateHeroImages([FromBody] List<string> images)
    {
        if (images == null) return BadRequest("Images list is required.");
        Save(images);
        return Ok(images);
    }

    private static List<string> Load()
    {
        if (!System.IO.File.Exists(SettingsPath))
            return new List<string>
            {
                "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1600&q=90"
            };

        var json = System.IO.File.ReadAllText(SettingsPath);
        return System.Text.Json.JsonSerializer.Deserialize<List<string>>(json)
            ?? new List<string>();
    }

    private static void Save(List<string> images)
    {
        var json = System.Text.Json.JsonSerializer.Serialize(images);
        System.IO.File.WriteAllText(SettingsPath, json);
    }
}
