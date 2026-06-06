using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;
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
    private readonly AppDbContext _context;

    public SettingsController(AppDbContext context)
    {
        _context = context;
    }

    // ── Hero Images ──────────────────────────────────────────────────────────

    [HttpGet("hero-images")]
    public async Task<IActionResult> GetHeroImages()
    {
        var images = await LoadImages();
        return Ok(images);
    }

    [HttpPut("hero-images")]
    public async Task<IActionResult> UpdateHeroImages([FromBody] List<string> images)
    {
        if (images == null) return BadRequest("Images list is required.");
        await SaveImages(images);
        return Ok(images);
    }

    // ── Hero Video ───────────────────────────────────────────────────────────

    [HttpGet("hero-video")]
    public async Task<IActionResult> GetHeroVideo()
    {
        var url = await LoadVideo();
        return Ok(new { url });
    }

    [HttpPut("hero-video")]
    public async Task<IActionResult> UpdateHeroVideo([FromBody] HeroVideoRequest req)
    {
        await SaveVideo(req?.Url ?? "");
        return Ok(new { url = req?.Url ?? "" });
    }

    [HttpDelete("hero-video")]
    public async Task<IActionResult> DeleteHeroVideo()
    {
        await SaveVideo("");
        return Ok(new { url = "" });
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private async Task<List<string>> LoadImages()
    {
        var setting = await _context.SiteSettings.FindAsync("HeroImages");
        if (setting == null || string.IsNullOrWhiteSpace(setting.Value))
            return new List<string>
            {
                "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1600&q=90"
            };

        return System.Text.Json.JsonSerializer.Deserialize<List<string>>(setting.Value)
            ?? new List<string>();
    }

    private async Task SaveImages(List<string> images)
    {
        var json = System.Text.Json.JsonSerializer.Serialize(images);
        var setting = await _context.SiteSettings.FindAsync("HeroImages");
        if (setting == null)
        {
            _context.SiteSettings.Add(new SiteSetting { Key = "HeroImages", Value = json });
        }
        else
        {
            setting.Value = json;
        }
        await _context.SaveChangesAsync();
    }

    private async Task<string> LoadVideo()
    {
        var setting = await _context.SiteSettings.FindAsync("HeroVideoUrl");
        return setting?.Value ?? "";
    }

    private async Task SaveVideo(string url)
    {
        var setting = await _context.SiteSettings.FindAsync("HeroVideoUrl");
        if (setting == null)
        {
            _context.SiteSettings.Add(new SiteSetting { Key = "HeroVideoUrl", Value = url });
        }
        else
        {
            setting.Value = url;
        }
        await _context.SaveChangesAsync();
    }
}

public class HeroVideoRequest
{
    public string? Url { get; set; }
}
