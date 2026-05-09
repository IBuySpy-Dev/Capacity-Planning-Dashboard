---
name: identity-migration
title: Identity Migration to ASP.NET Core & Entra ID
description: Migrate legacy authentication to ASP.NET Core Identity with Entra ID integration, claims-based authentication, and role/password management
compatibility: ["agent:backend-dev"]
metadata:
  domain: identity
  maturity: production
  audience: [backend-engineer, devops-engineer, architect]
allowed-tools: [bash, powershell, docker]
---

# Identity Migration Skill

Migrate legacy ASP.NET Membership systems to ASP.NET Core Identity with Azure Entra ID
integration. Covers user model conversion, password hash compatibility, claims-based auth,
role migration, OIDC setup, and hybrid local + Entra ID scenarios.

## Quick Start

1. Implement `LegacyPasswordHasher` for backward-compatible password verification.
2. Run the database migration SQL to copy users and roles to Identity tables.
3. Configure OIDC in `ConfigureServices` pointing to `AzureAd` configuration section.
4. Apply claims transformation to convert legacy roles to claims.
5. Follow the migration checklist in `references/testing-checklist.md`.

## Reference Files

| File | Contents |
|------|----------|
| [`references/migration-patterns.md`](references/migration-patterns.md) | User model migration, DB steps, password hash compatibility, claims, role migration |
| [`references/azure-integration.md`](references/azure-integration.md) | Entra ID OIDC, Azure AD config, hybrid auth, OAuth2 providers, token refresh |
| [`references/testing-checklist.md`](references/testing-checklist.md) | Migration checklist, test scenarios, rollback plan |

## Key Patterns

- **LegacyPasswordHasher** — falls back to PBKDF2 verification; upgrades hash on login
- **IClaimsTransformation** — converts Identity roles to claims on each request
- **Hybrid auth** — `AddCookie` + `AddMicrosoftIdentityWebApp` for local + Entra ID
- **Never store secrets** in `appsettings.json` — use Key Vault or environment variables

## References

- Microsoft Identity Platform Documentation
- ASP.NET Core Identity Documentation
- Azure Entra ID Integration Guide (`docs/integrations/AZURE_AD_INTEGRATION_GUIDE.md`)
