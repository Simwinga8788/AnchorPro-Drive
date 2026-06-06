using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using CarRental.Api.Models;

namespace CarRental.Api.Services;

public class RoleClaimsTransformation : IClaimsTransformation
{
    private readonly IServiceProvider _serviceProvider;

    public RoleClaimsTransformation(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        // Check if the user is authenticated and we don't already have a role claim
        if (!principal.Identity?.IsAuthenticated == true || principal.HasClaim(c => c.Type == ClaimTypes.Role && c.Value == "Admin"))
        {
            return principal;
        }

        var userIdString = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !Guid.TryParse(userIdString, out var userId))
        {
            return principal;
        }

        // We must create a scope since this is a singleton or scoped per request and we need DbContext
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        try
        {
            var profile = await context.Profiles.FindAsync(userId);
            if (profile != null && profile.IsAdmin && principal.Identity != null)
            {
                var identity = (ClaimsIdentity)principal.Identity;
                identity.AddClaim(new Claim(ClaimTypes.Role, "Admin"));
            }
        }
        catch (Exception ex)
        {
            // Log but don't crash — user simply won't get Admin role
            Console.Error.WriteLine($"[RoleClaimsTransformation] Error looking up profile {userId}: {ex.Message}");
        }

        return principal;
    }
}
