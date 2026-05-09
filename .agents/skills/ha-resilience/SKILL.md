---
name: ha-resilience
title: High-Availability & Resilience Design Patterns
description: Multi-AZ/region architectures, circuit breakers, retries, chaos testing, and SRE practices
compatibility: ["agent:ha-architect"]
metadata:
  domain: infrastructure
  maturity: production
  audience: [architect, sre, devops-engineer]
allowed-tools: [terraform, kubernetes, python, bash, docker]
---

# HA & Resilience Skill

Production patterns for designing and testing highly available, fault-tolerant systems.

## Reference Files

| File | Contents |
|------|----------|
| [`references/patterns.md`](references/patterns.md) | Multi-region active-active (Terraform), circuit breaker (Go), retry + jitter (Python), bulkhead pattern, error budget tracking |
| [`references/testing.md`](references/testing.md) | Chaos test script, test scenarios, k6 load testing, SLO validation checklist |

## Core Patterns

| Pattern | Use Case | Key Rule |
|---------|---------|---------|
| Circuit Breaker | Prevent cascade failures | Opens after N failures; half-open after timeout |
| Retry + Jitter | Transient faults | Exponential backoff + random jitter; cap at max_delay |
| Bulkhead | Dependency isolation | Separate thread pools per downstream dependency |
| Multi-region | Regional outages | Route53 health check + failover; read replica in secondary |
| Error Budget | Deployment safety | Block deployments when burn rate > 3× |

## SLO Quick Reference

- 99.9% availability = 43.8 min/month downtime budget
- 99.95% = 21.9 min/month
- 99.99% = 4.4 min/month

## References

- [AWS Well-Architected Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/)
- [Chaos Engineering Principles](https://principlesofchaos.org/)
- [Release It! (Nygard)](https://pragprog.com/titles/mnee2/release-it-second-edition/)
