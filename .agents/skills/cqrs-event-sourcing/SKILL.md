---
name: cqrs-event-sourcing
description: CQRS (Command Query Responsibility Segregation) and Event Sourcing patterns for scalable, auditable, distributed systems. Covers command execution, event storage, read model synchronization, eventual consistency, and event replay.
compatibility: ["backend-dev", "middleware-dev", "data-tier"]
metadata:
  category: "Architecture & Design"
  tags: ["cqrs", "event-sourcing", "event-driven", "distributed-systems", "data-persistence"]
  maturity: "production"
  audience: ["backend-developers", "architects", "platform-teams"]
allowed-tools: ["csharp", "sql", "bash", "git"]
---

# CQRS & Event Sourcing Patterns

Comprehensive patterns for implementing CQRS and Event Sourcing in distributed systems.

## Quick Navigation

| Reference | Contents |
|---|---|
| [references/command-side.md](references/command-side.md) | Commands, command handlers, aggregate design |
| [references/event-sourcing.md](references/event-sourcing.md) | Event store, aggregate reconstruction, snapshots, versioning |
| [references/read-side.md](references/read-side.md) | Queries, read models, event subscribers, eventual consistency |
| [references/sagas-operations.md](references/sagas-operations.md) | Saga pattern, event replay, monitoring, disaster recovery |

## CQRS Overview

CQRS separates read and write logic:

- **Commands**: Operations that modify state (CreateOrder, UpdateInventory).
- **Queries**: Operations that retrieve state (GetOrder, ListOrders).
- **Events**: Records of state changes that occurred (OrderCreated, OrderShipped).

**Benefits**

- Independent scaling of read and write models
- Optimized read models for specific query patterns
- Clearer separation of concerns
- Better support for event-driven architectures
- Audit trail and temporal queries

**Trade-offs**

- Eventual consistency between write and read models
- Increased operational complexity
- Requires careful handling of consistency boundaries

## Core Flow

```
User → Command → Command Handler → Event Store → Events → Event Bus
                                                            ↓
                                                    Event Handlers
                                                            ↓
                                                      Read Models
                                                            ↓
                                                  Query Handlers → User
```

## When to Use

**Use when:** audit trail is a hard requirement; read/write workloads need independent
scaling; multiple read-optimized views are needed; event-driven architecture is in use.

**Avoid when:** simple CRUD with uniform load; small team without distributed-systems
experience; low-throughput domain where eventual consistency adds friction without benefit.
