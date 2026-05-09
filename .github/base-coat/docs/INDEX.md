# Base Coat Documentation Index

> A complete map of all documentation in this repository, organized by topic area.
> For asset inventory, see [reference/INVENTORY.md](reference/INVENTORY.md).

## Core

- [../README.md](../README.md) — Getting started, installation, and overview
- [../CHANGELOG.md](../CHANGELOG.md) — Release history
- [../CONTRIBUTING.md](../CONTRIBUTING.md) — Contribution guide
- [PHILOSOPHY.md](PHILOSOPHY.md) — Design philosophy and principles

## Agents (`docs/agents/`)

- [agents/AGENTS.md](agents/AGENTS.md) — Agent catalog and index
- [agents/AGENT_SKILL_MAP.md](agents/AGENT_SKILL_MAP.md) — Agent-to-skill dependency map
- [agents/AGENT_RUNTIME_ENFORCEMENT.md](agents/AGENT_RUNTIME_ENFORCEMENT.md) — Runtime enforcement rules
- [agents/AGENT_TELEMETRY.md](agents/AGENT_TELEMETRY.md) — Telemetry and adoption metrics
- [agents/AGENT_TESTING.md](agents/AGENT_TESTING.md) — Agent testing strategy
- [agents/AGENT_TESTING_HARNESS.md](agents/AGENT_TESTING_HARNESS.md) — Test harness implementation
- [agents/agent-handoffs.md](agents/agent-handoffs.md) — Agent handoff protocols
- [agents/agentic-workflows.md](agents/agentic-workflows.md) — Agentic workflow reference
- [agents/MULTI_AGENT_WORKFLOWS.md](agents/MULTI_AGENT_WORKFLOWS.md) — Multi-agent orchestration patterns
- [agents/app-inventory.md](agents/app-inventory.md) — Application inventory agent guide

## Architecture (`docs/architecture/`)

- [architecture/AI_ARCHITECTURE_PATTERNS.md](architecture/AI_ARCHITECTURE_PATTERNS.md) — AI system design patterns
- [architecture/RAG_PATTERNS.md](architecture/RAG_PATTERNS.md) — Retrieval-Augmented Generation patterns
- [architecture/LOCAL_MODELS.md](architecture/LOCAL_MODELS.md) — Local LLM deployment
- [architecture/LOCAL_EMBEDDINGS.md](architecture/LOCAL_EMBEDDINGS.md) — Local embeddings configuration
- [architecture/OFFLINE_AGENT_STACK.md](architecture/OFFLINE_AGENT_STACK.md) — Offline / air-gapped agent stack
- [architecture/multi-agent-orchestration-patterns.md](architecture/multi-agent-orchestration-patterns.md) — LangGraph patterns
- [architecture/concurrency-phase2.md](architecture/concurrency-phase2.md) — Concurrency Phase 2 design
- [architecture/execution-hierarchy.md](architecture/execution-hierarchy.md) — 5-layer execution stack

## Memory (`docs/memory/`)

- [memory/shared-memory.md](memory/shared-memory.md) — Two-tier shared memory architecture
- [memory/SQLITE_MEMORY.md](memory/SQLITE_MEMORY.md) — SQLite cross-session memory layer

## Guides (`docs/guides/`)

- [guides/enterprise-setup.md](guides/enterprise-setup.md) — Initial enterprise setup
- [guides/enterprise-rollout.md](guides/enterprise-rollout.md) — Enterprise rollout playbook
- [guides/repo-template-standard.md](guides/repo-template-standard.md) — Repo template standards
- [guides/ENTERPRISE_DOTNET_GUIDANCE.md](guides/ENTERPRISE_DOTNET_GUIDANCE.md) — .NET modernization patterns
- [guides/DOTNET_DECISION_TREE.md](guides/DOTNET_DECISION_TREE.md) — .NET version decision tree
- [guides/DOTNET_MODERNIZATION.md](guides/DOTNET_MODERNIZATION.md) — Modernization guide
- [guides/WINDOWS_SERVER_AZURE_GUIDANCE.md](guides/WINDOWS_SERVER_AZURE_GUIDANCE.md) — Windows Server on Azure
- [guides/MODEL_OPTIMIZATION.md](guides/MODEL_OPTIMIZATION.md) — Model routing and optimization
- [guides/token-optimization.md](guides/token-optimization.md) — Token usage optimization
- [guides/rate-limit-guidance.md](guides/rate-limit-guidance.md) — Rate limit handling
- [guides/prd-and-spec-guidance.md](guides/prd-and-spec-guidance.md) — PRD and spec gate guidance
- [guides/CONFIG_PATTERN.md](guides/CONFIG_PATTERN.md) — Configuration pattern reference
- [guides/pydantic-validation-strategy.md](guides/pydantic-validation-strategy.md) — Pydantic validation strategy
- [guides/CODE_EXAMPLES.md](guides/CODE_EXAMPLES.md) — Code examples reference
- [guides/DEPLOYMENT_CHECKLIST.md](guides/DEPLOYMENT_CHECKLIST.md) — Deployment checklist

## Integrations (`docs/integrations/`)

