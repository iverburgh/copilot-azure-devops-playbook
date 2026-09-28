---
description: 'Application layer rules: thin command and query handlers, result types for expected failures, integration events after commit, and mapping.'
applyTo: 'src/**/Application/**'
---

# Application layer

## Core principle: handlers orchestrate, they hold no business logic

A command handler loads an aggregate, calls a domain method and saves. Business rules belong in the
domain layer. If a handler contains an `if` about business state, that rule probably belongs on the
aggregate.

## Command handlers

Commands change state.

```csharp
internal sealed class CancelOrderCommandHandler(OrdersDbContext db)
    : IRequestHandler<CancelOrderCommand, Result>
{
    public async Task<Result> Handle(CancelOrderCommand command, CancellationToken cancellationToken)
    {
        var order = await db.Orders.FindAsync([command.OrderId], cancellationToken);
        if (order is null)
        {
            return Result.Fail(new OrderNotFound(command.OrderId));
        }

        var cancelled = order.Cancel(command.Reason);
        if (cancelled.IsFailed)
        {
            return cancelled;
        }

        await db.SaveChangesAsync(cancellationToken);

        return Result.Ok();
    }
}
```

- Handlers are `internal` unless there is a reason to expose them.
- Always save through the unit of work that dispatches domain events (for example an overridden
  `SaveChangesAsync`); never bypass it.
- Return a failed result for expected failures (not found, rule violated); throw only for unexpected
  ones.
- Log the identifier of the entity being processed when a handler starts.

## Query handlers

Queries only read, and **never** change state.

```csharp
internal sealed class GetOpenOrdersQueryHandler(OrdersDbContext db)
    : IRequestHandler<GetOpenOrdersQuery, OrderSummaryDto[]>
{
    public async Task<OrderSummaryDto[]> Handle(GetOpenOrdersQuery query, CancellationToken cancellationToken)
    {
        return await db.Orders
            .Where(o => o.Status == OrderStatus.Open)
            .Select(o => new OrderSummaryDto(o.Id, o.CustomerId, o.Total))
            .ToArrayAsync(cancellationToken);
    }
}
```

- Project directly in the query (`Select`); do not load full aggregates to read three fields.
- No save calls in query handlers.

## Integration events

Messages to other components are published **after** the transaction commits — through an outbox or
a handler that buffers domain events until the save succeeded. Publishing before the commit sends
messages about changes that may still roll back.

- Map a domain event to an integration message in one place per event.
- The message carries every identifier the consumer needs; consumers do not look them up again.
- Consumers are idempotent: the same message may arrive more than once.

## Mapping

- Mapping between domain objects and DTOs lives in this layer, never in the domain or
  infrastructure layer.
- Keep mapping profiles small, one per aggregate or use case, and cover them with a configuration
  validation test if the mapping library supports it.

## Naming

| Type | Pattern | Example |
|---|---|---|
| Command | `<Action><Aggregate>Command` | `CancelOrderCommand` |
| Query | `Get<What>Query` | `GetOpenOrdersQuery` |
| Handler | `<CommandOrQuery>Handler` | `CancelOrderCommandHandler` |
| Integration event handler | `<Event>IntegrationEventHandler` | `OrderCancelledIntegrationEventHandler` |

## Folder layout

```
src/<Component>/Application/
  <Aggregate>/
    <Action><Aggregate>Command.cs
    <Action><Aggregate>CommandHandler.cs
    Get<What>Query.cs
    Get<What>QueryHandler.cs
  Mapping/
  DependencyInjection.cs
```
