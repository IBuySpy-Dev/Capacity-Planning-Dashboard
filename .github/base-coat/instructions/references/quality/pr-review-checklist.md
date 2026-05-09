# Quality — PR Review Checklist Reference

## PR Review Minimum Bar

Every PR must satisfy all items before merging:

- [ ] Linked to a GitHub issue
- [ ] Branch name follows `<type>/<issue-number>-<description>` convention
- [ ] No secrets, tokens, or credentials committed
- [ ] CI is green (all checks passing)
- [ ] New or changed functionality has tests
- [ ] Test coverage thresholds met (see below)
- [ ] CHANGELOG entry added for user-facing changes
- [ ] PR description includes Summary, Validation, Issue Reference, and Risk sections
- [ ] No files outside the PR's declared scope modified

## Security Review Gate Triggers

The following changes require a security review (tag `security-analyst`):

- New authentication or authorization logic
- Changes to session handling or token validation
- New external API calls or webhook handlers
- Input parsing (query params, request body, file upload)
- New or modified infrastructure-as-code
- Dependency additions or upgrades (check for known CVEs)
- Changes to CI/CD pipeline files (`.github/workflows/`)

## Performance Budget Thresholds

| Metric | Budget | Enforcement |
|---|---|---|
| Frontend JS bundle (gzip) | ≤ 250 KB | CI gate |
| Largest Contentful Paint | ≤ 2.5 s | CI gate |
| API p99 latency | ≤ 500 ms | CI gate |
| Docker image size | ≤ 500 MB | CI gate |

PRs that exceed a budget must include a documented justification and a tracking issue.

## Code Coverage Thresholds

| Scope | Minimum | Enforcement |
|---|---|---|
| Overall project | ≥ 80% line coverage | CI gate — merge blocked below threshold |
| New / changed files | ≥ 90% line coverage | CI gate — merge blocked below threshold |
| Critical paths (auth, payment, data access) | ≥ 95% branch coverage | CI gate — merge blocked below threshold |

Coverage exceptions require a code comment and a tracking issue: `// Coverage exception — see #<N>`.