- [integrations/mcp-deployment.md](integrations/mcp-deployment.md) — Deploying the Base Coat MCP server
- [integrations/pydantic-mcp-integration.md](integrations/pydantic-mcp-integration.md) — Pydantic + MCP integration
- [integrations/pydantic-typescript-client-generation.md](integrations/pydantic-typescript-client-generation.md) — TypeScript client generation
- [integrations/AZURE_AD_INTEGRATION_GUIDE.md](integrations/AZURE_AD_INTEGRATION_GUIDE.md) — Azure AD integration
- [integrations/AZURE_SQL_MIGRATION_GUIDANCE.md](integrations/AZURE_SQL_MIGRATION_GUIDANCE.md) — Azure SQL migration
- [integrations/ENTERPRISE_IDENTITY_ACCESS.md](integrations/ENTERPRISE_IDENTITY_ACCESS.md) — Identity & access patterns
- [integrations/ENTERPRISE_KUBERNETES_PATTERNS.md](integrations/ENTERPRISE_KUBERNETES_PATTERNS.md) — AKS / K8s guidance
- [integrations/APPLICATION_GATEWAY_ROUTING_GUIDANCE.md](integrations/APPLICATION_GATEWAY_ROUTING_GUIDANCE.md) — App Gateway routing
- [integrations/RBAC_ONLY_AUTHENTICATION_PATTERNS.md](integrations/RBAC_ONLY_AUTHENTICATION_PATTERNS.md) — RBAC auth patterns
- [integrations/untools-integration.md](integrations/untools-integration.md) — UnTools integration guide

## Reference (`docs/reference/`)

- [reference/INVENTORY.md](reference/INVENTORY.md) — Full asset listing (agents, skills, instructions, prompts)
- [reference/GOVERNANCE.md](reference/GOVERNANCE.md) — Contribution policies and review standards
- [reference/DISTRIBUTION.md](reference/DISTRIBUTION.md) — Sync mechanism for consumer repos
- [reference/HOOKS.md](reference/HOOKS.md) — Git hooks and pre-commit validation
- [reference/GOALS.md](reference/GOALS.md) — Project goals and OKRs
- [reference/SCOPED_INSTRUCTIONS.md](reference/SCOPED_INSTRUCTIONS.md) — Scoped instruction authoring guide
- [reference/LABEL_TAXONOMY.md](reference/LABEL_TAXONOMY.md) — GitHub label taxonomy
- [reference/PROMPT_REGISTRY.md](reference/PROMPT_REGISTRY.md) — Prompt catalog and registry
- [reference/ASSET_REGISTRY.md](reference/ASSET_REGISTRY.md) — Asset registry metadata
- [reference/CLI_COMMAND_REFERENCE.md](reference/CLI_COMMAND_REFERENCE.md) — CLI command reference
- [reference/COMPONENT_LIBRARY.md](reference/COMPONENT_LIBRARY.md) — Component library reference
- [reference/PRODUCT.md](reference/PRODUCT.md) — Product vision and roadmap
- [reference/QUICK_REFERENCE.md](reference/QUICK_REFERENCE.md) — Quick reference card
- [reference/treatment-matrix.md](reference/treatment-matrix.md) — Issue treatment matrix
- [reference/guardrails/](reference/guardrails/) — Guardrail configuration files

## Operations (`docs/operations/`)

- [operations/RELEASE_PROCESS.md](operations/RELEASE_PROCESS.md) — How releases are cut and published
- [operations/RELEASE_METRICS.md](operations/RELEASE_METRICS.md) — Release metrics and KPIs
- [operations/OPERATIONAL_RUNBOOK.md](operations/OPERATIONAL_RUNBOOK.md) — Runbook for common operations
- [operations/DISASTER_RECOVERY.md](operations/DISASTER_RECOVERY.md) — DR procedures
- [operations/COST_OPTIMIZATION.md](operations/COST_OPTIMIZATION.md) — Cost analysis and optimization
- [operations/ENTERPRISE_RUNNERS.md](operations/ENTERPRISE_RUNNERS.md) — Self-hosted runner setup
- [operations/ENTERPRISE_SECURITY_HARDENING.md](operations/ENTERPRISE_SECURITY_HARDENING.md) — Security hardening guide
- [operations/BLOCKED_ISSUES.md](operations/BLOCKED_ISSUES.md) — Blocked issues tracking
- [operations/TELEMETRY_ADOPTION.md](operations/TELEMETRY_ADOPTION.md) — Adoption telemetry guide
- [operations/GITHUB_SECRETS.md](operations/GITHUB_SECRETS.md) — Repository secrets setup and rotation guide
- [operations/security/](operations/security/) — Security policies and audit docs

## Templates (`docs/templates/`)

- [templates/](templates/) — Reusable file and directory templates (shared memory, repo scaffold, etc.)

## Archive (`docs/archive/`)

> Historical Wave 3 staging deliverables, portal design docs, wireframes, and cleanup reports.
> These are preserved for reference but are not part of the active framework.

- [archive/](archive/) — All archived Wave 3, portal, design, and audit documents
