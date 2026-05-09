---
name: penetration-testing
title: Penetration Testing & Vulnerability Discovery Patterns
description: Test case execution, OWASP Top 10 coverage, exploitation techniques, and finding reporting
compatibility: ["agent:penetration-test"]
metadata:
  domain: security
  maturity: production
  audience: [security-engineer, red-team, bug-bounty]
allowed-tools: [bash, curl, python, docker, git]
---

# Penetration Testing Skill

Patterns for executing penetration tests aligned with OWASP standards, covering
reconnaissance, vulnerability discovery, exploitation, and reporting.

## Quick Navigation

| Reference | Contents |
|---|---|
| [references/test-cases.md](references/test-cases.md) | Test harness, OWASP coverage matrix, web application testing patterns |
| [references/exploitation.md](references/exploitation.md) | Common vulnerability exploitation (SSTI, XXE, deserialization, API flaws) |
| [references/reporting.md](references/reporting.md) | Finding template, CVSS scoring, remediation payloads |

## Test Execution Flow

```
1. Scope definition → agree on target URLs, IP ranges, allowed techniques
2. Reconnaissance   → enumerate endpoints, gather tech stack info
3. Vulnerability discovery → OWASP Top 10 test cases
4. Exploitation     → validate severity by demonstrating impact
5. Reporting        → finding template per vulnerability, CVSS score
6. Remediation      → provide fix code, verify fix in retest
```

## OWASP Top 10 Quick Reference

| # | Category | Key Test |
|---|---|---|
| A01 | Broken Access Control | BOLA: access other users' objects via ID manipulation |
| A02 | Cryptographic Failures | Weak algorithms, plaintext secrets, missing TLS |
| A03 | Injection | SQLi, NoSQLi, command injection, SSTI |
| A04 | Insecure Design | Missing rate limits, no abuse-case coverage |
| A05 | Security Misconfiguration | Default creds, debug endpoints, verbose errors |
| A06 | Vulnerable Components | Known CVEs in dependencies |
| A07 | Auth Failures | Session fixation, missing MFA, brute-force exposure |
| A08 | Data Integrity Failures | Insecure deserialization, unsigned updates |
| A09 | Logging Failures | Missing audit logs, PII in logs |
| A10 | SSRF | Unvalidated URLs, internal network access |

## Scope Rules

- **Never test without written authorization** — document the engagement scope
- Respect rate limits — use backoff to avoid DoS during testing
- Stop and report immediately if Critical (RCE, credential dump) is found
- Do not exfiltrate real user data — stop at proof-of-concept level
