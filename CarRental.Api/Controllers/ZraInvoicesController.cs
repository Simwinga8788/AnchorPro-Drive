using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;

namespace CarRental.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ZraInvoicesController : ControllerBase
{
    private readonly AppDbContext _context;

    public ZraInvoicesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetInvoices()
    {
        var invoices = await _context.ZraInvoices
            .Include(z => z.Booking)
            .ToListAsync();
        return Ok(invoices);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetInvoice(Guid id)
    {
        var invoice = await _context.ZraInvoices
            .Include(z => z.Booking)
            .FirstOrDefaultAsync(z => z.Id == id);
            
        if (invoice == null) return NotFound();
        return Ok(invoice);
    }

    [HttpPost]
    public async Task<IActionResult> CreateInvoice([FromBody] ZraInvoice invoice)
    {
        _context.ZraInvoices.Add(invoice);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetInvoice), new { id = invoice.Id }, invoice);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateInvoice(Guid id, [FromBody] ZraInvoice updatedInvoice)
    {
        if (id != updatedInvoice.Id) return BadRequest("ID mismatch");

        _context.Entry(updatedInvoice).State = EntityState.Modified;
        
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _context.ZraInvoices.AnyAsync(z => z.Id == id)) return NotFound();
            throw;
        }

        return NoContent();
    }
}
