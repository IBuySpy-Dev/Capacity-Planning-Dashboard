# API Security Controls

Rate limiting, API keys, CORS, and transport security patterns.

## Rate Limiting

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/auth/login")
@limiter.limit("5/minute")
async def login(request: Request, credentials: LoginRequest):
    return {"token": "..."}

@app.get("/api/search")
@limiter.limit("100/hour")
async def search(q: str):
    return {"results": []}
```

## API Key Verification

```python
from fastapi.security import APIKeyHeader

api_key_header = APIKeyHeader(name="X-API-Key")
VALID_KEYS = {"key-abc123", "key-def456"}

async def verify_api_key(api_key: str = Depends(api_key_header)):
    if api_key not in VALID_KEYS:
        raise HTTPException(403, "Invalid API key")
    return api_key
```

## CORS Configuration

```python
# CORRECT: Restrict to trusted origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://trusted-domain.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)

# INCORRECT: Allow all origins (never use in production)
# allow_origins=["*"]
```

## Security Headers (HTTPS Middleware)

```python
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    return response
```

## Security Controls Checklist

- [ ] JWT tokens expire in ≤ 1 hour; refresh tokens rotated on use
- [ ] RBAC enforced on every authenticated endpoint
- [ ] Input validation via schema (Pydantic, Zod, etc.) on all request bodies
- [ ] Parameterized queries used everywhere (no string concatenation in SQL)
- [ ] Rate limiting on auth endpoints (≤ 5 attempts/minute)
- [ ] CORS restricted to known origins (no `allow_origins=["*"]` in production)
- [ ] Security headers added to all responses
- [ ] GraphQL depth/complexity limits enabled
- [ ] Failed auth attempts logged with IP and username (not password)

## References

- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [REST API Security Best Practices](https://restfulapi.net/security-essentials/)
