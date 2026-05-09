# Dashboards, Log Aggregation, and Compliance

## Dashboard Requirements

Every service must have four dashboards:

### 1. Service Overview

| Panel | Metric |
|---|---|
| Request rate | `http.request.count` per second |
| P50/P95/P99 latency | `http.request.duration` percentiles |
| Error rate | `http.request.count{status_code=~"5.."}` / total |
| Top 5 slow endpoints | ranked by P99 |
| Top 5 error endpoints | ranked by error count |

### 2. Application Dashboard

| Panel | Metric |
|---|---|
| HTTP method breakdown | `http.request.count` by method |
| Response size distribution | histogram of `http.response.size` |
| Database query performance | `database.query.duration` by table/operation |
| Cache hit ratio | `cache.hit.count` / (hit + miss) |
| External dependency latency | per-dependency P99 |

### 3. Infrastructure Dashboard

| Panel | Metric |
|---|---|
| CPU usage | `process.cpu.usage` |
| Memory usage | `process.memory.usage` |
| Disk I/O | `system.disk.read/write` bytes/sec |
| Network I/O | bytes in/out per second |
| Container restarts | `container.restart.count` |

### 4. SLO Compliance Dashboard

| Panel | Value |
|---|---|
| SLO target | 99.9% |
| Current compliance | live percentage |
| Error budget remaining | hours |
| Burn rate | hours of budget consumed per day |

## Correlation ID Pattern

Every request gets a `trace_id` at the edge (load balancer or API gateway). All
logs, traces, and metrics downstream must carry this same ID:

```text
User Request → Load Balancer
  trace_id = "abc123" (generated)
  ↓
Service A
  logs: { trace_id: "abc123" }
  outbound call with traceparent header
  ↓
Service B
  logs: { trace_id: "abc123" }
  ↓
Database
  query logs: { trace_id: "abc123" }

Result: One trace_id links every log, trace, and query for a single request.
```

## Log Aggregation Architecture

```text
Application (JSON stdout)
  ↓
Log Collector (Fluentd or Filebeat)
  ↓ structured parsing + field extraction
Centralized Log Store (Loki, ELK, or Datadog)
  ↓ indexed by trace_id, service, level, timestamp
Search / Query Interface
  ↓ alerts on patterns
Alert Rules (CloudWatch, Prometheus Alertmanager)
  ↓
PagerDuty / Incident Management
```

## Compliance Mappings

### SOC2 CC7.2 — System Monitoring

Demonstrate:

- Real-time dashboards showing service health at all times
- Alert rules with documented SLA response times
- Traces crossing service boundaries with correlated IDs
- Log retention ≥ 90 days with query access

### HIPAA Security Rule §164.308(a)(3)(ii)(H)

- Log all access to ePHI (electronic protected health information)
- Every log line must include: timestamp, user ID, action, resource
- **Retention: minimum 6 years**
- Sanitize: never log PHI values in traces or metrics

### PCI-DSS Requirement 10.1

- Log all access to cardholder data environments
- Log all administrative access to critical systems
- Log all failed access attempts
- **Retention: minimum 1 year, 3 months online (immediately queryable)**

## References

- [W3C Trace Context](https://www.w3.org/TR/trace-context/)
- [OpenTelemetry Best Practices](https://opentelemetry.io/docs/instrumentation/best-practices/)
- [Prometheus Metrics Naming Guide](https://prometheus.io/docs/practices/naming/)
- [ELK Stack Best Practices](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-best-practices.html)
- [Google SRE Book — Monitoring Distributed Systems](https://sre.google/books/)
