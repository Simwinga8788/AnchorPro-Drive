using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using CarRental.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace CarRental.Api.Services;

public interface IEmailService
{
    Task SendBookingConfirmationAsync(string toEmail, string customerName, string carName, DateOnly startDate, DateOnly endDate, decimal totalZmw, string bookingId);
    Task SendBookingStatusUpdateAsync(string toEmail, string customerName, string carName, string newStatus, string bookingId);
    Task SendAdminNewBookingAsync(string customerName, string customerEmail, string carName, DateOnly startDate, DateOnly endDate, decimal totalZmw, string bookingId);
    Task SendDamageNoticeAsync(string toEmail, string customerName, string carName, decimal chargeZmw, string description);
    Task<bool> SendTestEmailAsync(string toEmail);
}

public class EmailService : IEmailService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IServiceScopeFactory scopeFactory, ILogger<EmailService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    // ── Load config from SiteSettings DB ────────────────────────────────────

    private async Task<EmailConfig?> LoadConfigAsync()
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var keys = new[] { "Email_SmtpHost", "Email_SmtpPort", "Email_SenderEmail", "Email_SenderName", "Email_AppPassword", "Email_AdminEmail" };
        var settings = await db.SiteSettings.Where(s => keys.Contains(s.Key)).ToListAsync();

        string Get(string key) => settings.FirstOrDefault(s => s.Key == key)?.Value ?? "";

        var host = Get("Email_SmtpHost");
        var senderEmail = Get("Email_SenderEmail");
        var appPassword = Get("Email_AppPassword");

        if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(senderEmail) || string.IsNullOrWhiteSpace(appPassword))
            return null;

        return new EmailConfig
        {
            SmtpHost = host,
            SmtpPort = int.TryParse(Get("Email_SmtpPort"), out var port) ? port : 587,
            SenderEmail = senderEmail,
            SenderName = string.IsNullOrWhiteSpace(Get("Email_SenderName")) ? "Retrix Car Rental" : Get("Email_SenderName"),
            AppPassword = appPassword,
            AdminEmail = Get("Email_AdminEmail"),
        };
    }

    // ── Core Send ────────────────────────────────────────────────────────────

    private async Task SendAsync(EmailConfig config, string toEmail, string toName, string subject, string htmlBody)
    {
        try
        {
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress(config.SenderName, config.SenderEmail));
            message.To.Add(new MailboxAddress(toName, toEmail));
            message.Subject = subject;
            message.Body = new BodyBuilder { HtmlBody = htmlBody }.ToMessageBody();

            using var client = new SmtpClient();
            await client.ConnectAsync(config.SmtpHost, config.SmtpPort, SecureSocketOptions.StartTls);
            await client.AuthenticateAsync(config.SenderEmail, config.AppPassword);
            await client.SendAsync(message);
            await client.DisconnectAsync(true);
            _logger.LogInformation("Email sent to {Email}: {Subject}", toEmail, subject);
        }
        catch (Exception ex)
        {
            // Never let email failure crash a booking operation
            _logger.LogError(ex, "Failed to send email to {Email}: {Subject}", toEmail, subject);
        }
    }

    // ── Public Methods ───────────────────────────────────────────────────────

    public async Task SendBookingConfirmationAsync(string toEmail, string customerName, string carName, DateOnly startDate, DateOnly endDate, decimal totalZmw, string bookingId)
    {
        var config = await LoadConfigAsync();
        if (config == null) return;

        var html = EmailTemplates.BookingConfirmation(customerName, carName, startDate, endDate, totalZmw, bookingId);
        await SendAsync(config, toEmail, customerName, "✅ Your Retrix Booking is Confirmed!", html);
    }

    public async Task SendBookingStatusUpdateAsync(string toEmail, string customerName, string carName, string newStatus, string bookingId)
    {
        var config = await LoadConfigAsync();
        if (config == null) return;

        var (subject, html) = EmailTemplates.BookingStatusUpdate(customerName, carName, newStatus, bookingId);
        await SendAsync(config, toEmail, customerName, subject, html);
    }

    public async Task SendAdminNewBookingAsync(string customerName, string customerEmail, string carName, DateOnly startDate, DateOnly endDate, decimal totalZmw, string bookingId)
    {
        var config = await LoadConfigAsync();
        if (config == null || string.IsNullOrWhiteSpace(config.AdminEmail)) return;

        var html = EmailTemplates.AdminNewBooking(customerName, customerEmail, carName, startDate, endDate, totalZmw, bookingId);
        await SendAsync(config, config.AdminEmail, "Admin", $"🔔 New Booking — {customerName}", html);
    }

    public async Task SendDamageNoticeAsync(string toEmail, string customerName, string carName, decimal chargeZmw, string description)
    {
        var config = await LoadConfigAsync();
        if (config == null) return;

        var html = EmailTemplates.DamageNotice(customerName, carName, chargeZmw, description);
        await SendAsync(config, toEmail, customerName, "⚠️ Damage Fee Notice — Retrix Car Rental", html);
    }

    public async Task<bool> SendTestEmailAsync(string toEmail)
    {
        var config = await LoadConfigAsync();
        if (config == null) return false;

        var html = EmailTemplates.TestEmail();
        await SendAsync(config, toEmail, "Admin", "✅ Retrix Email Test — Connection Successful", html);
        return true;
    }
}

public class EmailConfig
{
    public string SmtpHost { get; set; } = "";
    public int SmtpPort { get; set; } = 587;
    public string SenderEmail { get; set; } = "";
    public string SenderName { get; set; } = "Retrix Car Rental";
    public string AppPassword { get; set; } = "";
    public string AdminEmail { get; set; } = "";
}
