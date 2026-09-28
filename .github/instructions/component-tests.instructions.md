---
description: 'Component test rules: test at the system boundary, fixture-centric style, in-memory infrastructure, full coverage of externally visible outcomes.'
applyTo: 'tests/**'
---

# Component tests

A component test exercises one deployable component end to end — HTTP endpoint, function trigger or
message handler, through the real dependency injection container, down to an in-memory database and
message bus. It needs no cloud resources. It is the main way to prove that a flow works.

For tests against a real environment, see `integration-tests.instructions.md`.

## Minimum coverage

- Every endpoint, trigger and message handler has at least one happy-path and one error-path
  component test.
- Every acceptance criterion is covered. Main paths go through component tests; state machines with
  many permutations may be covered by domain unit tests.
- **Every externally visible outcome has a component test.** When an error code or result type is
  part of a contract — it ends up in the database, in an outgoing message or in a metric — a unit
  test that only checks the returned value does not count as coverage. Add a component test that
  verifies every consequence of that outcome: the stored state, the outgoing message, the metric.
  Adding a new contract value means adding its component test in the same change.

## Test at the system boundary

A test that verifies a full outcome — a state change, a stored record, an outgoing message, a
metric — goes through the entry point: the endpoint or trigger resolved from the container. Never by
constructing a handler or service directly. The boundary is where wiring, serialisation and error
handling live; skipping it skips what breaks most often.

```csharp
// Yes: through the trigger, from the container
var trigger = fixture.GetRequiredService<OrderCancelledTrigger>();
await trigger.Run(message, messageActions);

// No: the handler in isolation
var handler = new CancelOrderCommandHandler(db);
await handler.Handle(command, CancellationToken.None);
```

Exception: a test may construct a class directly to verify one isolated technical aspect that is not
observable from outside (for example, that a logging scope is filled) — as long as it does not verify
the handler's business outcome. A fixture that is hard to extend is not a reason to skip the
boundary; extend the fixture.

## Fixture-centric style

- One fixture instance per test, disposed at the end (`using var fixture = ...` or
  `await using var fixture = ...`).
- The fixture builds a real service collection with the production registrations and replaces only
  external dependencies with fakes or in-memory versions.
- Arrange, act and assert go through **fixture methods** with readable names, so a test reads like a
  scenario:

  | Phase | Naming | Example |
  |---|---|---|
  | Arrange | `Given...`, `With...` | `GivenAnOpenOrder()`, `WithCustomer(id)` |
  | Act | `Run...Trigger`, `Call...` | `RunCancelOrderTrigger(orderId)` |
  | Assert | `Should...`, `Then...` | `ShouldPublishOrderCancelled(orderId)` |

- Drivers are stateless and come from the container; mutable test state lives in the fixture.
- No raw container code in test methods.

```csharp
[Test]
public async Task CancellingAnOpenOrderReleasesStock()
{
    // Arrange
    using var fixture = new OrdersFixture();
    var orderId = fixture.GivenAnOpenOrderWithReservedStock();

    // Act
    await fixture.RunCancelOrderTrigger(orderId);

    // Assert
    fixture.ShouldHaveOrderInStatus(orderId, OrderStatus.Cancelled);
    fixture.ShouldHaveReleasedStockFor(orderId);
    fixture.ShouldPublishOrderCancelled(orderId);
}
```

Use the bare labels `// Arrange`, `// Act`, `// Assert`, without text after them.

## Assert every consequence

Each test makes **all** relevant consequences of its action explicit, even when another test checks
some of them too. Component tests are living documentation: one test should show everything that
happens for that action, without reading other files. Overlap between tests is fine; duplication at
unit level is not.

Observable outcomes to assert on: status code and response body; messages sent and whether the
incoming message was completed or abandoned; stored state; blobs or cache; log entries (on a stable
part of the message, not full text); metrics; error responses with their problem details.

## In-memory infrastructure

- Database: SQLite in memory for speed; a shared local SQL Server with a reset tool when the code
  uses provider-specific features such as bulk operations. Tests on a shared database do not run in
  parallel.
- Message bus, blob storage, cache: in-memory fakes that record what was sent.
- Time: a fake time provider. Never assert on the real clock.
- No live cloud resources, no external HTTP.

## What not to mock

- **The domain.** If a test gets too complex, the domain logic may be in the wrong place.
- **The DbContext.** Use an in-memory provider.
- **The mediator or dispatcher.** Use the real one.
- **Internal handlers.** Test them through the boundary.

## Isolation

- No shared static state; every fixture is independent.
- Always generate IDs (`Guid.NewGuid()`); never hardcode them.
- Every message gets a unique message ID.
- `[OneTimeSetUp]` only for truly shared, immutable state.
- Arrange through drivers and messages rather than inserting rows directly, so tests do not depend on
  the storage schema. Reading state directly in the assert is acceptable when nothing external is
  observable.

## Test data

Use builders or factory methods, one per contract type, with fresh IDs by default.
