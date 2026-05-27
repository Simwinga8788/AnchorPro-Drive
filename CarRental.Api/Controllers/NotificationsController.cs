using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;

namespace CarRental.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class NotificationsController : ControllerBase
{
    private readonly AppDbContext _context;

    public NotificationsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetNotifications()
    {
        var notifications = await _context.Notifications
            .Include(n => n.Profile)
            .ToListAsync();
        return Ok(notifications);
    }

    [HttpPost]
    public async Task<IActionResult> CreateNotification([FromBody] Notification notification)
    {
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
        return Ok(notification);
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var notification = await _context.Notifications.FindAsync(id);
        if (notification == null) return NotFound();

        notification.IsRead = true;
        await _context.SaveChangesAsync();
        return NoContent();
    }
}
