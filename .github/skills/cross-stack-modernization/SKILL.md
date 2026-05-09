---
name: cross-stack-modernization
description: Language-agnostic application modernization patterns including strangler fig, anti-corruption layer, risk scoring, and dependency extraction sequencing.
metadata:
  category: modernization
  keywords: "modernization, strangler-fig, anti-corruption-layer, refactor, rewrite, migration, legacy"
  maturity: production
  audience: [solution-architect, backend-engineer, platform-engineer]
allowed-tools: [bash, git, grep, find]
---

# Cross-Stack Modernization

Language-agnostic patterns for incrementally modernizing legacy applications.
Covers strangler fig, anti-corruption layer (ACL), database-first vs UI-first
strategies, migration risk scoring, and dependency extraction sequencing.

## Triggers

Use this skill when:

- Deciding whether to rewrite, refactor, or replace a legacy application or service
- Planning an incremental migration without a big-bang cutover
- Wrapping a legacy API to shield new code from its quirks
- Sequencing which components to extract or replace first
- Scoring migration risk across a portfolio of services
- Choosing between database-first and UI-first migration approaches

## Inputs

- Inventory of services or modules to modernize (language, age, size, owners)
- Dependency graph (what calls what; what shares data)
- Existing test coverage percentage per module
- Coupling indicators: shared database tables, synchronous call chains, shared libraries
- Business constraints: zero-downtime required, regulatory freeze windows, team capacity

## Workflow

### 1. Assess: rewrite vs refactor vs replace

Use this decision matrix before committing to any strategy:

| Criterion | Refactor | Strangler-fig replace | Full rewrite |
|-----------|----------|----------------------|-------------|
| Test coverage | > 60 % | 30–60 % | < 30 % |
| External API surface | Stable | Wrappable | Broken / undocumented |
| Team knowledge | High | Medium | Low (net-new) |
| Time horizon | Weeks | Months | Quarters |
| Risk tolerance | Low | Medium | High |

Prefer **refactor** when the codebase is testable and the domain model is sound.
Prefer **strangler fig** when the system is live and cannot be taken down.
Prefer **full rewrite** only when the code is irredeemably coupled, undocumented,
or the target platform is fundamentally different.

### 2. Strangler fig pattern

Route new functionality to the replacement system while the legacy system handles
everything else. Incrementally move routes or capabilities until the legacy is empty.

```text
┌─────────────┐        ┌───────────────────┐
│   Clients   │──────▶ │   Routing layer   │
└─────────────┘        │  (proxy / facade) │
                       └────────┬──────────┘
                  legacy ◀──────┤──────▶ new system
                  (shrinks)     │        (grows)
```

Steps:

1. Place a routing proxy in front of the legacy system (nginx, API Gateway, BFF).
2. Identify the lowest-risk, highest-value capability to migrate first.
3. Build the replacement behind a feature flag; route a small traffic slice.
4. Validate, then shift 100 % of that route to the new system.
5. Remove the legacy code path. Repeat for the next capability.

### 3. Anti-corruption layer (ACL)

Wrap the legacy API in an adapter that translates its model into your domain model.
New code only calls the ACL; it never depends directly on legacy internals.

```text
New service ──▶ ACL (adapter) ──▶ Legacy API
                  │
                  └── translates: legacy DTO ↔ domain model
                      enforces: invariants, nullability, naming
```

Implementation checklist:

- Define a domain interface first; implement the ACL against it.
- Log all translation errors — they reveal legacy contract gaps.
- Version the ACL if the legacy API changes; never silently absorb breaking changes.
- Write contract tests against the ACL boundary, not against legacy internals.

### 4. Database-first vs UI-first migration

**Database-first**: Migrate the data model and persistence layer first; keep the UI on legacy.

- Use when: data integrity is the primary risk; UI is thin or regeneratable.
- Pattern: dual-write to old and new schema during transition; cut reads over gradually.
- Risk: longer period of dual-write complexity; legacy UI must tolerate schema changes.

**UI-first**: Replace the frontend and API layer first; keep legacy data store.

- Use when: the UI is the primary UX debt; data model is relatively clean.
- Pattern: new UI calls an ACL that proxies to legacy data; migrate data later.
- Risk: ACL carries business logic that must eventually move to the data layer.

Choose **database-first** when data consistency is non-negotiable (financial, medical).
Choose **UI-first** when the legacy backend is stable and the UX is the blocker.

### 5. Migration risk scoring

Score each service before sequencing:

```text
Risk = Complexity × Coupling × (1 / Test Coverage)
```

| Dimension | Score 1 | Score 2 | Score 3 |
|-----------|---------|---------|---------|
| Complexity | < 500 LOC, clear modules | 500–5000 LOC, some coupling | > 5000 LOC, tangled |
| Coupling | Few consumers, own DB | Shared DB or sync calls | Shared DB + sync calls + shared libs |
| Test coverage | > 70 % | 30–70 % | < 30 % |

Migrate **low-risk** services first to build team confidence and tooling.
Tackle **high-risk** services last, after patterns and ACLs are proven.

### 6. Dependency extraction sequencing

Extract in leaf-to-root order — start with services that have no downstream consumers:

1. List all dependencies (call graph + data dependencies).
2. Identify **leaf nodes**: services nothing else depends on.
3. Extract leaves first; each extraction reduces coupling for the next layer.
4. Work inward toward the most-coupled core last.
5. After each extraction, update the dependency graph and re-score.

Never extract a shared-database component before all its consumers have been
migrated to call it through an API.

## Output

- Migration strategy decision (refactor / strangler fig / rewrite) with rationale
- Risk scores per service and recommended extraction sequence
- ACL interface definitions for wrapped legacy APIs
- Database-first or UI-first selection with transition plan
- Routing proxy configuration for strangler fig (if applicable)

## Examples

### Risk scoring a service portfolio

```text
Service A: Complexity=1, Coupling=1, Coverage=80% → Risk = 1×1×(1/0.8) = 1.25  ✅ migrate first
Service B: Complexity=2, Coupling=2, Coverage=40% → Risk = 2×2×(1/0.4) = 10    ⚠ mid-queue
Service C: Complexity=3, Coupling=3, Coverage=10% → Risk = 3×3×(1/0.1) = 90    🔴 migrate last
```

### Strangler fig routing with nginx

```nginx
location /api/orders {
    # New orders service
    proxy_pass http://orders-new.internal;
}

location /api/ {
    # Legacy catch-all (shrinks over time)
    proxy_pass http://legacy-api.internal;
}
```

### ACL adapter (TypeScript example)

```typescript
// Domain interface — new code depends only on this
interface OrderRepository {
  findById(id: string): Promise<Order>;
}

// ACL implementation wrapping legacy REST API
class LegacyOrderAdapter implements OrderRepository {
  async findById(id: string): Promise<Order> {
    const raw = await legacyClient.get(`/orders/${id}`);
    return {
      id: raw.order_id,           // legacy uses snake_case
      total: raw.total_amount_usd,
      status: mapLegacyStatus(raw.status_code),
    };
  }
}
```
