# CQRS Read Side — Queries, Read Models & Eventual Consistency

## Queries

Queries retrieve state without modification. Handlers read from optimized read models.

**Query Characteristics**

- Passive: retrieve state only, no invariant enforcement
- Read from denormalized models optimized for specific access patterns
- Can cache results aggressively

```csharp
public class GetOrderHandler : IQueryHandler<GetOrderQuery, OrderDetailsDto>
{
    private readonly IReadModelRepository<OrderDetailsDto> _readModelRepo;

    public async Task<OrderDetailsDto> HandleAsync(GetOrderQuery query)
    {
        var order = await _readModelRepo.GetByIdAsync(query.OrderId);
        if (order == null)
            throw new OrderNotFoundException(query.OrderId);
        return order;
    }
}

// Denormalized read model (optimized for query access)
public class OrderDetailsDto
{
    public Guid OrderId { get; set; }
    public Guid CustomerId { get; set; }
    public DateTime CreatedAt { get; set; }
    public OrderStatus Status { get; set; }
    public decimal Total { get; set; }
    public List<OrderLineItemDto> Items { get; set; }
    public ShippingDetailsDto ShippingDetails { get; set; }
}
```

## Event Subscribers — Read Model Update

Read models are updated by event handlers, creating eventual consistency.

```csharp
public class OrderDetailsReadModelUpdater : IEventSubscriber
{
    private readonly IReadModelRepository<OrderDetailsDto> _repository;

    public async Task OnEventAsync(DomainEvent @event)
    {
        switch (@event)
        {
            case OrderCreated e:
                await _repository.CreateAsync(new OrderDetailsDto
                {
                    OrderId = e.OrderId,
                    CustomerId = e.CustomerId,
                    CreatedAt = e.CreatedAt,
                    Status = OrderStatus.Pending,
                    Items = e.Items.Select(i => new OrderLineItemDto { ... }).ToList(),
                });
                break;
            case OrderConfirmed e:
                var order = await _repository.GetByIdAsync(e.OrderId);
                order.Status = OrderStatus.Confirmed;
                await _repository.UpdateAsync(order);
                break;
            case OrderShipped e:
                var orderToShip = await _repository.GetByIdAsync(e.OrderId);
                orderToShip.Status = OrderStatus.Shipped;
                orderToShip.TrackingNumber = e.TrackingNumber;
                await _repository.UpdateAsync(orderToShip);
                break;
        }
    }
}
```

## Event Bus / Message Broker

Events are published to a message broker for asynchronous, decoupled delivery.

```csharp
public interface IMessagePublisher
{
    Task PublishAsync(IEnumerable<DomainEvent> events);
    Task SubscribeAsync<T>(IEventSubscriber subscriber) where T : DomainEvent;
}
```

## Handling Eventual Consistency

Because read models update asynchronously, there is a window where they lag the write model.

**Strategies**

1. **Accept staleness** — for many queries, slight lag is acceptable
2. **Client-side TTL caching** — cache read results with short TTL
3. **Polling with backoff** — client polls until consistency is achieved

```csharp
public async Task WaitForConsistencyAsync(Guid orderId, Func<OrderDetailsDto, bool> condition)
{
    var maxAttempts = 10;
    var delayMs = 100;

    for (int i = 0; i < maxAttempts; i++)
    {
        var dto = await _queryHandler.HandleAsync(new GetOrderQuery { OrderId = orderId });
        if (condition(dto))
            return;

        await Task.Delay(delayMs);
        delayMs = Math.Min(delayMs * 2, 5000); // Exponential backoff, max 5s
    }

    throw new ConsistencyTimeoutException("Read model did not reach expected state");
}
```
