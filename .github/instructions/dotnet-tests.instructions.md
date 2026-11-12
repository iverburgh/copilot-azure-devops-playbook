---
description: 'Rules for all .NET unit and component tests: test at the system boundary, fixture with Arrange and Assert helpers, every contract value covered, assert every consequence, in-memory infrastructure.'
applyTo: 'tests/**, **/*Tests/**'
---

# .NET tests

These rules apply to every .NET test project — unit tests and component tests alike. The aim is tests
that read like a scenario, prove one new thing each, and keep working when the implementation
underneath is refactored.

- A **component test** exercises one deployable component end to end — HTTP endpoint, function
  trigger or message handler — through the real dependency injection container, down to an in-memory
  database and message bus. It needs no cloud resources. It is the main way to prove that a flow
  works.
- A **unit test** covers pure logic: domain entities, value objects, calculations, parsers. No
  container, no database.

For tests against a real environment, see `integration-tests.instructions.md`.

## Before you add a test

- **Search the existing fixtures first.** Extend the fixture and test class that already cover the
  component before adding a new one. A second fixture for the same component drifts from the first.
- **A new test must prove something new.** If an existing test already shows the behaviour, extend
  its asserts instead of adding a near-copy.
- **Run the smallest set first**: the one test, then its class, then its project. Run broader suites
  only when shared test infrastructure or cross-cutting code changed.

## Minimum coverage

- Every endpoint, trigger and message handler has at least one happy-path and one error-path
  component test.
- Every acceptance criterion is covered. Main paths go through component tests; state machines with
  many permutations may be covered by domain unit tests.
- **Every contract value has a test at the entry point.** When an enum value — an error code, a result
  type, a status — is part of a contract because it ends up in the database, in an outgoing message or
  in a metric, it needs a test that triggers it through the entry point and verifies **every**
  consequence: the stored state, the outgoing message, the metric. A test that checks one consequence
  out of three is incomplete. A unit test that only checks the returned value does not count.
- Adding a new contract value means adding its test in the same change.
- Internal guards that never produce a contract value (for example, an argument check that throws
  before anything happens) are exempt.

## Test at the system boundary

A test that verifies an outcome — a state change, a stored record, an outgoing message, a metric —
goes through the entry point: the endpoint or trigger resolved from the container. Never by
constructing a handler or service directly with mocks. The boundary is where wiring, serialisation and
error handling live; skipping it skips what breaks most often.

This applies in **every** test project, not only the one named "component tests". A unit test project
that news up a handler with five mocks is a component test without the component.

```csharp
// Yes: through the trigger, from the container
var trigger = fixture.GetRequiredService<OrderCancelledTrigger>();
await trigger.Run(message, messageActions);

// No: the handler in isolation, with mocks
var handler = new CancelOrderCommandHandler(dbMock.Object, busMock.Object);
await handler.Handle(command, CancellationToken.None);
```

Exception: a test may construct a class directly to verify one isolated technical aspect that is not
observable from outside (for example, that a logging scope is filled) — as long as it does not verify
the handler's outcome. **Code that is hard to reach is not a reason to skip the boundary; extend the
fixture.** Pure logic without dependencies belongs in a domain unit test, not in a handler test.

Error paths go through the entry point too:

```csharp
// Act
var act = () => fixture.RunCancelOrderTrigger(unknownOrderId);

// Assert
await act.Should().ThrowAsync<OrderNotFoundException>().WithMessage("*not found*");
```

## Fixture with Arrange and Assert helpers

- One fixture instance per test, disposed at the end (`using var fixture = ...` or
  `await using var fixture = ...`).
- The fixture exposes the act methods directly and groups the rest in two helper objects:
  `fixture.Arrange` for setup and `fixture.Assert` for verification.
- Test methods contain **no** mock `Setup` or `Verify` calls, no raw SQL, no feature flag setup and no
  container code. Each of those goes into a named method on `fixture.Arrange` or `fixture.Assert`, so
  the test states *what* and the fixture knows *how*. Mock fields stay internal to the fixture.
- Repeated exception asserts and repeated expected values also become named assert methods, so a
  change in the expectation is made once.

  | Phase | Lives on | Naming | Example |
  |---|---|---|---|
  | Arrange | `fixture.Arrange` | `Given...`, `With...` | `GivenAnOpenOrder()`, `WithStockLevel(sku, 5)` |
  | Act | `fixture` | `Run...Trigger`, `Call...` | `RunCancelOrderTrigger(orderId)` |
  | Assert | `fixture.Assert` | `Should...` | `ShouldPublishOrderCancelled(orderId)`, `ShouldPublishNoStockMetrics()` |

