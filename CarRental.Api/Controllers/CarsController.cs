using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;

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
    public async Task<IActionResult> UpdateCar(Guid id, [FromBody] Car updatedCar)
    {
        if (id != updatedCar.Id) return BadRequest("ID mismatch");

        _context.Entry(updatedCar).State = EntityState.Modified;
        
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _context.Cars.AnyAsync(c => c.Id == id)) return NotFound();
            throw;
        }

        return NoContent();
    }

    // DELETE: api/cars/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteCar(Guid id)
    {
        var car = await _context.Cars.FindAsync(id);
        if (car == null) return NotFound();

        _context.Cars.Remove(car);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
