# Identity Migration Testing & Checklist

## Migration Checklist

- [ ] Back up legacy Membership database
- [ ] Create ASP.NET Core Identity schema (EF Core migration)
- [ ] Implement and test `LegacyPasswordHasher` (verify + rehash flow)
- [ ] Migrate user accounts; validate data integrity (row counts, email uniqueness)
- [ ] Migrate roles and user-role assignments
- [ ] Implement claims-based authorization policies
- [ ] Configure Entra ID (Azure AD) OIDC integration
- [ ] Configure hybrid authentication (local + Entra ID)
- [ ] Configure OAuth2 providers (Microsoft, Google, etc.)
- [ ] Test login flows for all authentication methods
- [ ] Test password reset flows
- [ ] Verify MFA enforcement for admin roles
- [ ] Monitor legacy authentication deprecation in logs
- [ ] Communicate authentication changes to end users

## Test Scenarios

### Password Migration

| Scenario | Expected Result |
|----------|----------------|
| Legacy user logs in with correct password | `SuccessRehashNeeded` → hash upgraded |
| Legacy user logs in with wrong password | `Failed` |
| Migrated user logs in with new hash | `Success` |

### Claims & Authorization

```csharp
[Fact]
public async Task AdminPolicy_RequiresAdminRole()
{
    var user = new ClaimsPrincipal(new ClaimsIdentity(
        new[] { new Claim(ClaimTypes.Role, "user") }));
    var result = await _authorizationService.AuthorizeAsync(user, null, "AdminOnly");
    Assert.False(result.Succeeded);
}
```

### Entra ID Integration

- Sign in via Entra ID returns valid `ClaimsPrincipal` with expected claims.
- Token refresh succeeds and returns a new access token.
- Hybrid auth correctly routes local vs. Entra ID accounts.

## Rollback Plan

1. Keep legacy Membership tables intact during migration (do not drop).
2. Feature-flag the new Identity stack; roll back by disabling the flag.
3. Validate user counts match before dropping legacy tables.
