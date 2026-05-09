---
name: e2e-testing
title: E2E Testing - Playwright, Cypress, and Cross-Browser Patterns
description: Production E2E testing patterns with Playwright and Cypress, flakiness prevention, cross-browser matrices, accessibility testing, and CI/CD integration
compatibility: ["agent:e2e-test-strategy", "agent:contract-testing"]
metadata:
  domain: testing
  maturity: production
  audience: [qa-engineer, developer, test-automation-engineer]
allowed-tools: [bash, node, python, docker]
---

# E2E Testing Skill

Production patterns for reliable, maintainable end-to-end test suites using modern
testing frameworks.

## Quick Navigation

| Reference | Contents |
|---|---|
| [references/playwright-patterns.md](references/playwright-patterns.md) | Setup, test structure, waits, fixtures, mocking, accessibility, performance |
| [references/cypress-patterns.md](references/cypress-patterns.md) | Cypress config, test patterns, custom commands |
| [references/ci-integration.md](references/ci-integration.md) | CI matrix, flakiness prevention, test data management |

## Framework Decision Guide

| Criterion | Playwright | Cypress |
|---|---|---|
| Browser support | Chromium, Firefox, WebKit | Chromium, Firefox, Electron |
| Language | JS/TS, Python, Java, C# | JS/TS only |
| Parallel execution | Native, multi-process | Paid feature (Cypress Cloud) |
| API mocking | `page.route()` | `cy.intercept()` |
| Component testing | Yes | Yes |
| **Best for** | Cross-browser, multi-language | JS-first teams, quick setup |

## Core Principles

1. **No magic sleeps** — use smart waits (`waitForSelector`, `cy.contains().should(...)`)
2. **Test IDs over CSS selectors** — `data-testid` attributes are the most robust locators
3. **Isolate tests** — each test creates its own data; no shared state between tests
4. **Mock external services** — never hit real third-party APIs in E2E tests
5. **Deterministic environments** — use Docker for consistent browser and app versions
