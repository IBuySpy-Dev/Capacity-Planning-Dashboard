# Tracing and Structured Logging

## W3C Trace Context

**Standard header:** `traceparent: "<version>-<trace_id>-<span_id>-<trace_flags>"`

```yaml
Example:
  traceparent: "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"

Components:
  version:     00 (current)
  trace_id:    4bf92f3577b34da6a3ce929d0e0e4736 (128-bit hex)
  span_id:     00f067aa0ba902b7 (64-bit hex)
  trace_flags: 01 (sampled) | 00 (not sampled)
```

### Implementation (Python + Flask + OTEL)

```python
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# Auto-instrument Flask and outbound HTTP
FlaskInstrumentor().instrument()
RequestsInstrumentor().instrument()

# Propagation is automatic:
# 1. Flask extracts traceparent from inbound request
# 2. requests.get() injects traceparent into outbound request
# 3. Downstream service receives the same trace_id
```

### Requirements

- **Inbound:** Extract `traceparent` / `tracestate` from request headers.
- **Outbound:** Inject trace context into all downstream service calls.
- **Logging:** Include `trace_id` and `span_id` in every log line.
- **Metrics:** Tag metrics with `trace_id` when relevant.
- **Sampling:** Respect `trace_flags` — never override to sample everything in prod.

## Structured Log Schema

All logs must be structured JSON. Required fields:

```json
{
  "timestamp": "2024-05-03T14:22:31.234567Z",
  "level": "INFO",
  "logger": "auth.service",
  "message": "User authentication successful",

  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "request_id": "req-12345",

  "context": {
    "service": "auth-service",
    "environment": "production",
    "version": "1.2.3",
    "instance_id": "pod-abc123"
  },

  "user": {
    "id": "usr_12345",
    "email": "redacted"
  },

  "http": {
    "method": "POST",
    "path": "/api/auth/login",
    "status_code": 200,
    "duration_ms": 145
  },

  "custom": {
    "auth_method": "oauth2",
    "provider": "google",
    "ip_address": "203.0.113.42"
  }
}
```

## Logging Rules

**DO:**

- Include `trace_id` + `span_id` for tracing correlation
- Include `request_id` for user-centric analysis
- Sanitize PII — never log passwords, tokens, credit cards, SSNs
- Include `duration_ms` for performance analysis
- Include `error_type` + `error_message` (not full stack traces in log lines)
- Use consistent field names across all services

**DO NOT:**

- Log unstructured free text — must always be JSON
- Include stack traces in the log line (ship separately as a field)
- Log secrets: DB passwords, API keys, credentials
- Log raw request/response bodies (extract meaningful fields only)

## Anti-patterns

```python
# ✗ BAD: Unstructured, exposes sensitive data
logger.info(f"User {user_email} logged in from {ip} with password {pwd}")

# ✓ GOOD: Structured, sanitized
logger.info("authentication.success", extra={
    "trace_id": trace_id,
    "user_id": user_id,        # ID only, not email
    "ip_address": ip,
    "auth_method": auth_method,
})
```
