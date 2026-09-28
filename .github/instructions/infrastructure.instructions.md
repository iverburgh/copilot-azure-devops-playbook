---
description: 'Infrastructure layer rules for EF Core: DbContext, save pipeline and domain events, entity configurations, conversions, owned types and test providers.'
applyTo: 'src/**/Infrastructure/**'
---

# Infrastructure layer

## DbContext

One `DbContext` per component, applying every configuration in its assembly:

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.ApplyConfigurationsFromAssembly(typeof(OrdersDbContext).Assembly);
    base.OnModelCreating(modelBuilder);
}
```

Never register entity configurations by hand.

## The save pipeline dispatches domain events

When the codebase overrides `SaveChangesAsync` (usually in a shared base context) to validate
aggregate state, dispatch domain events and set audit fields:

- always save through that override — never call the base implementation directly;
- never add extra logic to the override — use a domain event for the side effect instead.

## Entity configurations

One `IEntityTypeConfiguration<T>` per aggregate or entity:

```csharp
internal sealed class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> entity)
    {
        entity.ToTable("Order", Schemas.Orders);

        entity.Property(e => e.Status).HasConversion<string>().HasMaxLength(30);

        entity.OwnsOne(e => e.Total, total =>
        {
            total.Property(t => t.Amount).HasColumnName("TotalAmount");
            total.Property(t => t.Currency).HasColumnName("TotalCurrency").HasConversion<string>();
        });

        entity.Navigation(e => e.Lines).AutoInclude(false);
    }
}
```

## Configure only what differs from convention

```csharp
// Yes: differs from convention
entity.Property(e => e.Id).HasColumnName("OrderNumber");
entity.Property(e => e.Result).HasConversion<string>().HasMaxLength(50);

// No: identical to convention, pure noise
entity.Property(e => e.CustomerId).HasColumnName("CustomerId");
```

## Value object conversions

```csharp
entity.Property(e => e.Status).HasConversion<string>();

entity.Property(e => e.Reason)
    .HasConversion(v => v.Code, v => CancellationReason.FromCode(v));
```

Store enums as strings: numbers in a database are unreadable and break silently when the enum is
reordered.

## Owned types

- `OwnsOne` / `OwnsMany` for value objects, with their own table when needed.
- Use backing fields for private value objects.
- Set `AutoInclude(false)` on navigations and load them explicitly with `Include` where needed.

## Test providers

Component tests often run on SQLite in memory. Keep provider-specific configuration in one place:

```csharp
if (Database.IsSqlite())
{
    entity.Property(e => e.OrderNumber).HasValueGenerator<SequentialTestValueGenerator>();
}
else
{
    entity.Property(e => e.OrderNumber).UseIdentityColumn();
}
```

SQLite has no identity columns, no schemas and limited `DateTimeOffset` support; handle those
differences centrally, not per test.

## Schema changes

The ORM model follows the database, not the other way around, when the schema is owned by a
database project or migration tool. A mapping change without the matching schema change is
incomplete — the Database Engineer reviews both together.
