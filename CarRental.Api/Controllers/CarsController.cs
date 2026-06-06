using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;
using Microsoft.AspNetCore.Authorization;

namespace CarRental.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CarsController : ControllerBase
{
    private readonly AppDbContext _context;

    public CarsController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/cars
    [HttpGet]
    public async Task<IActionResult> GetCars()
    {
        var cars = await _context.Cars
            .Include(c => c.Location)
            .ToListAsync();
        return Ok(cars);
    }

    // GET: api/cars/available?startDate=2024-06-01&endDate=2024-06-10
    [HttpGet("available")]
    public async Task<IActionResult> GetAvailableCars([FromQuery] DateOnly startDate, [FromQuery] DateOnly endDate)
    {
        if (startDate >= endDate) return BadRequest("End date must be after start date.");

        var availableCars = await _context.Cars
            .Include(c => c.Location)
            .Where(c => c.Status == "Available")
            .Where(c => !c.Bookings.Any(b => 
                (b.Status == "Confirmed" || b.Status == "Active") &&
                b.StartDate < endDate && b.EndDate > startDate))
            .ToListAsync();

        return Ok(availableCars);
    }

    // GET: api/cars/{id}
    [HttpGet("{id}")]
    public async Task<IActionResult> GetCar(Guid id)
    {
        var car = await _context.Cars
            .Include(c => c.Location)
            .FirstOrDefaultAsync(c => c.Id == id);
            
        if (car == null) return NotFound();
        return Ok(car);
    }

    // POST: api/cars
    [HttpPost]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> CreateCar([FromBody] Car car)
    {
        if (string.IsNullOrWhiteSpace(car.Vin))
        {
            car.Vin = "AUTOVIN-" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper();
        }

        _context.Cars.Add(car);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetCar), new { id = car.Id }, car);
    }

    // PUT: api/cars/{id}
    [HttpPut("{id}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> UpdateCar(Guid id, [FromBody] Car updatedCar)
    {
        if (id != updatedCar.Id) return BadRequest("ID mismatch");

        var existingCar = await _context.Cars.FindAsync(id);
        if (existingCar == null) return NotFound();

        // Update properties
        existingCar.Make = updatedCar.Make;
        existingCar.Model = updatedCar.Model;
        existingCar.Year = updatedCar.Year;
        existingCar.LicensePlate = updatedCar.LicensePlate;
        existingCar.Vin = updatedCar.Vin;
        existingCar.Transmission = updatedCar.Transmission;
        existingCar.FuelType = updatedCar.FuelType;
        existingCar.Seats = updatedCar.Seats;
        existingCar.DailyRateZmw = updatedCar.DailyRateZmw;
        existingCar.DailyRateUsd = updatedCar.DailyRateUsd;
        existingCar.DailyRateOutofTownZmw = updatedCar.DailyRateOutofTownZmw;
        existingCar.DailyRateOutofTownUsd = updatedCar.DailyRateOutofTownUsd;
        existingCar.Features = updatedCar.Features;
        existingCar.ImageUrls = updatedCar.ImageUrls;
        existingCar.CurrentOdometer = updatedCar.CurrentOdometer;
        existingCar.Status = updatedCar.Status;
        existingCar.InsuranceExpiryDate = updatedCar.InsuranceExpiryDate;
        existingCar.RoadTaxExpiryDate = updatedCar.RoadTaxExpiryDate;
        existingCar.LocationId = updatedCar.LocationId;
        existingCar.IsShuttleOnly = updatedCar.IsShuttleOnly;
        existingCar.UpdatedAt = DateTime.UtcNow;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            throw;
        }

        return NoContent();
    }

    // DELETE: api/cars/{id}
    [HttpDelete("{id}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> DeleteCar(Guid id)
    {
        var car = await _context.Cars.FindAsync(id);
        if (car == null) return NotFound();

        _context.Cars.Remove(car);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
