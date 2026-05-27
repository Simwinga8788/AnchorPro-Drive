using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;

namespace CarRental.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DamagesController : ControllerBase
{
    private readonly AppDbContext _context;

    public DamagesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetDamages()
    {
        var damages = await _context.Damages
            .Include(d => d.Car)
            .Include(d => d.Booking)
            .Include(d => d.ReportedByProfile)
            .ToListAsync();
        return Ok(damages);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetDamage(Guid id)
    {
        var damage = await _context.Damages
            .Include(d => d.Car)
            .Include(d => d.Booking)
            .Include(d => d.ReportedByProfile)
            .FirstOrDefaultAsync(d => d.Id == id);
            
        if (damage == null) return NotFound();
        return Ok(damage);
    }

    [HttpPost]
    public async Task<IActionResult> CreateDamage([FromBody] Damage damage)
    {
        _context.Damages.Add(damage);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetDamage), new { id = damage.Id }, damage);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateDamage(Guid id, [FromBody] Damage updatedDamage)
    {
        if (id != updatedDamage.Id) return BadRequest("ID mismatch");

        _context.Entry(updatedDamage).State = EntityState.Modified;
        
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _context.Damages.AnyAsync(d => d.Id == id)) return NotFound();
            throw;
        }

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteDamage(Guid id)
    {
        var damage = await _context.Damages.FindAsync(id);
        if (damage == null) return NotFound();

        _context.Damages.Remove(damage);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
