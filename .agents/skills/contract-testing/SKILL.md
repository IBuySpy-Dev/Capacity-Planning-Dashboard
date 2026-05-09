---
name: contract-testing
title: Contract Testing & Integration Patterns
description: Consumer-driven contracts, Pact, E2E testing, mutation testing, and integration test orchestration
compatibility: ["agent:contract-testing"]
metadata:
  domain: testing
  maturity: production
  audience: [qa-engineer, developer, architect]
allowed-tools: [python, docker, bash, java, javascript]
---

# Contract Testing Skill

Consumer-driven contracts, Pact, E2E testing, mutation testing, and integration test orchestration.

## Quick Start

1. Define consumer contracts using Pact — one per consumer/provider pair.
2. Write provider states for every contract interaction.
3. Run provider verification in CI against the Pact broker or local files.
4. Orchestrate full integration suites with Docker Compose.
5. Target >85% mutation score; block deployment if contract verification fails.

## Reference Files

| File | Contents |
|------|----------|
| [`references/pact-patterns.md`](references/pact-patterns.md) | Consumer contract definition, provider verification, provider states setup |
| [`references/e2e-orchestration.md`](references/e2e-orchestration.md) | Selenium E2E test, Docker Compose integration orchestration, mutation testing, report template |

## Key Patterns

- **Consumer-driven**: consumer writes the contract; provider must satisfy it
- **Provider states**: setup endpoint (`/provider-states`) seeds DB before each interaction
- **Mutation gate**: >85% mutation score required before merging
- **Deployment gate**: 🔴 BLOCKED if any contract fails verification

## References

- [Pact Specification](https://pact.foundation/)
- [Consumer-Driven Contract Testing](https://martinfowler.com/articles/consumerDrivenContracts.html)
- [Mutation Testing Guidelines](https://en.wikipedia.org/wiki/Mutation_testing)
