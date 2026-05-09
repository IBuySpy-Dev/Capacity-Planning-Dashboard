# CQRS Command Side — Commands, Handlers & Aggregates

## Commands

Commands are requests to perform actions that modify state. They are imperative and
synchronous.

**Command Characteristics**

- Imperative naming: `CreateOrder`, not `OrderCreated`
- Synchronous: caller waits for result (success or failure)
- Stateless handlers: each handler loads state, applies business logic, produces events
- Validation: commands validate input and preconditions before producing events

### Command Handler (C#)

```csharp
public class CreateOrderHandler : ICommandHandler<CreateOrderCommand>
{
    private readonly IEventStore _eventStore;
    private readonly IMessagePublisher _publisher;

    public async Task HandleAsync(CreateOrderCommand command)
    {
        if (command.Items.Count == 0)
            throw new InvalidOperationException("Order must contain at least one item");

        var order = await _eventStore.LoadAsync(command.OrderId, typeof(Order));
        order.Create(command.OrderId, command.CustomerId, command.Items,
                     command.ShippingAddress, command.BillingAddress);

        var events = order.GetUncommittedEvents();
        await _eventStore.AppendAsync(command.OrderId, events);
        await _publisher.PublishAsync(events);
    }
}

public class CreateOrderCommand
{
    public Guid OrderId { get; set; }
    public Guid CustomerId { get; set; }
    public List<OrderLineItem> Items { get; set; }
    public Address ShippingAddress { get; set; }
    public Address BillingAddress { get; set; }
}
```

## Aggregate Design

Aggregates are the consistency boundary. They enforce invariants and produce events.

```csharp
public abstract class AggregateRoot
{
    protected Guid Id { get; set; }
    private List<DomainEvent> _uncommittedEvents = new();
    protected int _version = 0;

    protected abstract void Apply(DomainEvent @event);

    public void LoadFromHistory(IEnumerable<DomainEvent> events)
    {
        foreach (var @event in events)
        {
            Apply(@event);
            _version++;
        }
    }

    protected void AddEvent(DomainEvent @event)
    {
        Apply(@event);
        _uncommittedEvents.Add(@event);
        _version++;
    }

    public IEnumerable<DomainEvent> GetUncommittedEvents() => _uncommittedEvents;
    public void ClearUncommittedEvents() => _uncommittedEvents.Clear();
}

public class Order : AggregateRoot
{
    public Guid CustomerId { get; private set; }
    public OrderStatus Status { get; private set; }
    public List<OrderLineItem> Items { get; private set; } = new();

    public void Create(Guid orderId, Guid customerId, List<OrderLineItem> items, ...)
    {
        if (items.Count == 0)
            throw new InvalidOperationException("Order must contain items");
        AddEvent(new OrderCreated(orderId, customerId, items, ...));
    }

    public void Confirm()
    {
        if (Status != OrderStatus.Pending)
            throw new InvalidOperationException("Only pending orders can be confirmed");
        AddEvent(new OrderConfirmed(Id));
    }

    protected override void Apply(DomainEvent @event)
    {
        switch (@event)
        {
            case OrderCreated e:
                Id = e.OrderId;
                CustomerId = e.CustomerId;
                Items = e.Items;
                Status = OrderStatus.Pending;
                break;
            case OrderConfirmed:
                Status = OrderStatus.Confirmed;
                break;
            case OrderShipped:
                Status = OrderStatus.Shipped;
                break;
        }
    }
}
```

## Aggregate Design Rules

- One aggregate per consistency boundary
- Aggregates reference other aggregates by ID only (never object references)
- Use optimistic concurrency (`_version`) to prevent lost updates
- Keep aggregates small — if an aggregate grows large, split into multiple aggregates
