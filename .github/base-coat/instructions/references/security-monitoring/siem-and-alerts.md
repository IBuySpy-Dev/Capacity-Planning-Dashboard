# SIEM Integration and Alert Rules

## Event Ingestion Configuration

- **Normalization:** Map all log formats to common schema (CEF, Syslog, or JSON).
- **Enrichment:** Add context — user, asset, geolocation, threat intelligence — to every event.
- **Parsing:** Define field extraction patterns per log source type.
- **Retention:** Set based on compliance requirement:
  - SOC2: 90 days minimum
  - HIPAA: 6 years
  - PCI-DSS: 1 year minimum

### Splunk Props.conf Example (Nginx Access Logs)

```ini
[nginx:access]
TRANSFORMS-extract = extract-fields
LINE_BREAKER = \n
TIME_PREFIX = \[
TIME_FORMAT = %d/%b/%Y:%H:%M:%S %z
```

## Alert Rule Template

```yaml
Alert:
  Name: "Suspicious PowerShell Execution"
  Type: "Correlation"  # Correlation | Anomaly | Threshold
  Severity: "High"     # Critical | High | Medium | Low
  MITRE ATT&CK: "T1027 (Obfuscated Files or Information)"

  Detection Query: |
    # Splunk SPL
    index=windows EventCode=4688
    | where process_name="powershell.exe"
    | where command LIKE "%IEX%" OR command LIKE "%DownloadString%"
    | stats count by user, hostname, command
    | where count > 3

  Baseline: "200 events/day (normal PowerShell activity)"
  Threshold: "5 events/hour from same host"

  Response Actions:
    Critical: Alert SOC immediately, open incident
    High: Alert SOC within 1 hour
    Medium: Queue for daily review
    Low: Log only, no alert

  Escalation:
    1. SOC Analyst reviews alert
    2. If confirmed: Incident Handler (response playbook)
    3. If critical: Incident Commander (mobilize)
    4. If exfiltration: Legal + PR notification
```

## False Positive Tuning

- **Whitelist known-good activity:** Service accounts, scheduled jobs, automation pipelines.
- **Baseline adjustment:** Update thresholds as systems scale (re-baseline monthly).
- **Correlation:** Combine weak signals into strong compound alerts to reduce noise.
- **Playbook:** Define an investigation checklist to confirm true positive before escalation.

### Example: Multiple Failed Logins

```yaml
Baseline:
  Normal: 10 failed logins/day (typos, forgotten passwords)
  Anomalous: 50+ failed logins/hour

Whitelist:
  - Service accounts: svc_app, svc_batch (expected failures)
  - VPN clients: <VPN_IP_RANGE> (brief authentication storms on reconnect)

Threshold: 25 failed logins in 5 minutes from single user
  Rationale: Filters human typos, catches brute-force
```

## Log Source Priority

| Source | Priority | Retention |
|---|---|---|
| Authentication events | P1 | 1 year |
| Privileged access events | P1 | 1 year |
| Network flow data | P2 | 90 days |
| Application error logs | P2 | 90 days |
| System event logs (Windows/Linux) | P2 | 90 days |
| DNS query logs | P3 | 30 days |
| Web proxy logs | P3 | 30 days |
