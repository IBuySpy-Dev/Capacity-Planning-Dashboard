# HA & Resilience Patterns

Core patterns for building highly available, fault-tolerant systems.

## Multi-Region Active-Active

```terraform
# Primary database with Multi-AZ
resource "aws_db_instance" "primary" {
  provider                = aws.primary
  engine                  = "postgres"
  instance_class          = "db.r6i.xlarge"
  multi_az                = true
  backup_retention_period = 30
  storage_encrypted       = true
  publicly_accessible     = false
}

# Secondary read replica
resource "aws_db_instance" "secondary" {
  provider            = aws.secondary
  replicate_source_db = aws_db_instance.primary.identifier
  skip_final_snapshot = false
}

# Route 53 health check + failover routing
resource "aws_route53_health_check" "primary" {
  ip_address        = aws_db_instance.primary.address
  port              = 5432
  type              = "TCP"
  failure_threshold = 2
  request_interval  = 10
}
```

## Circuit Breaker (Go)

```go
type CircuitBreaker struct {
    mu               sync.RWMutex
    state            CircuitState  // Closed | Open | HalfOpen
    failureCount     int
    failureThreshold int
    timeout          time.Duration
    lastFailureTime  time.Time
}

func (cb *CircuitBreaker) Execute(fn func() error) error {
    cb.mu.Lock(); defer cb.mu.Unlock()
    switch cb.state {
    case StateClosed:   return cb.executeClosed(fn)
    case StateOpen:     return cb.executeOpen(fn)
    case StateHalfOpen: return cb.executeHalfOpen(fn)
    }
    return nil
}
```

States: `Closed` → `Open` (on threshold failures) → `HalfOpen` (after timeout) → `Closed` (on recovery).

## Retry with Exponential Backoff + Jitter

```python
def retry_with_backoff(config: RetryConfig, fn, *args, **kwargs):
    for attempt in range(config.max_attempts):
        try:
            return fn(*args, **kwargs)
        except Exception:
            if attempt < config.max_attempts - 1:
                delay = min(config.initial_delay * (2 ** attempt), config.max_delay)
                jitter = delay * (0.5 + random.random())
                time.sleep(jitter)
            else:
                raise
```

## Bulkhead Pattern

```python
class Bulkhead:
    def __init__(self, name: str, max_threads: int):
        self.executor = ThreadPoolExecutor(max_workers=max_threads)

    def submit(self, fn, *args, **kwargs):
        return self.executor.submit(fn, *args, **kwargs)

payment_bulkhead = Bulkhead("payment", max_threads=20)
cache_bulkhead   = Bulkhead("cache",   max_threads=50)
```

Separate thread pools prevent one failing dependency from exhausting global capacity.

## Error Budget Tracking

```python
class ErrorBudget:
    def __init__(self, slo_target: float, window_days: int):
        self.slo_target = slo_target
        self.window_days = window_days

    @property
    def total_budget_seconds(self) -> float:
        return self.window_days * 86400 * (1 - self.slo_target)

    @property
    def burn_rate(self) -> float:
        elapsed = (datetime.now() - self.incidents[0]['start']).days or 1
        return self.consumed_seconds / elapsed / (self.total_budget_seconds / self.window_days)

    def can_deploy(self) -> bool:
        return self.burn_rate <= 3.0
```

Block deployments when burn rate > 3× to protect the remaining error budget.
