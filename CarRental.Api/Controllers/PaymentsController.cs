using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;

namespace CarRental.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PaymentsController : ControllerBase
{
    private readonly AppDbContext _context;

    public PaymentsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetPayments()
    {
        var payments = await _context.Payments
            .Include(p => p.Booking)
            .Include(p => p.Profile)
            .ToListAsync();
        return Ok(payments);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetPayment(Guid id)
    {
        var payment = await _context.Payments
            .Include(p => p.Booking)
            .Include(p => p.Profile)
            .FirstOrDefaultAsync(p => p.Id == id);
            
        if (payment == null) return NotFound();
        return Ok(payment);
    }

    [HttpPost]
    public async Task<IActionResult> CreatePayment([FromBody] Payment payment)
    {
        _context.Payments.Add(payment);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetPayment), new { id = payment.Id }, payment);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdatePayment(Guid id, [FromBody] Payment updatedPayment)
    {
        if (id != updatedPayment.Id) return BadRequest("ID mismatch");

        _context.Entry(updatedPayment).State = EntityState.Modified;
        
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _context.Payments.AnyAsync(p => p.Id == id)) return NotFound();
            throw;
        }

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeletePayment(Guid id)
    {
        var payment = await _context.Payments.FindAsync(id);
        if (payment == null) return NotFound();

        _context.Payments.Remove(payment);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
