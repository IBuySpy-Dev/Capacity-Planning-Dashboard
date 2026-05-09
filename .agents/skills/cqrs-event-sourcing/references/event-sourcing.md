# CQRS Event Sourcing — Event Store, Snapshots & Versioning

## Event Store

The event store is the single source of truth. It stores events chronologically
and supports replay.

```csharp
public interface IEventStore
{
    Task AppendAsync(Guid aggregateId, IEnumerable<DomainEvent> events);
    Task<T> LoadAsync<T>(Guid aggregateId) where T : AggregateRoot;
    Task<IEnumerable<DomainEvent>> GetEventsAsync(Guid aggregateId);
    Task<IEnumerable<(Guid AggregateId, DomainEvent Event)>> GetAllEventsAsync(long fromVersion = 0);
}
```

**Implementation Considerations**

- Ensure atomicity: either all events in a batch are stored or none
- Maintain a global sequence number for cross-aggregate ordering
- Implement cleanup/archival for old events after snapshots are taken

## Snapshots

For large aggregates with long event histories, replaying all events is slow.
Snapshots capture aggregate state at points in time.

**Strategy:** snapshot every N events (e.g., every 100) or after each command.
When loading: fetch latest snapshot, replay events since snapshot version.

```csharp
public interface ISnapshotStore
{
    Task SaveSnapshotAsync(Guid aggregateId, AggregateSnapshot snapshot);
    Task<AggregateSnapshot> GetLatestSnapshotAsync(Guid aggregateId);
}

public async Task<T> LoadWithSnapshotAsync<T>(Guid aggregateId) where T : AggregateRoot
{
    var snapshot = await _snapshotStore.GetLatestSnapshotAsync(aggregateId);
    var aggregate = snapshot != null
        ? (T)Activator.CreateInstance(typeof(T), snapshot.State)
        : (T)Activator.CreateInstance(typeof(T));

    var events = await _eventStore.GetEventsAfterAsync(aggregateId, snapshot?.Version ?? 0);
    aggregate.LoadFromHistory(events);
    return aggregate;
}
```

## Event Versioning

Events evolve as business requirements change. Versioning ensures backward compatibility.

**Strategy:** Each event includes a `version` field (default: 1). New versions become
new event types (`OrderCreatedV2`). Use upcasting to convert old versions at
deserialization time — do not duplicate handler logic.

```csharp
public interface IEventUpcaster
{
    DomainEvent Upcast(object oldEventData);
}

public class OrderCreatedUpcaster : IEventUpcaster
{
    public DomainEvent Upcast(object oldEventData)
    {
        var v1 = (OrderCreatedV1)oldEventData;
        return new OrderCreated(v1.OrderId, v1.CustomerId, v1.Items,
            new Money(v1.Total, "USD")); // v2 adds explicit currency
    }
}
```

**Rules**

- Subscribers must handle all event versions
- Never change the schema of an existing event version
- Prefer additive changes (new optional fields) before cutting a new version
- Document the migration path in event changelog
