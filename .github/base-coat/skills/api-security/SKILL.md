---
name: api-security
title: OWASP API Security Top 10 Patterns
description: API authentication, authorization, input validation, rate limiting, and protection patterns
compatibility: ["agent:api-security"]
metadata:
  domain: security
  maturity: production
  audience: [api-developer, security-engineer, architect]
allowed-tools: [python, javascript, bash, docker]
---

# API Security Skill

Production patterns for securing REST and GraphQL APIs against OWASP API Security Top 10.

## Reference Files

| File | Contents |
|------|----------|
| [`references/threat-model.md`](references/threat-model.md) | OWASP Top 10 table, JWT auth, RBAC, input validation/XSS, SQL injection prevention, GraphQL security, security logging |
| [`references/controls.md`](references/controls.md) | Rate limiting, API key verification, CORS configuration, security headers, controls checklist |

## Core Controls (Quick Reference)

| Control | Pattern |
|---------|---------|
| Authentication | JWT with short expiry (≤1 hr); rotate refresh tokens |
| Authorization | RBAC via `require_role()` on every endpoint |
| Input validation | Pydantic/Zod schema + HTML escape on user content |
| Injection prevention | Parameterized queries only — no string concatenation |
| Rate limiting | `slowapi` — 5/min on auth, 100/hr on search |
| CORS | Explicit `allow_origins` list — never `["*"]` in production |
| Transport | HTTPS + security headers (HSTS, CSP, X-Frame-Options) |

## Security Logging

Log all auth events (success + failure) with username, IP, and timestamp.
Never log passwords or tokens.

## References

- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [OWASP Top 10 2021](https://owasp.org/Top10/)
