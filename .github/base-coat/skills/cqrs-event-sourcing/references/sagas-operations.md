# CQRS Sagas & Operational Concerns

## Saga Pattern for Distributed Transactions

Sagas coordinate multi-aggregate workflows using events and compensating actions.
There are no distributed transactions — only eventual consistency.

**Saga Characteristics**

- Steps: each step is a command or event handler
- Each step publishes events that trigger the next step
- Compensating actions undo previous steps on failure

**Example: Order Fulfillment Saga**

```
1. OrderCreated event fires
2. InventoryService → AllocateInventory → InventoryAllocated
3. ShippingService → CreateShipment → ShipmentCreated
4. If inventory fails → compensate: OrderCreationFailed
```

## Event Replay

Replay events from the beginning to rebuild corrupted read models or verify aggregate state.

```csharp
public async Task RebuildReadModelAsync(Type readModelType)
{
    await _readModelRepository.ClearAsync(readModelType);
    var allEvents = await _eventStore.GetAllEventsAsync(0);

    foreach (var (aggregateId, @event) in allEvents)
    {
        await _readModelUpdater.OnEventAsync(@event);
    }
}
```

**Pre-replay checklist**

- [ ] Take a backup of the current read model
- [ ] Pause incoming commands during replay (or use versioned replica)
- [ ] Monitor event processing rate — large event stores can take minutes
- [ ] Validate read model after replay before routing traffic back

## Monitoring and Observability

| Signal | Alert Threshold | Action |
|---|---|---|
| Event publishing latency | p99 > 500ms | Check broker throughput |
| Dead letter queue depth | > 0 sustained | Investigate failed events |
| Read model lag | > 30s from write | Check subscriber health |
| Snapshot age | > 1000 events behind | Trigger snapshot creation |

**Key correlation fields to include in all events:**

- `correlationId` — ties commands → events → read model updates
- `traceId` — distributed tracing across service boundaries
- `aggregateVersion` — for optimistic concurrency validation

## Disaster Recovery

- Archive old event data for long-term retention (compliance, auditing)
- Maintain backups of both event store and snapshot store
- Test event replay and snapshot recovery procedures regularly (minimum quarterly)
- Document RTO/RPO per aggregate type — event replay time scales with event store size
