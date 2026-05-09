# Detection Rules and Log Schema

## MITRE ATT&CK Mapping

Every detection rule must map to a MITRE ATT&CK technique:

```yaml
Rule Anatomy:
  MITRE ATT&CK Tactic: "Persistence"
  MITRE ATT&CK Technique: "T1547 (Boot or Logon Autostart Execution)"
  Sub-technique: "T1547.001 (Registry Run Keys / Startup Folder)"

  Example Indicators:
    - Registry write to HKLM\Software\Microsoft\Windows\CurrentVersion\Run
    - New .lnk in C:\Users\*\AppData\Roaming\Microsoft\...\Startup
    - New scheduled task with SYSTEM privilege
```

## Detection Query Templates

### Template 1: Behavioral Anomaly (Statistical)

```sql
-- Detect activity spike vs 7-day baseline
SELECT user, hostname, action, COUNT(*) AS count
FROM events
WHERE timestamp > now() - INTERVAL 5 MINUTE
GROUP BY user, hostname, action
HAVING count > (
  SELECT AVG(count) FROM events
  WHERE timestamp > now() - INTERVAL 7 DAY
) * 3
```

### Template 2: Known Malware Indicator (IoC Match)

```sql
-- Match events against threat intelligence feeds
SELECT * FROM events
WHERE ip IN (
  SELECT ip FROM threat_intel
  WHERE source = 'CISA' AND type = 'malware_c2'
)
OR file_hash IN (
  SELECT file_hash FROM threat_intel
  WHERE source = 'VirusTotal' AND verdict = 'malicious'
)
```

### Template 3: Impossible Travel (Location-Based)

```sql
-- Flag logins from geographically impossible locations
SELECT user, location1, location2,
       (miles / time_seconds * 3600 / 3.6e6) AS mph
FROM (
  SELECT user,
    LAG(location) OVER (PARTITION BY user ORDER BY timestamp) AS location1,
    location AS location2,
    calculate_distance(LAG(location) OVER (PARTITION BY user ORDER BY timestamp), location) AS miles,
    EXTRACT(EPOCH FROM timestamp - LAG(timestamp) OVER (PARTITION BY user ORDER BY timestamp)) AS time_seconds
  FROM login_events
)
WHERE mph > 900 -- Faster than commercial jet
```

## Security Event Log Schema

All security logs must include:

```json
{
  "timestamp": "2024-05-03T14:22:31.234Z",
  "event_id": "uuid-v4",
  "event_type": "authentication_attempt | process_creation | file_write | network_connect",
  "severity": "critical | high | medium | low | info",
  "source": {
    "user": "alice@example.com",
    "hostname": "laptop-001",
    "ip": "192.168.1.100",
    "process_name": "powershell.exe",
    "process_id": 1234
  },
  "resource": {
    "type": "file | registry | network | credential",
    "name": "C:\\Windows\\System32\\config\\SAM",
    "action": "read | write | delete | execute"
  },
  "threat_intel": {
    "matched_indicators": ["APT.Lazarus.C2.Domain"],
    "risk_score": 85
  },
  "context": {
    "mitre_attck": ["T1005 (Data from Local System)"],
    "compliance": ["PCI-DSS.10.2.1"]
  }
}
```

## Rule Quality Checklist

Before deploying a detection rule to production:

- [ ] MITRE ATT&CK technique mapped
- [ ] Baseline established and documented
- [ ] False-positive rate tested in staging (< 5% FP target)
- [ ] Response action documented for each severity level
- [ ] Whitelist entries justified and reviewed
- [ ] Tuning schedule set (re-evaluate monthly)