```csharp
[Test]
public async Task CancellingAnOpenOrderReleasesStock()
{
    // Arrange
    using var fixture = new OrdersFixture();
    var orderId = fixture.Arrange.GivenAnOpenOrderWithReservedStock();

    // Act
    await fixture.RunCancelOrderTrigger(orderId);

    // Assert
    fixture.Assert.ShouldHaveOrderInStatus(orderId, OrderStatus.Cancelled);
    fixture.Assert.ShouldHaveReleasedStockFor(orderId);
    fixture.Assert.ShouldPublishOrderCancelled(orderId);
}
```

Use the bare labels `// Arrange`, `// Act`, `// Assert`, without text after them.

## Feature toggles

- Run a test class for both toggle states with parameterised fixtures, for example
  `[TestFixture(false)]` and `[TestFixture(true)]`, instead of copying the class.
- A test that only makes sense in one state skips the other with `Assume.That(...)`, so it reports
  as inconclusive rather than passing silently.
- Test both paths of every toggle until the toggle is removed.

## Dependency injection in the fixture

- Build a real `ServiceCollection` through the **same extension methods production uses** to register
  services. Do not start the host or `Program`; do not hand-register what production registers.
- Replace only external dependencies — database, message bus, HTTP clients, clock — with fakes or
  in-memory versions.
- Build the provider once per fixture. Rebuild it only when a registration changes during Arrange.
- No shared static mutable state between fixtures.

## Assert every consequence

Each test makes **all** relevant consequences of its action explicit, even when another test checks
some of them too. Tests are living documentation: one test should show everything that happens for
that action, without reading other files. Overlap between tests is fine; duplicated setup code is not
— that belongs in the fixture.

Observable outcomes to assert on: status code and response body; messages sent and whether the
incoming message was completed or abandoned; stored state; blobs or cache; log entries; metrics;
error responses with their problem details.

- **Logging:** assert on a stable core of the message — `Contains`, a prefix or a regular expression —
  never the full text, so rewording a log line does not break the test.
- **Time:** use a fake time provider (`FakeTimeProvider`) and assert on its value. Never compare with
  `DateTime.Now` or `DateTime.UtcNow`.

## In-memory infrastructure

- Database: SQLite in memory for speed; a shared local SQL Server with a reset tool when the code
  uses provider-specific features such as bulk operations. Tests on a shared database do not run in
  parallel.
- Message bus, blob storage, cache: in-memory fakes that record what was sent.
- No live cloud resources, no external HTTP.

## What not to mock

- **The domain.** If a test gets too complex, the domain logic may be in the wrong place.
- **The DbContext.** Use an in-memory provider.
- **The mediator or dispatcher.** Use the real one.
- **Internal handlers.** Test them through the boundary.

## Isolation

- Every fixture is independent; no shared static state.
- Always generate IDs (`Guid.NewGuid()`); never hardcode them.
- Every message gets a unique message ID.
- No broad `[OneTimeSetUp]` for state that tests change; use it only for truly shared, immutable
  state.
- Arrange through drivers and messages rather than inserting rows directly, so tests do not depend on
  the storage schema. Reading state directly in the assert is acceptable when nothing external is
  observable.

## Test data

Use builders or factory methods, one per contract type, with fresh IDs by default.

## Unit tests

- Cover pure logic: invariants of entities and value objects, calculations, parsing, state
  transitions. One behaviour per test, named after the behaviour
  (`CancellingAShippedOrderIsRejected`), with the same `// Arrange`, `// Act`, `// Assert` labels.
- Construct the class under test directly — that is the point of a unit test — but only for classes
  without infrastructure dependencies. Once a class needs mocks to be tested, test it at the boundary
  instead.
- Use parameterised tests (`[TestCase]`) for permutations instead of copies.
- Do not unit-test what a component test already proves end to end, and do not write tests that only
  restate the implementation, check constants or exercise the framework.

## Avoid

- `new SomeHandler(...)` in tests.
- Mock `Setup`/`Verify`, raw SQL or feature flag setup inside test methods.
- A test that checks one consequence of a contract value and ignores the others.
- `DateTime.Now` in asserts, full log messages in asserts.
- Broad `[OneTimeSetUp]` for mutable state, static state shared between tests.
- A new fixture class when an existing one can be extended.
