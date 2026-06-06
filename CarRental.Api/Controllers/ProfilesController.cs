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

    [HttpGet("whoami")]
    public IActionResult WhoAmI()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var isAdmin = User.IsInRole("Admin");
        var claims = User.Claims.Select(c => new { c.Type, c.Value }).ToList();
        return Ok(new { userId, isAdmin, claims });
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetMe()
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !Guid.TryParse(userIdString, out var userId))
            return Unauthorized();

        var profile = await _context.Profiles.FindAsync(userId);
        if (profile == null)
        {
            // Auto-create a minimal profile for new Supabase users on first login
            var email = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
            profile = new Profile
            {
                Id = userId,
                Email = email,
                FirstName = "",
                LastName = "",
                CreatedAt = DateTime.UtcNow,
                IsAdmin = false,
                IsSuspended = false
            };
            _context.Profiles.Add(profile);
            await _context.SaveChangesAsync();
        }

        return Ok(profile);
    }

    [HttpGet]
    [Authorize(Policy = "AdminOnly")]
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
    [AllowAnonymous]
    public async Task<IActionResult> CreateProfile([FromBody] Profile profile)
    {
        // Idempotent: if profile already exists, just update the empty fields
        var existing = await _context.Profiles.FindAsync(profile.Id);
        if (existing != null)
        {
            if (!string.IsNullOrEmpty(profile.FirstName)) existing.FirstName = profile.FirstName;
            if (!string.IsNullOrEmpty(profile.LastName)) existing.LastName = profile.LastName;
            if (!string.IsNullOrEmpty(profile.PhoneNumber)) existing.PhoneNumber = profile.PhoneNumber;
            if (!string.IsNullOrEmpty(profile.Email)) existing.Email = profile.Email;
            if (!string.IsNullOrEmpty(profile.DriverLicenseNumber)) existing.DriverLicenseNumber = profile.DriverLicenseNumber;
            if (profile.DateOfBirth.HasValue) existing.DateOfBirth = profile.DateOfBirth;
            await _context.SaveChangesAsync();
            return Ok(existing);
        }
        _context.Profiles.Add(profile);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetProfile), new { id = profile.Id }, profile);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateProfile(Guid id, [FromBody] Profile updatedProfile)
    {
        if (id != updatedProfile.Id) return BadRequest("ID mismatch");

        var profile = await _context.Profiles.FindAsync(id);
        if (profile == null) return NotFound();

        profile.FirstName = updatedProfile.FirstName;
        profile.LastName = updatedProfile.LastName;
        profile.PhoneNumber = updatedProfile.PhoneNumber;
        profile.DriverLicenseNumber = updatedProfile.DriverLicenseNumber;
        profile.DriverLicenseExpiry = updatedProfile.DriverLicenseExpiry;
        profile.Address = updatedProfile.Address;
        profile.DateOfBirth = updatedProfile.DateOfBirth;
        profile.AvatarUrl = updatedProfile.AvatarUrl;
        
        if (!string.IsNullOrEmpty(updatedProfile.Email))
        {
            profile.Email = updatedProfile.Email;
        }

        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPut("{id}/toggle-admin")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> ToggleAdmin(Guid id)
    {
        var profile = await _context.Profiles.FindAsync(id);
        if (profile == null) return NotFound();

        profile.IsAdmin = !profile.IsAdmin;
        await _context.SaveChangesAsync();
        return Ok(profile);
    }

    [HttpPut("{id}/toggle-suspend")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> ToggleSuspend(Guid id)
    {
        var profile = await _context.Profiles.FindAsync(id);
        if (profile == null) return NotFound();

        profile.IsSuspended = !profile.IsSuspended;
        await _context.SaveChangesAsync();
        return Ok(profile);
    }

    [HttpDelete("{id}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> DeleteProfile(Guid id)
    {
        var profile = await _context.Profiles.FindAsync(id);
        if (profile == null) return NotFound();

        // Find all bookings for this customer
        var bookings = await _context.Bookings.Where(b => b.CustomerId == id).ToListAsync();
        
        // Find and delete all payments for those bookings
        var bookingIds = bookings.Select(b => b.Id).ToList();
        var payments = await _context.Payments.Where(p => bookingIds.Contains(p.BookingId)).ToListAsync();
        _context.Payments.RemoveRange(payments);

        // Delete the bookings
        _context.Bookings.RemoveRange(bookings);

        // Finally delete the profile
        _context.Profiles.Remove(profile);
        
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException ex)
        {
            return BadRequest($"Could not delete user due to database constraints: {ex.InnerException?.Message ?? ex.Message}");
        }

        return NoContent();
    }
}
