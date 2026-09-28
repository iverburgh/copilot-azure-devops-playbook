---
description: 'Domain-driven design rules for the domain layer: value objects, entities, aggregates, domain events and domain services.'
applyTo: 'src/**/Domain/**, tests/**/Domain/**'
---

# Domain layer

The domain layer holds the business rules and nothing else: no infrastructure, no I/O, no framework
concerns. Persistence and external calls happen behind interfaces defined here and implemented
elsewhere.

## Value objects

- **Always immutable**: read-only properties, no setters.
- Validate every invariant in the constructor or a static factory (`Create`).
- Equality is based on all relevant values; use a `record` or override `Equals` and `GetHashCode`.
- No identity of their own — a value object is defined by its value.

## Entities

- Have a unique identity, usually an `Id`.
- Behaviour first, data second: state changes only through methods on the entity.
- Entities inside an aggregate are changed only through the **aggregate root**.
- Setters are `private` or `protected`. Guard invariants inside methods, not through setters.
- **Restrict visibility**: make methods or constructors `internal` when creation or mutation must go
  through an aggregate, a domain service or a factory.

## Aggregates

- A cluster of entities and value objects with one **aggregate root**; only the root is changed from
  outside.
- All business invariants of the cluster are enforced inside it.
- Expose behaviour through intention-revealing, imperative methods: `Approve()`, `Schedule()`,
  `Complete()` — not `SetStatus()`.
- Refer to other aggregates by ID only, never by object reference.
- The aggregate is consistent before it raises events.
- Make the constructor `internal` when only a factory or domain service may create it.
- If the ORM needs a parameterless constructor, make it `private` and suppress the nullable warning
  locally:

  ```csharp
  #pragma warning disable CS8618 // Required by the ORM
  private Order()
  #pragma warning restore CS8618
  {
  }
  ```

## Domain events

- Communicate meaningful state changes: something that just happened, in past tense
  (`OrderCancelled`).
- Immutable, and complete: all identifiers, timestamps and data a consumer needs.
- Consumers do not reconstruct missing identity through repository lookups, unless that is
  explicitly part of the design.
- Use events for side effects and for communication between components.

## Domain services

- Only when behaviour does not belong in a single entity or aggregate.
- Stateless and pure domain: take value objects or entities, return a domain result or event.

## Boundaries

- Keep models specific to their bounded context; do not share entities or value objects across
  contexts.
- Factories are fine for complex creation; they validate invariants too.
- Specification- and policy-like rules belong in domain services or value objects; query logic
  belongs in the application or infrastructure layer.
