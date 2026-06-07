using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;

namespace CarRental.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class LocationsController : ControllerBase
{
    private readonly AppDbContext _context;

    public LocationsController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/locations
    [HttpGet]
    public async Task<IActionResult> GetLocations()
    {
        var locations = await _context.Locations.ToListAsync();
        if (locations.Count == 0)
        {
            var defaultLocation = new Location
            {
                Id = Guid.NewGuid(),
                Name = "Lusaka — Cairo Road Branch",
                Address = "Cairo Road, Lusaka, Zambia",
                ContactPhone = "+260 211 123456",
                CreatedAt = DateTime.UtcNow
            };
            _context.Locations.Add(defaultLocation);
            await _context.SaveChangesAsync();
            locations.Add(defaultLocation);
        }
        Response.Headers["Cache-Control"] = "public, max-age=300";
        return Ok(locations);
    }

    // GET: api/locations/{id}
    [HttpGet("{id}")]
    public async Task<IActionResult> GetLocation(Guid id)
    {
        var location = await _context.Locations.FindAsync(id);
        if (location == null) return NotFound();
        return Ok(location);
    }

    // POST: api/locations
    [HttpPost]
    public async Task<IActionResult> CreateLocation([FromBody] Location location)
    {
        _context.Locations.Add(location);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetLocation), new { id = location.Id }, location);
    }

    // PUT: api/locations/{id}
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateLocation(Guid id, [FromBody] Location updatedLocation)
    {
        if (id != updatedLocation.Id) return BadRequest("ID mismatch");

        _context.Entry(updatedLocation).State = EntityState.Modified;
        
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _context.Locations.AnyAsync(l => l.Id == id)) return NotFound();
            throw;
        }

        return NoContent();
    }

    // DELETE: api/locations/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteLocation(Guid id)
    {
        var location = await _context.Locations.FindAsync(id);
        if (location == null) return NotFound();

        _context.Locations.Remove(location);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
