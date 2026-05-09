# HA & Resilience Testing

Chaos engineering, load testing, and SLO validation patterns.

## Chaos Testing Script

```bash
#!/bin/bash
set -e
NAMESPACE="production"
LATENCY="500ms"

echo "Baseline health check..."
curl -sf https://api.example.com/health

echo "Injecting ${LATENCY} network latency..."
# Use tc, toxiproxy, or Chaos Mesh network policy

echo "Monitoring for 60s..."
sleep 60

echo "Removing latency..."
# Remove injection

echo "Verifying recovery..."
curl -sf https://api.example.com/health
echo "Chaos test complete"
```

## Chaos Test Scenarios

| Scenario | Injection | Recovery Criterion |
|----------|-----------|-------------------|
| Network latency | 500ms latency on db port | p99 < 1s within 30s |
| Pod failure | Kill 1 of 3 replicas | All replicas healthy within 60s |
| Region failover | Block primary region traffic | DNS failover < 5 min |
| Dependency down | Block external API calls | Circuit breaker opens; fallback returns |
| Memory pressure | Limit pod memory to 50% | OOM kill triggers restart, no data loss |

## Load Testing

```yaml
# k6 load test
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },   // ramp up
    { duration: '5m', target: 100 },   // steady state
    { duration: '2m', target: 0 },     // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],   // 95th percentile < 500ms
    http_req_failed: ['rate<0.01'],     // < 1% errors
  },
};

export default function () {
  const res = http.get('https://api.example.com/health');
  check(res, { 'status 200': (r) => r.status === 200 });
  sleep(1);
}
```

## SLO Validation Checklist

- [ ] Availability SLO defined (e.g., 99.9% = 43.8 min/month downtime)
- [ ] Error budget calculated and tracked
- [ ] Circuit breaker tested: opens on threshold failures, recovers after timeout
- [ ] Retry logic tested: correct backoff, jitter, max attempts
- [ ] Bulkhead tested: one pool exhaustion does not affect other pools
- [ ] Multi-region failover tested and documented RTO/RPO
- [ ] Alert fires before error budget is 50% consumed
- [ ] Runbook linked to each alert

## References

- [AWS Well-Architected Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/)
- [Release It! (Michael Nygard)](https://pragprog.com/titles/mnee2/release-it-second-edition/)
- [Chaos Engineering Principles](https://principlesofchaos.org/)
