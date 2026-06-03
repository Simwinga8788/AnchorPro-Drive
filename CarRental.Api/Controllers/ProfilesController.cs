using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;

using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace CarRental.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ProfilesController : ControllerBase
{
    private readonly AppDbContext _context;

    public ProfilesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetMe()
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !Guid.TryParse(userIdString, out var userId))
            return Unauthorized();

        var profile = await _context.Profiles.FindAsync(userId);
        if (profile == null) return NotFound();

        return Ok(profile);
    }

    [HttpGet]
    public async Task<IActionResult> GetProfiles()
    {
        var profiles = await _context.Profiles.ToListAsync();
        return Ok(profiles);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetProfile(Guid id)
    {
        var profile = await _context.Profiles.FindAsync(id);
        if (profile == null) return NotFound();
        return Ok(profile);
    }

    [HttpPost]
    public async Task<IActionResult> CreateProfile([FromBody] Profile profile)
    {
        _context.Profiles.Add(profile);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetProfile), new { id = profile.Id }, profile);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateProfile(Guid id, [FromBody] Profile updatedProfile)
    {
        if (id != updatedProfile.Id) return BadRequest("ID mismatch");

        _context.Entry(updatedProfile).State = EntityState.Modified;
        
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _context.Profiles.AnyAsync(p => p.Id == id)) return NotFound();
            throw;
        }

        return NoContent();
    }
}
