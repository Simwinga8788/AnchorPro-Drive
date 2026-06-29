namespace CarRental.Api.Services;

public static class EmailTemplates
{
    private const string BrandColor = "#1a56db";
    private const string GoldColor = "#d4a017";
    private const string GreenColor = "#10b981";
    private const string RedColor = "#ef4444";

    private static string Wrap(string content) => $@"
<!DOCTYPE html>
<html lang=""en"">
<head>
  <meta charset=""UTF-8"" />
  <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"" />
  <title>Retrix Car Rental</title>
</head>
<body style=""margin:0;padding:0;background:#f1f5f9;font-family:'Segoe UI',Arial,sans-serif;"">
  <table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""background:#f1f5f9;padding:32px 16px;"">
    <tr><td align=""center"">
      <table width=""600"" cellpadding=""0"" cellspacing=""0"" style=""max-width:600px;width:100%;"">

        <!-- Header -->
        <tr><td style=""background:linear-gradient(135deg,#1a56db,#1e3a8a);border-radius:16px 16px 0 0;padding:32px 40px;text-align:center;"">
          <div style=""font-size:28px;font-weight:800;color:#fff;letter-spacing:-0.5px;"">RETRIX</div>
          <div style=""font-size:12px;color:rgba(255,255,255,0.7);letter-spacing:3px;text-transform:uppercase;margin-top:4px;"">Car Rental</div>
        </td></tr>

        <!-- Body -->
        <tr><td style=""background:#ffffff;padding:40px;border-radius:0 0 16px 16px;"">
          {content}
        </td></tr>

        <!-- Footer -->
        <tr><td style=""text-align:center;padding:24px 0;"">
          <p style=""margin:0;font-size:12px;color:#94a3b8;"">© 2025 Retrix Car Rental. All rights reserved.</p>
          <p style=""margin:4px 0 0;font-size:12px;color:#94a3b8;"">Support: simwinga8788@gmail.com | +260 972 996 902</p>
        </td></tr>

      </table>
    </td></tr>
  </table>
</body>
</html>";

    private static string InfoRow(string label, string value) =>
        $@"<tr>
          <td style=""padding:10px 0;border-bottom:1px solid #f1f5f9;font-size:13px;color:#64748b;width:40%;"">{label}</td>
          <td style=""padding:10px 0;border-bottom:1px solid #f1f5f9;font-size:13px;color:#1e293b;font-weight:600;"">{value}</td>
        </tr>";

    // ── Booking Confirmation ─────────────────────────────────────────────────

    public static string BookingConfirmation(string customerName, string carName, DateOnly startDate, DateOnly endDate, decimal totalZmw, string bookingId)
    {
        int days = endDate.DayNumber - startDate.DayNumber;
        var content = $@"
          <h1 style=""margin:0 0 8px;font-size:24px;font-weight:800;color:#1e293b;"">Your booking is confirmed! 🎉</h1>
          <p style=""margin:0 0 28px;font-size:15px;color:#64748b;"">Hi {customerName}, great news — your car is reserved and ready.</p>

          <div style=""background:#eff6ff;border:1px solid #bfdbfe;border-radius:12px;padding:20px 24px;margin-bottom:28px;"">
            <div style=""font-size:13px;font-weight:700;color:{BrandColor};text-transform:uppercase;letter-spacing:0.08em;margin-bottom:14px;"">Booking Summary</div>
            <table width=""100%"" cellpadding=""0"" cellspacing=""0"">
              {InfoRow("Booking Ref", bookingId.ToUpper()[..8])}
              {InfoRow("Vehicle", carName)}
              {InfoRow("Pick-up Date", startDate.ToString("dd MMM yyyy"))}
              {InfoRow("Return Date", endDate.ToString("dd MMM yyyy"))}
              {InfoRow("Duration", $"{days} day{(days == 1 ? "" : "s")}")}
              {InfoRow("Total Amount", $"K{totalZmw:N2}")}
            </table>
          </div>

          <div style=""background:#f0fdf4;border:1px solid #bbf7d0;border-radius:12px;padding:16px 20px;margin-bottom:28px;"">
            <p style=""margin:0;font-size:14px;color:#166534;""><strong>💳 Payment:</strong> Payment is collected at the counter when you pick up your vehicle. Please bring a valid ID and driver's license.</p>
          </div>

          <p style=""font-size:14px;color:#64748b;line-height:1.6;"">If you have any questions before your rental, don't hesitate to reach out to us. We look forward to seeing you!</p>
          <p style=""margin:24px 0 0;font-size:14px;color:#1e293b;"">Warm regards,<br/><strong>The Retrix Team</strong></p>";

        return Wrap(content);
    }

    // ── Booking Status Update ────────────────────────────────────────────────

    public static (string Subject, string Html) BookingStatusUpdate(string customerName, string carName, string newStatus, string bookingId)
    {
        string subject, emoji, title, message, color;

        switch (newStatus)
        {
            case "Active":
                subject = "🚗 Your rental has started!";
                emoji = "🚗";
                title = "Your rental is now active!";
                message = $"Your {carName} has been picked up and your rental is underway. Enjoy the drive and drive safely!";
                color = BrandColor;
                break;
            case "Completed":
                subject = "✅ Rental complete — Thank you!";
                emoji = "✅";
                title = "Thanks for choosing Retrix!";
                message = $"Your rental of the {carName} is now complete. We hope you had a great experience and look forward to serving you again!";
                color = GreenColor;
                break;
            case "Cancelled":
                subject = "❌ Your booking has been cancelled";
                emoji = "❌";
                title = "Your booking has been cancelled";
                message = $"Your booking for the {carName} (Ref: {bookingId.ToUpper()[..8]}) has been cancelled. If you did not request this, please contact us immediately.";
                color = RedColor;
                break;
            default:
                subject = $"📋 Booking update: {newStatus}";
                emoji = "📋";
                title = $"Booking status updated to {newStatus}";
                message = $"Your booking for the {carName} has been updated to <strong>{newStatus}</strong>.";
                color = BrandColor;
                break;
        }

        var content = $@"
          <div style=""text-align:center;margin-bottom:28px;"">
            <div style=""font-size:48px;margin-bottom:12px;"">{emoji}</div>
            <h1 style=""margin:0 0 8px;font-size:22px;font-weight:800;color:#1e293b;"">{title}</h1>
            <p style=""margin:0;font-size:15px;color:#64748b;"">Hi {customerName},</p>
          </div>

          <div style=""background:#f8fafc;border-left:4px solid {color};border-radius:0 12px 12px 0;padding:16px 20px;margin-bottom:28px;"">
            <p style=""margin:0;font-size:14px;color:#334155;line-height:1.6;"">{message}</p>
          </div>

          <p style=""font-size:14px;color:#64748b;"">Need help? Contact us at <a href=""mailto:simwinga8788@gmail.com"" style=""color:{BrandColor};"">simwinga8788@gmail.com</a> or call <strong>+260 972 996 902</strong>.</p>
          <p style=""margin:20px 0 0;font-size:14px;color:#1e293b;"">Best regards,<br/><strong>Retrix Car Rental</strong></p>";

        return (subject, Wrap(content));
    }

    // ── Admin — New Booking ──────────────────────────────────────────────────

    public static string AdminNewBooking(string customerName, string customerEmail, string carName, DateOnly startDate, DateOnly endDate, decimal totalZmw, string bookingId)
    {
        int days = endDate.DayNumber - startDate.DayNumber;
        var content = $@"
          <h1 style=""margin:0 0 8px;font-size:22px;font-weight:800;color:#1e293b;"">🔔 New Booking Received</h1>
          <p style=""margin:0 0 28px;font-size:14px;color:#64748b;"">A new booking has just been submitted through the Retrix platform.</p>

          <div style=""background:#eff6ff;border:1px solid #bfdbfe;border-radius:12px;padding:20px 24px;margin-bottom:24px;"">
            <div style=""font-size:12px;font-weight:700;color:{BrandColor};text-transform:uppercase;letter-spacing:0.08em;margin-bottom:14px;"">Booking Details</div>
            <table width=""100%"" cellpadding=""0"" cellspacing=""0"">
              {InfoRow("Booking Ref", bookingId.ToUpper()[..8])}
              {InfoRow("Customer", customerName)}
              {InfoRow("Email", customerEmail)}
              {InfoRow("Vehicle", carName)}
              {InfoRow("From", startDate.ToString("dd MMM yyyy"))}
              {InfoRow("To", endDate.ToString("dd MMM yyyy"))}
              {InfoRow("Days", days.ToString())}
              {InfoRow("Total (ZMW)", $"K{totalZmw:N2}")}
            </table>
          </div>

          <p style=""font-size:13px;color:#94a3b8;"">Log in to the admin dashboard to manage this booking.</p>";

        return Wrap(content);
    }

    // ── Damage Notice ────────────────────────────────────────────────────────

    public static string DamageNotice(string customerName, string carName, decimal chargeZmw, string description)
    {
        var content = $@"
          <div style=""text-align:center;margin-bottom:28px;"">
            <div style=""font-size:48px;margin-bottom:12px;"">⚠️</div>
            <h1 style=""margin:0 0 8px;font-size:22px;font-weight:800;color:#1e293b;"">Damage Fee Notice</h1>
            <p style=""margin:0;font-size:15px;color:#64748b;"">Hi {customerName},</p>
          </div>

          <p style=""font-size:14px;color:#334155;line-height:1.6;margin-bottom:20px;"">
            A damage assessment has been completed for your recent rental of the <strong>{carName}</strong>. A fee has been recorded on your account.
          </p>

          <div style=""background:#fef2f2;border:1px solid #fecaca;border-radius:12px;padding:20px 24px;margin-bottom:24px;"">
            <table width=""100%"" cellpadding=""0"" cellspacing=""0"">
              {InfoRow("Vehicle", carName)}
              {InfoRow("Damage Description", description)}
              {InfoRow("Amount Due", $"K{chargeZmw:N2}")}
            </table>
          </div>

          <p style=""font-size:14px;color:#64748b;line-height:1.6;"">Please contact us if you have any questions or would like to dispute this charge.</p>
          <p style=""margin:20px 0 0;font-size:14px;color:#1e293b;"">Regards,<br/><strong>Retrix Car Rental</strong></p>";

        return Wrap(content);
    }

    // ── Test Email ───────────────────────────────────────────────────────────

    public static string TestEmail()
    {
        var content = $@"
          <div style=""text-align:center;"">
            <div style=""font-size:56px;margin-bottom:16px;"">✅</div>
            <h1 style=""margin:0 0 8px;font-size:24px;font-weight:800;color:#1e293b;"">Email Configuration Successful!</h1>
            <p style=""margin:0 0 24px;font-size:15px;color:#64748b;"">Your Retrix email system is working correctly.</p>
            <div style=""background:#f0fdf4;border:1px solid #bbf7d0;border-radius:12px;padding:16px 20px;display:inline-block;"">
              <p style=""margin:0;font-size:14px;color:#166534;"">Customers and admins will now receive email notifications for bookings, status changes, and more.</p>
            </div>
            <p style=""margin:28px 0 0;font-size:13px;color:#94a3b8;"">This is an automated test from the Retrix Admin Dashboard.</p>
          </div>";

        return Wrap(content);
    }
}
