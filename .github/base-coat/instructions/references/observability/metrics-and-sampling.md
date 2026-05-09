# Metrics Naming and Sampling Strategies

## Metrics Naming Format

```text
<namespace>.<component>.<metric_name>.<unit>
```

### Examples

```yaml
# HTTP metrics
http.request.count          # requests
http.request.duration       # milliseconds
http.request.size           # bytes
http.response.size          # bytes

# Database metrics
database.connection.pool.size   # connections
database.query.duration         # milliseconds
database.query.count            # queries

# Cache metrics
cache.hit.count             # operations
cache.miss.count            # operations
cache.size                  # bytes

# System metrics
process.memory.usage        # bytes
process.cpu.usage           # percent
system.disk.usage           # bytes
```

## Metric Labels

Always include labels for dimensionality:

```yaml
http.request.count:
  labels: [method, path, status_code]
  example: http.request.count{method="POST", path="/api/users", status_code="200"} = 42

database.query.duration:
  labels: [operation, table, status]
  example: database.query.duration{operation="SELECT", table="users", status="success"} = 123ms
```

### Label Rules

- Use lowercase snake_case for label names.
- Keep cardinality bounded — do not use user IDs or session IDs as labels.
- Limit labels to dimensions that will be used for aggregation or alerting.

## Sampling Strategies

### 1. Fixed Rate Sampling (Simple)

- Sample a fixed percentage of all requests (e.g., 1%).
- **Pro:** Simple to implement.
- **Con:** May miss rare but important events.

### 2. Dynamic Sampling (Recommended)

- Sample 100% of errors.
- Sample 100% of slow requests (> 1 second).
- Sample 5–10% of normal requests.
- **Result:** No signal loss on events that matter; low cost on healthy traffic.

### 3. Tail Sampling (Advanced)

- Collect all spans initially; decide post-collection whether to retain.
- **Criteria:** Error? Slow? Contains a specific attribute?
- **Pro:** Most flexible — can make decisions on full trace context.
- **Con:** Higher memory overhead during collection window.

### Implementation (Python OTEL SmartSampler)

```python
from opentelemetry.sdk.trace.sampling import Sampler, Decision
import random

class SmartSampler(Sampler):
    def should_sample(self, trace_id, parent_context, span_name, attributes):
        # Always sample errors
        if attributes.get('error'):
            return Decision.RECORD_AND_SAMPLE

        # Always sample slow requests (> 1 second)
        if attributes.get('duration_ms', 0) > 1000:
            return Decision.RECORD_AND_SAMPLE

        # Sample 5% of normal requests
        if random.random() < 0.05:
            return Decision.RECORD_AND_SAMPLE

        return Decision.DROP
```

## SLO / Error Budget

Configure SLO tracking metrics alongside service metrics:

```yaml
SLO Configuration:
  service: auth-service
  objective: 99.9%         # Availability target
  window: 30d              # Rolling window

Error Budget:
  total_minutes:    43200  # 30 days in minutes
  budget_minutes:   43.2   # 0.1% of window
  consumed_minutes: <query from monitoring>
  remaining:        budget_minutes - consumed_minutes

Burn Rate Alert: fire if burn_rate > 14.4 (budget gone in 2 hours)
```
