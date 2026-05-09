# Base Coat Router — Usage & Authoring

## Usage Modes

### Discovery Mode

| Command | What It Does |
|---------|--------------|
| `/basecoat` | Full categorized agent catalog |
| `/basecoat development` | Show only Development agents |
| `/basecoat quality` | Show only Quality agents |
| `/basecoat help [agent-name]` | Detailed usage card for one agent |
| `/basecoat find "[search term]"` | Fuzzy search across agent keywords |

Discovery results are organized by category:

**🔨 Development** — `@backend-dev`, `@frontend-dev`, `@middleware-dev`, `@data-tier`

**🏗️ Architecture** — `@solution-architect`, `@api-designer`, `@ux-designer`

**🔍 Quality** — `@code-review`, `@security-analyst`, `@performance-analyst`,
`@config-auditor`, `@manual-test-strategy`, `@exploratory-charter`, `@strategy-to-automation`

**🚀 DevOps** — `@devops-engineer`, `@release-manager`, `@rollout-basecoat`

**📋 Process** — `@sprint-planner`, `@product-manager`, `@issue-triage`,
`@retro-facilitator`, `@project-onboarding`

**🧰 Meta** — `@agent-designer`, `@prompt-engineer`, `@mcp-developer`,
`@tech-writer`, `@new-customization`, `@merge-coordinator`

### Delegation Mode

When a discipline keyword and prompt are provided, the router delegates directly:

```text
/basecoat backend build a REST API for user management
→ Delegates to @backend-dev with prompt "build a REST API for user management"

/basecoat security run threat model for auth service
→ Delegates to @security-analyst

/basecoat sprint plan sprint 12 from open issues
→ Delegates to @sprint-planner
```

## Delegation Instructions

1. **Match** the first token after `/basecoat` against the keyword routing table.
2. **Ambiguous match** — show top 2–3 candidates and ask the user to pick.
3. **Load the agent** — open the matched agent's instruction file.
4. **Pass the prompt** — forward everything after the keyword to the loaded agent.
5. **No match** — fall back to the full discovery menu with a note.

## Examples

```text
/basecoat                        → Full agent catalog by category
/basecoat architecture           → Architecture agents only
/basecoat help code-review       → Detailed usage card for @code-review
/basecoat find "deploy"          → Finds @devops-engineer, @release-manager
/basecoat backend build a REST API for orders
/basecoat docs write a runbook for deployment
```
