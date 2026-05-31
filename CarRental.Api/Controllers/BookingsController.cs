using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;
using CarRental.Api.Services;

namespace CarRental.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BookingsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly LencoService _lencoService;
    private readonly IServiceScopeFactory _scopeFactory;

    public BookingsController(AppDbContext context, LencoService lencoService, IServiceScopeFactory scopeFactory)
    {
        _context = context;
        _lencoService = lencoService;
        _scopeFactory = scopeFactory;
    }

    // GET: api/bookings
    [HttpGet]
    public async Task<IActionResult> GetBookings()
    {
        var bookings = await _context.Bookings
            .Include(b => b.Car)
            .Include(b => b.Customer)
            .Include(b => b.PickupLocation)
            .Include(b => b.DropoffLocation)
            .ToListAsync();
        return Ok(bookings);
    }

    // GET: api/bookings/{id}
    [HttpGet("{id}")]
    public async Task<IActionResult> GetBooking(Guid id)
    {
        var booking = await _context.Bookings
            .Include(b => b.Car)
            .Include(b => b.Customer)
            .Include(b => b.PickupLocation)
            .Include(b => b.DropoffLocation)
            .FirstOrDefaultAsync(b => b.Id == id);
            
        if (booking == null) return NotFound();
        return Ok(booking);
    }

    // POST: api/bookings
    [HttpPost]
    public async Task<IActionResult> CreateBooking([FromBody] Booking booking)
    {
        _context.Bookings.Add(booking);

        // Notify Admin
        var notification = new AdminNotification
        {
            Title = "New Booking Request",
            Message = $"New booking received for {booking.StartDate:MMM dd} to {booking.EndDate:MMM dd}.",
            Type = "Booking",
            BookingId = booking.Id
        };
        _context.AdminNotifications.Add(notification);

        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetBooking), new { id = booking.Id }, booking);
    }

    // POST: api/bookings/checkout
    [HttpPost("checkout")]
    public async Task<IActionResult> CheckoutBooking([FromBody] CheckoutRequest request)
    {
        var booking = request.Booking;
        
        if (booking.StartDate >= booking.EndDate) 
            return BadRequest("End date must be after start date.");

        var car = await _context.Cars.FindAsync(booking.CarId);
        if (car == null) return NotFound("Car not found.");

        if (car.Status != "Available") 
            return BadRequest("Car is not currently available for rental.");

        // Check for overlapping bookings
        bool isAlreadyBooked = await _context.Bookings.AnyAsync(b => 
            b.CarId == booking.CarId &&
            (b.Status == "Confirmed" || b.Status == "Active") &&
            b.StartDate < booking.EndDate && 
            b.EndDate > booking.StartDate);

        if (isAlreadyBooked) 
            return BadRequest("The car is already booked for the selected dates.");

        // Calculate total days (minimum 1 day)
        int totalDays = booking.EndDate.DayNumber - booking.StartDate.DayNumber;
        if (totalDays < 1) totalDays = 1;

        // Auto-calculate price
        booking.TotalPriceZmw = car.DailyRateZmw * totalDays;
        
        // If they choose Pay Later, it starts as a Quotation (Pending). If they pay now, it's Confirmed.
        booking.Status = request.PaymentMethod == "Pay Later" ? "Pending" : "Confirmed";
        booking.PaymentStatus = "Pending";
        
        // Initiate Lenco Mobile Money if requested
        if (request.PaymentMethod == "Mobile Money" && !string.IsNullOrEmpty(request.MobileNumber) && !string.IsNullOrEmpty(request.Provider))
        {
            booking.LencoReference = $"REF-{Guid.NewGuid().ToString().Substring(0, 8).ToUpper()}";
            var lencoRef = await _lencoService.InitiateMobileMoneyCollectionAsync(
                request.MobileNumber,
                booking.TotalPriceZmw,
                request.Provider,
                booking.LencoReference
            );
            
            if (lencoRef == null) 
            {
                return BadRequest("Failed to initiate mobile money payment with Lenco. Please try again or use another payment method.");
            }
        }
        
        _context.Bookings.Add(booking);
        await _context.SaveChangesAsync();

        if (request.PaymentMethod == "Mobile Money")
        {
            var bookingId = booking.Id;
            // Mock webhook delay for presentation
            Task.Run(async () =>
            {
                await Task.Delay(5000); // 5 seconds
                using var scope = _scopeFactory.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                var b = await db.Bookings.FindAsync(bookingId);
                if (b != null)
                {
                    b.PaymentStatus = "Paid";
                    await db.SaveChangesAsync();
                    Console.WriteLine($"[MOCK WEBHOOK] Booking {bookingId} successfully marked as Paid!");
                }
            });
        }

        return CreatedAtAction(nameof(GetBooking), new { id = booking.Id }, booking);
    }


    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateBooking(Guid id, [FromBody] Booking updatedBooking)
    {
        if (id != updatedBooking.Id) return BadRequest("ID mismatch");

        var existing = await _context.Bookings.FindAsync(id);
        if (existing == null) return NotFound();

        if (existing.PaymentStatus != "Paid" && updatedBooking.PaymentStatus == "Paid")
        {
            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                BookingId = existing.Id,
                ProfileId = existing.CustomerId,
                Currency = "ZMW",
                AmountZmw = existing.TotalPriceZmw,
                AmountUsd = existing.TotalPriceUsd,
                PaymentMethod = "Mobile Money",
                Type = "Rental",
                Status = "Completed",
                TransactionId = $"MANUAL-{DateTime.UtcNow:yyyyMMddHHmmss}",
                CreatedAt = DateTime.UtcNow
            };
            _context.Payments.Add(payment);
        }

        existing.Status = updatedBooking.Status;
        existing.PaymentStatus = updatedBooking.PaymentStatus;
        existing.InitialOdometer = updatedBooking.InitialOdometer;
        existing.FinalOdometer = updatedBooking.FinalOdometer;
        existing.SecurityDepositStatus = updatedBooking.SecurityDepositStatus;
        
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _context.Bookings.AnyAsync(b => b.Id == id)) return NotFound();
            throw;
        }

        return NoContent();
    }

    // DELETE: api/bookings/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteBooking(Guid id)
    {
        var booking = await _context.Bookings.FindAsync(id);
        if (booking == null) return NotFound();

        _context.Bookings.Remove(booking);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}

public class CheckoutRequest
{
    public Booking Booking { get; set; } = null!;
    public string? PaymentMethod { get; set; }
    public string? MobileNumber { get; set; }
    public string? Provider { get; set; }
}
