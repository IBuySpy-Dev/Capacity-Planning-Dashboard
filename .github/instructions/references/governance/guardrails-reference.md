# Governance — Guardrails Reference

## OIDC Federation — No Stored Azure Credentials

All GitHub Actions workflows that authenticate to Azure must use OIDC federated credentials
(`azure/login@v2` with `client-id`, `tenant-id`, `subscription-id`). Storing service principal
client secrets as GitHub Secrets is a policy violation.

See [`docs/guardrails/oidc-federation.md`](../../docs/guardrails/oidc-federation.md).

## CAF Naming Conventions for Azure Resources

All Azure resources must follow Cloud Adoption Framework (CAF) naming conventions
(e.g., `rg-{workload}-{env}`, `ca-{workload}-{env}-{location}-{instance}`).
Non-compliant names must be flagged during code review.

See [`docs/guardrails/caf-naming.md`](../../docs/guardrails/caf-naming.md).

## Container Image Tags — SHA Required

Every container image pushed from CI/CD must be tagged with the full git commit SHA.
Pushing only `:latest` is a policy violation.

See [`docs/guardrails/container-image-tags.md`](../../docs/guardrails/container-image-tags.md).

## Environment Variables — `.env.example` Required

Every repository that requires environment variables must include a `.env.example` at the root
documenting all required variables with placeholder values and description comments. Real values
(`.env`, `.env.local`) are gitignored.

See [`docs/guardrails/env-example.md`](../../docs/guardrails/env-example.md).

## Database Deployment Concurrency

Any GitHub Actions workflow that runs database migrations or schema changes **must** set
`cancel-in-progress: false` in its concurrency group. Cancelling a running DB deploy can
leave the database in a partially-migrated state.

See [`docs/guardrails/db-deployment-concurrency.md`](../../docs/guardrails/db-deployment-concurrency.md).

## Deployment Cancellation Pre-Flight Check

Before stopping or cancelling **any** in-progress infrastructure deployment, run:

1. Identify what is running and its current progress
2. Assess the blast radius — list resources already created and operations still in-flight
3. Check for dependent downstream systems that consume deployment outputs
4. Make an explicit go / no-go decision

See [`docs/guardrails/deployment-cancellation.md`](../../docs/guardrails/deployment-cancellation.md).
