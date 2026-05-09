# Enterprise Configuration — Security Policies and Setup Checklist

## Security Policies

### Configure Code Suggestion Controls

1. Enterprise → Settings → Policies → Copilot → Code suggestions
2. Choose: **Enable for all users** / **Disable for all users** / **Custom policy** (per org/team)

### Configure Public Code Matching

1. Enterprise → Settings → Policies → Copilot → Public code matching
2. **Allow:** Copilot can reference publicly available code (better suggestions)
3. **Disallow:** Disable public code matching (more restrictive)

### Enable Secret Scanning for Copilot

1. Enterprise → Settings → Security → Secret scanning
2. Enable **Secret scanning for Copilot** (alerts if generated code contains secrets)

## Billing and Cost Review

1. Enterprise → Settings → Billing → Copilot
2. View: Total monthly cost (Seats × $19/month), current seats used, per-model costs (web UI only)

See `tracking/github-api-billing-notes.md` for per-model cost API limitations.

## Enterprise Setup Checklist

### Phase 1 — Governance (Week 1)

- [ ] Designate enterprise admin(s) for Copilot
- [ ] Document Copilot usage policy
- [ ] Communicate policy to all teams
- [ ] Create issue templates for Copilot feedback

### Phase 2 — Infrastructure (Week 2)

- [ ] Enable Copilot in Enterprise settings
- [ ] Configure auto-seat or manual assignment workflow
- [ ] Set seat limits based on headcount + growth projection
- [ ] Grant organizations access to Copilot

### Phase 3 — Observability (Week 3)

- [ ] Enable usage metrics policy (most important step)
- [ ] Configure daily metrics reports
- [ ] Set up alerts for unusual usage patterns
- [ ] Document baseline metrics (adoption rate, usage by team)

### Phase 4 — Security (Week 4)

- [ ] Enable secret scanning for Copilot-generated code
- [ ] Review public code matching policy
- [ ] Document approved Copilot models (if restricting)
- [ ] Create data classification policy (public vs. confidential code)

### Phase 5 — Optimization (Month 2+)

- [ ] Review monthly usage metrics
- [ ] Optimize seat allocation (adjust limits, add/remove org access)
- [ ] Publish ROI report (productivity gains, cost per user)
- [ ] Gather feedback from users
- [ ] Plan for LLM model updates

## Related Documentation

- [GitHub Copilot Billing API](https://docs.github.com/en/rest/copilot/copilot-billing)
- [GitHub Copilot Metrics API](https://docs.github.com/en/rest/copilot/copilot-metrics)
- [GitHub Enterprise Settings](https://docs.github.com/en/enterprise-cloud@latest/admin/policies/enforcing-policies-for-your-enterprise/about-enterprise-policies)
- `tracking/github-api-billing-notes.md`
