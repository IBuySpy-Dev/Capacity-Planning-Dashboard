# API Security Threat Model

OWASP API Security Top 10 patterns and corresponding mitigations.

## OWASP API Security Top 10 (2023)

| # | Risk | Mitigation |
|---|------|-----------|
| API1 | Broken Object Level Authorization | Validate object ownership per request |
| API2 | Broken Authentication | JWT + short expiry, rotate secrets |
| API3 | Broken Object Property Level Authorization | Filter fields on serialization |
| API4 | Unrestricted Resource Consumption | Rate limiting, pagination caps |
| API5 | Broken Function Level Authorization | RBAC on every endpoint |
| API6 | Unrestricted Access to Sensitive Business Flows | Bot detection, step-up auth |
| API7 | Server-Side Request Forgery | Allowlist outbound destinations |
| API8 | Security Misconfiguration | Lint headers, scan configs in CI |
| API9 | Improper Inventory Management | API versioning, sunset old versions |
| API10 | Unsafe Consumption of APIs | Validate all third-party responses |

## JWT Authentication

```python
def create_access_token(data: dict, expires_in: int = 3600):
    payload = {**data, 'exp': datetime.utcnow() + timedelta(seconds=expires_in)}
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")

def verify_token(credentials: HTTPAuthCredentials = Depends(security)):
    try:
        return jwt.decode(credentials.credentials, SECRET_KEY, algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        raise HTTPException(401, "Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(401, "Invalid token")
```

## RBAC

```python
def require_role(*roles):
    async def checker(token: dict = Depends(verify_token)):
        if token.get("role") not in roles:
            raise HTTPException(403, "Insufficient permissions")
        return token
    return checker

@app.delete("/admin/users/{user_id}")
async def delete_user(user_id: str, token = Depends(require_role("admin"))):
    return {"deleted": user_id}
```

## Input Validation (XSS + Injection Prevention)

```python
class CreatePostRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1, max_length=10000)

    @validator('title', 'content', pre=True)
    def sanitize_html(cls, v):
        return escape(v) if isinstance(v, str) else v
```

## SQL Injection Prevention

```python
# CORRECT: Parameterized query
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# INCORRECT: String concatenation (never do this)
# cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
```

## GraphQL Security

```python
@query.field("user")
def resolve_user(_, info, id):
    if not info.context.get("user"):
        raise GraphQLError("Unauthorized")
    if info.context["user"].get("role") != "admin" and info.context["user"]["id"] != id:
        raise GraphQLError("Forbidden")
    return info.context["user_loader"].load(id)
```

## Security Logging

```python
@app.post("/login")
async def login(credentials: LoginRequest):
    try:
        user = authenticate(credentials.username, credentials.password)
        logger.info(f"Login success: {credentials.username}")
        return {"token": create_token(user)}
    except AuthenticationError:
        logger.warning(f"Failed login: {credentials.username}")
        raise HTTPException(401, "Invalid credentials")
```
