using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;

namespace CarRental.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class WebhooksController : ControllerBase
{
    private readonly AppDbContext _context;

    public WebhooksController(AppDbContext context)
    {
        _context = context;
    }

    [HttpPost("lenco")]
    public async Task<IActionResult> LencoWebhook([FromBody] LencoWebhookPayload payload)
    {
        // For security, you would normally verify a signature header here
        
        if (payload == null || string.IsNullOrEmpty(payload.Reference))
        {
            return BadRequest();
        }

        var booking = await _context.Bookings.FirstOrDefaultAsync(b => b.LencoReference == payload.Reference);
        if (booking == null)
        {
            return NotFound();
        }

        if (payload.Status == "successful")
        {
            booking.PaymentStatus = "Paid";
            
            // Generate a Payment ledger record
            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                BookingId = booking.Id,
                ProfileId = booking.CustomerId,
                AmountZmw = payload.Amount,
                Currency = "ZMW",
                PaymentMethod = "Mobile Money",
                Status = "Completed",
                TransactionId = payload.TransactionId,
                Type = "Rental Fee",
                CreatedAt = DateTime.UtcNow
            };
            
            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();
        }
        else if (payload.Status == "failed" || payload.Status == "rejected")
        {
            booking.PaymentStatus = "Failed";
            await _context.SaveChangesAsync();
        }

        return Ok();
    }
}

public class LencoWebhookPayload
{
    public string Reference { get; set; } = null!;
    public string Status { get; set; } = null!;
    public decimal Amount { get; set; }
    public string? TransactionId { get; set; }
}
