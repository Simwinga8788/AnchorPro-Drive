using Microsoft.AspNetCore.Mvc;

namespace CarRental.Api.Controllers;

/// <summary>
/// Manages site-wide settings stored server-side (e.g. hero images, hero video).
/// Settings are persisted to simple JSON files so they survive restarts
/// without needing a DB migration.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class SettingsController : ControllerBase
{
    private static readonly string SettingsPath =
        Path.Combine(AppContext.BaseDirectory, "site_settings.json");

    private static readonly string VideoSettingsPath =
        Path.Combine(AppContext.BaseDirectory, "site_settings_video.json");

    // ── Hero Images ──────────────────────────────────────────────────────────

    [HttpGet("hero-images")]
    public IActionResult GetHeroImages()
    {
        var images = LoadImages();
        return Ok(images);
    }

    [HttpPut("hero-images")]
    public IActionResult UpdateHeroImages([FromBody] List<string> images)
    {
        if (images == null) return BadRequest("Images list is required.");
        SaveImages(images);
        return Ok(images);
    }

    // ── Hero Video ───────────────────────────────────────────────────────────

    [HttpGet("hero-video")]
    public IActionResult GetHeroVideo()
    {
        var url = LoadVideo();
        return Ok(new { url });
    }

    [HttpPut("hero-video")]
    public IActionResult UpdateHeroVideo([FromBody] HeroVideoRequest req)
    {
        SaveVideo(req?.Url ?? "");
        return Ok(new { url = req?.Url ?? "" });
    }

    [HttpDelete("hero-video")]
    public IActionResult DeleteHeroVideo()
    {
        SaveVideo("");
        return Ok(new { url = "" });
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private static List<string> LoadImages()
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

    private static void SaveImages(List<string> images)
    {
        var json = System.Text.Json.JsonSerializer.Serialize(images);
        System.IO.File.WriteAllText(SettingsPath, json);
    }

    private static string LoadVideo()
    {
        if (!System.IO.File.Exists(VideoSettingsPath)) return "";
        var json = System.IO.File.ReadAllText(VideoSettingsPath);
        var obj = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, string>>(json);
        return obj != null && obj.TryGetValue("url", out var url) ? url : "";
    }

    private static void SaveVideo(string url)
    {
        var json = System.Text.Json.JsonSerializer.Serialize(new Dictionary<string, string> { ["url"] = url });
        System.IO.File.WriteAllText(VideoSettingsPath, json);
    }
}

public class HeroVideoRequest
{
    public string? Url { get; set; }
}
