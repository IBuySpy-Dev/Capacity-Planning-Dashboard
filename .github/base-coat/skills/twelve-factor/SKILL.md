---
name: twelve-factor
description: "12-Factor App methodology: codebase, dependencies, configuration, backing services, build/run/release, processes, port binding, concurrency, disposability, dev/prod parity, logs, and admin tasks"
compatibility: "Works with VS Code, CLI, and Copilot Coding Agent. Language-agnostic."
metadata:
  category: "architecture"
  keywords: "twelve-factor, app-architecture, cloud-native, stateless, configuration, processes"
  model-tier: "standard"
allowed-tools: "search/codebase"
---

# 12-Factor App Methodology

The 12-Factor App is a methodology for building modern, scalable, cloud-native applications.

## Quick Navigation

| Reference | Contents |
|---|---|
| [references/factors-1-6.md](references/factors-1-6.md) | Factors 1–6: codebase, dependencies, config, backing services, build/release/run, processes |
| [references/factors-7-12.md](references/factors-7-12.md) | Factors 7–12: port binding, concurrency, disposability, dev/prod parity, logs, admin tasks |

## The 12 Factors at a Glance

| # | Factor | Rule |
|---|---|---|
| 1 | Codebase | One repo → many deploys |
| 2 | Dependencies | Explicit declare + isolate |
| 3 | Config | Store in environment, not code |
| 4 | Backing services | Treat as attached resources |
| 5 | Build/Release/Run | Strictly separated stages |
| 6 | Processes | Stateless, share-nothing |
| 7 | Port binding | Self-contained HTTP service |
| 8 | Concurrency | Scale via process model |
| 9 | Disposability | Fast start, graceful shutdown |
| 10 | Dev/Prod parity | Keep environments identical |
| 11 | Logs | Treat logs as event streams (stdout) |
| 12 | Admin tasks | Run in same environment as app |

## Audit Checklist

Run before every deployment:

- [ ] Single repo; all code in Git
- [ ] Explicit lock file; no system-level dependencies
- [ ] Secrets in env vars; nothing hardcoded
- [ ] Backing service URLs from config; swappable without code change
- [ ] Immutable build artifact; separate release and run stages
- [ ] No in-memory session state; no local file writes
- [ ] App self-contained; binds to a port
- [ ] Horizontal scaling possible; processes are interchangeable
- [ ] Startup < 10s; SIGTERM handled gracefully
- [ ] Dev and prod use identical OS, language runtime, and DB versions
- [ ] Logs written to stdout only
- [ ] Admin tasks run with same image and config as the app

See `references/factors-1-6.md` and `references/factors-7-12.md` for full patterns and examples.
