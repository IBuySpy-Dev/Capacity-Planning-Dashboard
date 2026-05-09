# Quality — Agent Handoff Model Reference

## Four Review Agents

### code-reviewer

- **Scope:** Correctness, style, test quality, documentation, `development.instructions.md` adherence
- **Runs:** On every PR
- **Output:** Inline review comments — approves or requests changes
- **Handoff:** If diff touches a security gate trigger → add `security-review` label, tag `security-analyst`.
  If diff includes measurable performance changes → tag `performance-analyst`.

### security-analyst

- **Scope:** Trust boundaries, input validation, secrets handling, dependency risk, `security.instructions.md`
- **Runs:** On PRs labeled `security-review` or tagged by `code-reviewer`
- **Output:** Inline comments with severity ratings — approves or blocks
- **Handoff:** Remove `security-review` label when findings resolved. If infrastructure/pipeline changes involved → tag `devops`.

### performance-analyst

- **Scope:** Bundle size, API latency, Core Web Vitals, image/container size
- **Runs:** On PRs touching frontend bundles, API routes, database queries, or containers
- **Output:** Budget comparison table in PR comment — approves or requests optimization
- **Handoff:** If issue is infrastructure config → tag `devops`. If code-level → request changes from PR author.

### devops

- **Scope:** CI/CD pipeline correctness, deployment safety, infrastructure config, environment parity
- **Runs:** On PRs changing workflow files, Dockerfiles, IaC, or deployment scripts
- **Output:** Inline comments on pipeline and infrastructure files — approves or requests changes
- **Handoff:** Confirm staging deployment succeeded before production merge. If security concern found → tag `security-analyst`.

## Handoff Rules

1. **No agent merges alone.** PR requires approval from every agent whose scope is triggered.
2. **Tagging is explicit.** Agents tag the next agent by GitHub handle with reason for handoff.
3. **Blocking findings take priority.** Unresolved `critical` or `high` findings block merge.
4. **Async by default.** Agents review in parallel when scopes don't overlap.
5. **Escalation path.** Disagreements resolved by agent closest to the risk:
   - Security issues → `security-analyst`
   - Performance issues → `performance-analyst`
   - Deployment issues → `devops`
   - Correctness issues → `code-reviewer`
