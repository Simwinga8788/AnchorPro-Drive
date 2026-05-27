using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;

namespace CarRental.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BookingsController : ControllerBase
{
    private readonly AppDbContext _context;

    public BookingsController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/bookings
    [HttpGet]
    public async Task<IActionResult> GetBookings()
    {
        var bookings = await _context.Bookings
            .Include(b => b.Car)
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
            .Include(b => b.PickupLocation)
            .Include(b => b.DropoffLocation)
            .FirstOrDefaultAsync(b => b.Id == id);
            
        if (booking == null) return NotFound();
        return Ok(booking);
    }

    // POST: api/bookings/checkout
    [HttpPost("checkout")]
    public async Task<IActionResult> CheckoutBooking([FromBody] Booking booking)
    {
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
        
        // Ensure defaults are set
        booking.Status = "Confirmed";
        booking.PaymentStatus = "Pending";
        
        _context.Bookings.Add(booking);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetBooking), new { id = booking.Id }, booking);
    }

    // POST: api/bookings
    [HttpPost]
    public async Task<IActionResult> CreateBooking([FromBody] Booking booking)
    {
        _context.Bookings.Add(booking);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetBooking), new { id = booking.Id }, booking);
    }

    // PUT: api/bookings/{id}
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateBooking(Guid id, [FromBody] Booking updatedBooking)
    {
        if (id != updatedBooking.Id) return BadRequest("ID mismatch");

        _context.Entry(updatedBooking).State = EntityState.Modified;
        
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
