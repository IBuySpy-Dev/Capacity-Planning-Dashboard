# Penetration Testing — Reporting & Remediation

## Finding Template

```yaml
Finding:
  ID: "PEN-2026-001"
  Title: "Broken Object Level Authorization in User Profile API"
  Severity: "HIGH"
  CVSS_v3.1: "7.5 (AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N)"

  Description: |
    The /api/users/{id}/profile endpoint does not validate that the
    authenticated user is authorized to access the requested user ID.
    Any authenticated user can read any other user's profile by
    enumerating the ID parameter.

  Reproduction_Steps:
    1. Authenticate as User A (token: eyJ...)
    2. GET /api/users/1/profile → 200, returns own data
    3. GET /api/users/42/profile → 200, returns another user's data
    4. Compare emails to confirm cross-user data leakage

  Impact: |
    An attacker can enumerate and read all user profiles, exposing:
    - Email addresses and phone numbers
    - Payment method summaries
    - Activity and purchase history

  Remediation: |
    Add an authorization check before returning profile data:

    ```python
    @app.route("/api/users/<int:user_id>/profile")
    def get_user_profile(user_id):
        current_user = get_current_user()
        if current_user.id != user_id and not current_user.is_admin:
            abort(403)
        return jsonify(get_profile(user_id))
    ```

  Evidence:
    Request:  GET /api/users/42/profile
    Response: {"id": 42, "email": "alice@example.com", ...}

  References:
    - OWASP A01:2021 Broken Access Control
    - CWE-639: Authorization Bypass Through User-Controlled Key
    - https://owasp.org/API1_2023-Broken_Object_Level_Authorization/
```

## CVSS Scoring Quick Reference

| Metric | Critical (9.0–10.0) | High (7.0–8.9) | Medium (4.0–6.9) |
|---|---|---|---|
| Attack Vector | Network | Network | Network |
| Privileges Required | None | Low | Low |
| User Interaction | None | None | Required |
| Confidentiality | High | High | Low/Medium |

## Severity Classification

| Severity | CVSS Range | Examples | SLA |
|---|---|---|---|
| Critical | 9.0–10.0 | RCE, credential dump, auth bypass | 24h |
| High | 7.0–8.9 | BOLA, stored XSS, SQLi, SSRF | 3 days |
| Medium | 4.0–6.9 | Reflected XSS, info disclosure | 30 days |
| Low | 0.1–3.9 | Missing security headers, verbose errors | 90 days |
| Info | 0.0 | Best-practice gaps | Next sprint |

## Remediation Payloads

### SQL Injection Fix

```python
# ❌ Vulnerable: string interpolation
query = f"SELECT * FROM users WHERE username = '{username}'"

# ✅ Fix: parameterized query
query = "SELECT * FROM users WHERE username = %s"
cursor.execute(query, (username,))
```

### XSS Prevention

```html
<!-- ❌ Vulnerable -->
<div>{{ user_input | safe }}</div>

<!-- ✅ Fix: auto-escape -->
<div>{{ user_input }}</div>
```

```python
# Server-side: escape before rendering
from markupsafe import escape
safe_input = escape(user_input)
```

### Path Traversal Fix

```python
import os

# ❌ Vulnerable
filename = request.args.get('file')
with open(f"/data/{filename}") as f:
    return f.read()

# ✅ Fix: resolve and validate path
base_dir = "/data"
filename = request.args.get('file', '')
safe_path = os.path.realpath(os.path.join(base_dir, filename))
if not safe_path.startswith(base_dir):
    abort(400)  # Path traversal detected
with open(safe_path) as f:
    return f.read()
```

## Retest Checklist

- [ ] Original reproduction steps no longer produce the vulnerability
- [ ] Boundary cases tested (e.g., ID = -1, ID = 0, very large ID)
- [ ] Authorization check appears in code review / diff
- [ ] Unit or integration test added to prevent regression
- [ ] Finding marked as Remediated in tracking system with retest date
