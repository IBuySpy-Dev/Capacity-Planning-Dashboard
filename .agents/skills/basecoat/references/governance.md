# Base Coat Router — Keyword Routing & Governance

## Keyword-to-Agent Routing Table

| Keyword(s) | Agent | Category |
|------------|-------|----------|
| backend, api, server | @backend-dev | 🔨 Development |
| frontend, ui, web | @frontend-dev | 🔨 Development |
| middleware, integration, gateway | @middleware-dev | 🔨 Development |
| data, database, db | @data-tier | 🔨 Development |
| architect, design, system | @solution-architect | 🏗️ Architecture |
| api-design, openapi, swagger | @api-designer | 🏗️ Architecture |
| ux, accessibility, wireframe | @ux-designer | 🏗️ Architecture |
| review, cr, pull-request | @code-review | 🔍 Quality |
| security, vulnerability, threat | @security-analyst | 🔍 Quality |
| perf, performance, profiling | @performance-analyst | 🔍 Quality |
| config, secrets, audit | @config-auditor | 🔍 Quality |
| manual-test, test-strategy | @manual-test-strategy | 🔍 Quality |
| exploratory, charter | @exploratory-charter | 🔍 Quality |
| automate-tests, test-automation | @strategy-to-automation | 🔍 Quality |
| devops, cicd, deploy, pipeline | @devops-engineer | 🚀 DevOps |
| release, version, changelog | @release-manager | 🚀 DevOps |
| rollout, onboard-enterprise | @rollout-basecoat | 🚀 DevOps |
| sprint, plan, wave | @sprint-planner | 📋 Process |
| product, requirements, stories | @product-manager | 📋 Process |
| triage, classify, label | @issue-triage | 📋 Process |
| retro, retrospective | @retro-facilitator | 📋 Process |
| onboarding, setup, getting-started | @project-onboarding | 📋 Process |
| agent, create-agent | @agent-designer | 🧰 Meta |
| prompt, system-prompt | @prompt-engineer | 🧰 Meta |
| mcp, tools, tool-server | @mcp-developer | 🧰 Meta |
| docs, document, runbook | @tech-writer | 🧰 Meta |
| customization, create-skill | @new-customization | 🧰 Meta |
| merge, conflict, parallel-merge | @merge-coordinator | 🧰 Meta |

## Machine-Readable Registry

`basecoat-metadata.json` at the repository root contains the machine-readable registry of
all agents: names, descriptions, file paths, category groupings, keywords, aliases, and
paired skill references. Use it for programmatic matching when keyword lookup alone is
insufficient.

## Router Governance

- Maintain keyword uniqueness — no keyword should map to more than one agent.
- When adding a new agent, add its keywords to this table and `basecoat-metadata.json`.
- Run `pwsh tests/run-tests.ps1` to validate structure after changes.
- The router must not modify agent files — it reads and delegates only.
