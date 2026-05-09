# Identity Migration Patterns

Core patterns for migrating ASP.NET Membership to ASP.NET Core Identity.

## User Model Migration

```csharp
// Legacy ASP.NET Membership User
public class MembershipUser
{
    public Guid UserId { get; set; }
    public string UserName { get; set; }
    public string Email { get; set; }
    public string PasswordHash { get; set; }
    public DateTime CreateDate { get; set; }
    public bool IsApproved { get; set; }
}

// ASP.NET Core Identity User (extend IdentityUser)
public class ApplicationUser : IdentityUser
{
    public DateTime CreateDate { get; set; }
    public bool IsApproved { get; set; }
}
```

## Database Migration Steps

1. Back up the legacy Membership database.
2. Create ASP.NET Core Identity schema via EF Core migrations.
3. Copy user data to new tables (adjust hash format as needed).
4. Migrate roles and user-role relationships.
5. Update connection strings and configuration.

```sql
INSERT INTO AspNetUsers (Id, UserName, Email, PasswordHash, CreatedDate, IsApproved)
SELECT CONVERT(NVARCHAR(MAX), UserId), UserName, Email,
       PasswordHash, CreateDate, IsApproved
FROM aspnet_Users WHERE UserName IS NOT NULL;
```

## Legacy Password Hash Compatibility

Implement a custom `IPasswordHasher<T>` that falls back to the legacy PBKDF2 algorithm
and upgrades the hash on successful login:

```csharp
public class LegacyPasswordHasher : PasswordHasher<ApplicationUser>
{
    public override PasswordVerificationResult VerifyHashedPassword(
        ApplicationUser user, string hash, string providedPassword)
    {
        var result = base.VerifyHashedPassword(user, hash, providedPassword);
        if (result == PasswordVerificationResult.Success) return result;

        if (VerifyLegacyHash(hash, providedPassword))
        {
            user.PasswordHash = HashPassword(user, providedPassword);
            return PasswordVerificationResult.SuccessRehashNeeded;
        }
        return PasswordVerificationResult.Failed;
    }

    private bool VerifyLegacyHash(string hash, string password)
    {
        using var pbkdf2 = new Rfc2898DeriveBytes(
            password, Encoding.UTF8.GetBytes(hash.Substring(0, 16)), iterations: 1000);
        return hash.EndsWith(Convert.ToBase64String(pbkdf2.GetBytes(20)));
    }
}
```

## Claims-Based Authorization

```csharp
public class ClaimsTransformation : IClaimsTransformation
{
    private readonly UserManager<ApplicationUser> _userManager;

    public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        var user = await _userManager.FindByNameAsync(
            principal.FindFirst(ClaimTypes.Name)?.Value);
        if (user != null)
        {
            var identity = principal.Identity as ClaimsIdentity;
            foreach (var role in await _userManager.GetRolesAsync(user))
                identity?.AddClaim(new Claim(ClaimTypes.Role, role));
        }
        return principal;
    }
}
```

## Role Migration

```csharp
public async Task MigrateRolesAsync(IEnumerable<LegacyRole> legacyRoles)
{
    foreach (var legacyRole in legacyRoles)
    {
        var role = new IdentityRole { Name = legacyRole.RoleName };
        if ((await _roleManager.CreateAsync(role)).Succeeded)
            await _roleManager.AddClaimAsync(role, new Claim("permission", legacyRole.RoleName));
    }
}
```
