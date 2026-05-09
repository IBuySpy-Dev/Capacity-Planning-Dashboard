# Authentication Flow

The dashboard uses the **Microsoft Entra ID authorization-code flow** (MSAL) for browser-based users. Administrative and internal API calls use a shared HMAC secret or managed-identity credentials.

---

## Browser auth (OIDC authorization-code flow)

```mermaid
sequenceDiagram
    autonumber
    participant B as Browser
    participant API as App Service
    participant Entra as Microsoft Entra ID

    B->>API: GET /some-protected-page
    API->>API: No session cookie → start auth
    API->>B: 302 → /auth/signin?redirect=/some-protected-page

    B->>API: GET /auth/signin
    API->>B: 302 → Entra authorize endpoint\n(client_id, redirect_uri, scope=openid profile email)

    B->>Entra: GET /authorize (user follows redirect)
    Entra->>B: Render login page (MFA if required)

    B->>Entra: Submit credentials
    Entra->>B: 302 → /auth/callback?code=XXXX&state=YYY

    B->>API: GET /auth/callback?code=XXXX
    API->>Entra: POST /token (code + client_secret)
    Entra-->>API: { access_token, id_token, refresh_token }

    API->>API: Validate id_token\nExtract oid, groups, roles\nCreate express-session

    API->>B: 302 → /some-protected-page\n(Set-Cookie: connect.sid)

    B->>API: GET /some-protected-page\n(Cookie: connect.sid)
    API->>API: Session lookup → authorised
    API-->>B: 200 — page content
```

---

## Authorisation levels

Once authenticated, routes are gated by three roles derived from Entra group membership:

| Level | Middleware | Who |
|---|---|---|
| **Public** | none | Anyone, including unauthenticated callers |
| **User** | `requireAuth` | Any authenticated Entra user in the tenant |
| **Admin** | `requireAdmin` | Members of the configured admin Entra group |
| **Internal** | `INGEST_API_KEY` HMAC | Worker-to-API calls with shared secret header |

Routes are documented in [API Reference → Auth levels](../reference/api.md#auth-levels).

---

## Session storage

Sessions are stored in **Azure SQL** (`AppSessions` table) using `connect-mssql-v2`.

- Session lifetime: 8 hours (configurable via `SESSION_MAX_AGE_MS`)
- Secret: stored in Key Vault as `capdash-session-secret`; injected as Key Vault reference in App Settings
- Cookie: `httpOnly`, `secure`, `sameSite: lax`

---

## Token handling

| Token | Usage | Stored where |
|---|---|---|
| `id_token` | User identity, group claims | Discarded after session creation |
| `access_token` | ARM calls on behalf of user (not used — MI preferred) | Not stored |
| `refresh_token` | Kept for silent renewal | Encrypted in session row |

!!! warning
    Access tokens are never written to `localStorage` or `sessionStorage`. Session state lives server-side in SQL.
