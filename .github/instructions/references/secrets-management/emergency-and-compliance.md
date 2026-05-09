# Emergency Revocation and Compliance

## Emergency Revocation Procedure

**When a secret is compromised:**

```text
1. REVOKE IMMEDIATELY (0–5 min)
   vault revoke secret/my-api-key

2. ALERT STAKEHOLDERS (0–5 min)
   - Email: Affected team + security team
   - Slack: #security channel (public notification)
   - Create incident ticket

3. INVESTIGATE (5–30 min)
   - Audit logs: who accessed the secret and when?
   - When was it compromised?
   - Was it used for unauthorized activity?

4. MITIGATE (30 min–2 hours)
   - Generate new secret
   - Deploy new secret to all systems
   - Verify systems reconnect successfully
   - Monitor for errors

5. DOCUMENT (2–4 hours)
   - Post-incident review: root cause
   - Update security controls (rotate more frequently if needed)
   - Communicate remediation to stakeholders
```

## Break-Glass Access (Emergency)

For scenarios where normal Vault access is compromised:

```yaml
Break-Glass Credentials:
  Storage: Encrypted USB in physical safe/vault
  Access: Known to only 2–3 high-trust individuals
  Use: ONLY in declared emergency (incident commander + witness)
  Logging: All actions logged to external audit system
  Rotation: Annually, or immediately after any unplanned use

Break-Glass Procedure:
  1. Incident commander declares emergency and confirms need
  2. Request 2 break-glass signatories
  3. Retrieve encrypted USB from physical safe
  4. Decrypt using shared passphrase + hardware token
  5. Use credentials to access Vault/systems
  6. Log every action to external audit system
  7. Return USB to safe
  8. Rotate break-glass credentials within 24 hours
```

## Compliance Mappings

### SOC2 CC6.1 — Logical and Physical Access Controls

Demonstrate:

- Secrets stored in encrypted vault (AES-256 or better)
- Access restricted by role (least privilege)
- Full audit trail of all access attempts
- Automatic revocation policies configured

### HIPAA Security Rule §164.308(a)(3)(ii)(B) — Encryption/Decryption

Encrypt secrets at rest:

- Vault encryption: AES-256-GCM
- Database: column-level encryption for credentials
- Transmission: TLS 1.3+ for all secret access

### PCI-DSS Requirement 8.2.3 — Strong Cryptography

- 256-bit keys minimum
- FIPS 140-2 compliance for cryptographic modules
- Regular key rotation (minimum annually, more frequently per policy)

## References

- [NIST SP 800-57 Part 1 — Key Management](https://doi.org/10.6028/NIST.SP.800-57pt1r5)
- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [Azure Key Vault Best Practices](https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
