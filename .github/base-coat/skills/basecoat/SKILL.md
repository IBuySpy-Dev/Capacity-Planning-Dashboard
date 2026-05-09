---
name: basecoat
title: Base Coat Router & Agent Discovery
description: Single entry point for 73+ agents across 6 disciplines — discover or delegate across Development, Architecture, Quality, DevOps, Process, and Meta
compatibility: ["agent:*"]
metadata:
  domain: framework
  maturity: production
  audience: [all]
allowed-tools: [bash, curl, git]
---

# Base Coat Router

The front door to the Base Coat framework. Routes requests to the right agent across
6 disciplines and supports two modes: **Discovery** (browse agents) and **Delegation**
(route a prompt directly to the right agent).

## Quick Start

```text
/basecoat                        → Full agent catalog by category
/basecoat find "deploy"          → Search agents by keyword
/basecoat help code-review       → Usage card for @code-review
/basecoat backend build a REST API for orders  → Delegate to @backend-dev
```

## Reference Files

| File | Contents |
|------|----------|
| [`references/authoring.md`](references/authoring.md) | Discovery mode, delegation mode, examples |
| [`references/governance.md`](references/governance.md) | Full keyword-to-agent routing table, metadata registry, governance rules |

## Categories

| Category | Agents |
|----------|--------|
| 🔨 Development | `@backend-dev`, `@frontend-dev`, `@middleware-dev`, `@data-tier` |
| 🏗️ Architecture | `@solution-architect`, `@api-designer`, `@ux-designer` |
| 🔍 Quality | `@code-review`, `@security-analyst`, `@performance-analyst`, `@config-auditor`, and more |
| 🚀 DevOps | `@devops-engineer`, `@release-manager`, `@rollout-basecoat` |
| 📋 Process | `@sprint-planner`, `@product-manager`, `@issue-triage`, `@retro-facilitator` |
| 🧰 Meta | `@agent-designer`, `@prompt-engineer`, `@mcp-developer`, `@tech-writer` |

See `references/authoring.md` for the full per-category agent list with invocation commands.

## Fallback Behavior

If no keyword matches, show the full discovery menu with:
> "I couldn't match '[term]' to a specific agent. Here's the full catalog — pick the one that fits."
