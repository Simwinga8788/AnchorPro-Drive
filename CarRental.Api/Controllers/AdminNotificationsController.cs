using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;

namespace CarRental.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AdminNotificationsController : ControllerBase
{
    private readonly AppDbContext _context;

    public AdminNotificationsController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/adminnotifications
    [HttpGet]
    public async Task<IActionResult> GetNotifications()
    {
        var notifications = await _context.AdminNotifications
            .OrderByDescending(n => n.CreatedAt)
            .Take(50)
            .ToListAsync();
        return Ok(notifications);
    }

    // GET: api/adminnotifications/unread-count
    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        var count = await _context.AdminNotifications.CountAsync(n => !n.IsRead);
        return Ok(new { count });
    }

    // PUT: api/adminnotifications/mark-read
    [HttpPut("mark-read")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var unread = await _context.AdminNotifications.Where(n => !n.IsRead).ToListAsync();
        foreach (var notification in unread)
        {
            notification.IsRead = true;
        }
        await _context.SaveChangesAsync();
        return Ok(new { message = "Marked all as read" });
    }

    // PUT: api/adminnotifications/{id}/mark-read
    [HttpPut("{id}/mark-read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var notification = await _context.AdminNotifications.FindAsync(id);
        if (notification == null) return NotFound();

        notification.IsRead = true;
        await _context.SaveChangesAsync();
        return Ok(notification);
    }
}
