# Incident Escalation and Compliance

## Severity Classification

| Severity | Example | Response Time | Action |
|---|---|---|---|
| **P0 / Critical** | Active data exfiltration, ransomware, auth bypass | 15 min | Incident Commander → Full mobilization |
| **P1 / High** | Lateral movement, privilege escalation, credential theft | 1 hour | SOC Analyst → Incident Handler |
| **P2 / Medium** | Multiple failed logins, suspicious traffic, policy violation | 4 hours | SOC Analyst → Investigation queue |
| **P3 / Low** | Single failed login, known-good process, informational | 1 day | Logged for trends analysis |

## Escalation Workflow

```text
1. ALERT TRIGGERED
   ├─ SIEM rule fires
   └─ Alert routed to on-call SOC analyst

2. TRIAGE (15 min)
   ├─ Confirm severity level
   ├─ False positive?
   │   ├─ YES → Tune rule, document whitelist
   │   └─ NO → Proceed to investigation

3. INVESTIGATION (30 min–2 hours)
   ├─ Determine scope (1 user? 100 users? whole network?)
   ├─ Identify attack pattern (recon? exploitation? exfiltration?)
   ├─ Correlate with other events
   └─ Gather evidence (logs, network captures, forensics)

4. ESCALATION DECISION
   ├─ Confirmed incident? → Open incident ticket
   ├─ Immediate action required? → Page incident commander
   ├─ Data exfiltration confirmed? → Notify legal + PR
   └─ Containment needed? → Begin remediation playbook

5. RESPONSE
   ├─ Isolate affected systems
   ├─ Kill malicious processes
   ├─ Reset compromised credentials
   ├─ Patch exploited vulnerabilities
   └─ Monitor for re-compromise
```

## On-Call Rotations

| Role | Coverage | Responsibilities |
|---|---|---|
| SOC Analyst | 24/7 rotation | Triage alerts, initial investigation |
| Incident Handler | 24/7 rotation | Confirmed incidents, remediation playbooks |
| Incident Commander | On-demand (P0/P1) | Stakeholder communication, mobilization |
| Forensics | Business hours + escalation | Post-incident analysis, evidence preservation |

## Compliance Mappings

### SOC2 CC7.2 — System Monitoring

Demonstrate:

- Real-time alerting (not just periodic log review)
- Baseline establishment and continuous monitoring
- Documented anomaly investigation records
- Response time SLAs met (with evidence)

### HIPAA Security Rule §164.308(a)(3)(ii)(H) — Monitoring & Reporting

Log and monitor:

- All access to ePHI (electronic protected health information)
- System events: login, logout, data access, modifications
- Retention: **minimum 6 years**

### PCI-DSS Requirement 10.3 — Security Event Logging

Monitor and log:

- All access to cardholder data environments
- Administrative access to critical systems
- Invalid access attempts (failed auth)
- Any disabling or modification of logging mechanisms

## References

- [NIST CSF 2.0 — Detect Function](https://csrc.nist.gov/publications/detail/cswp/29)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [OWASP A09:2021 — Security Logging and Monitoring Failures](https://owasp.org/Top10/A09_2021-Logging_and_Monitoring_Failures/)
- [CIS Controls v8 — Controls 8 and 9](https://www.cisecurity.org/controls)
