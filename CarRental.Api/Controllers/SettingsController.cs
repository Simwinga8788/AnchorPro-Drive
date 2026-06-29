using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;
using CarRental.Api.Services;
using Microsoft.AspNetCore.Authorization;
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
    private readonly IEmailService _emailService;

    public SettingsController(AppDbContext context, IEmailService emailService)
    {
        _context = context;
        _emailService = emailService;
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
            return new List<string>();

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

    // ── Email Settings ────────────────────────────────────────────────────────

    [HttpGet("email-config")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> GetEmailConfig()
    {
        var keys = new[] { "Email_SmtpHost", "Email_SmtpPort", "Email_SenderEmail", "Email_SenderName", "Email_AppPassword", "Email_AdminEmail" };
        var settings = await _context.SiteSettings.Where(s => keys.Contains(s.Key)).ToListAsync();
        string Get(string key) => settings.FirstOrDefault(s => s.Key == key)?.Value ?? "";
        return Ok(new {
            smtpHost    = Get("Email_SmtpHost"),
            smtpPort    = Get("Email_SmtpPort"),
            senderEmail = Get("Email_SenderEmail"),
            senderName  = Get("Email_SenderName"),
            appPassword = Get("Email_AppPassword"),
            adminEmail  = Get("Email_AdminEmail"),
        });
    }

    [HttpPut("email-config")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> SaveEmailConfig([FromBody] EmailConfigRequest req)
    {
        var dict = new Dictionary<string, string>
        {
            ["Email_SmtpHost"]    = req.SmtpHost    ?? "",
            ["Email_SmtpPort"]    = req.SmtpPort    ?? "587",
            ["Email_SenderEmail"] = req.SenderEmail ?? "",
            ["Email_SenderName"]  = req.SenderName  ?? "Retrix Car Rental",
            ["Email_AppPassword"] = req.AppPassword ?? "",
            ["Email_AdminEmail"]  = req.AdminEmail  ?? "",
        };

        foreach (var kv in dict)
        {
            var existing = await _context.SiteSettings.FindAsync(kv.Key);
            if (existing == null)
                _context.SiteSettings.Add(new SiteSetting { Key = kv.Key, Value = kv.Value });
            else
                existing.Value = kv.Value;
        }
        await _context.SaveChangesAsync();
        return Ok(new { message = "Email configuration saved." });
    }

    [HttpPost("email-config/test")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> TestEmailConfig([FromBody] TestEmailRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.ToEmail))
            return BadRequest("Email address required.");

        var ok = await _emailService.SendTestEmailAsync(req.ToEmail);
        if (!ok)
            return BadRequest("Email config is not set up yet. Please save your settings first.");

        return Ok(new { message = $"Test email sent to {req.ToEmail}" });
    }
}

public class HeroVideoRequest
{
    public string? Url { get; set; }
}

public class EmailConfigRequest
{
    public string? SmtpHost    { get; set; }
    public string? SmtpPort    { get; set; }
    public string? SenderEmail { get; set; }
    public string? SenderName  { get; set; }
    public string? AppPassword { get; set; }
    public string? AdminEmail  { get; set; }
}

public class TestEmailRequest
{
    public string? ToEmail { get; set; }
}
