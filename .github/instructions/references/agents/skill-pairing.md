# Agent Skill Pairing & Multi-Agent Coordination

## Allowed Skills Section

Every agent file **should** include an `## Allowed Skills` section.

```markdown
## Allowed Skills

- agent-design
- create-skill

This agent creates and validates agent definitions only. Do not invoke development,
deployment, or testing skills.
```

- List each skill by its folder name (e.g., `agent-design`, `api-design`).
- If the agent invokes no skills, include `*(none)*`.
- The `## Allowed Skills` section and the `allowed_skills` frontmatter field are both enforced — an agent must not invoke any skill not listed, even if shown in `<available_skills>`.

## Agent-to-Skill Pairing

- The skill directory name **must** match the agent's `name` field.
- If an agent references a template or checklist, it must exist in the paired skill directory.
- When creating a new agent, create its skill directory at the same time.

## Multi-Agent Coordination

1. **Explicit tagging** — hand off by @-mentioning the next agent: `@security-analyst — this PR adds a new public endpoint that accepts user input`.
2. **Contract-first** — the agent that defines a shared interface owns it; others consume it.
3. **Conflict resolution** — the agent closest to the risk owns the decision: `security-analyst` for security, `performance-analyst` for performance, `backend-dev` for API contracts.
4. **No scope leakage** — if `frontend-dev` discovers a backend bug, it files an issue and tags `backend-dev`; it does not fix the backend code.
5. **Parallel by default** — sequential ordering only when one agent's output is a prerequisite for another.

## Token Budget Management

- Scope inputs narrowly — request only the files the agent needs, not the entire repo.
- Summarize large inputs if they exceed 30% of the model's context window.
- Return structured, concise output (tables, checklists, code blocks) — avoid prose-heavy responses.
- Reference template paths (`skills/security/owasp-checklist.md`) rather than inlining full content.
