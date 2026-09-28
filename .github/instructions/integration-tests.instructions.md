---
description: 'Integration test rules: when to write them at all, scenario structure, drivers and fixtures for tests against a real environment.'
applyTo: 'tests/Integration/**'
---

# Integration tests

Integration tests run several deployed components together in a real environment. They are slow,
need an environment and are harder to debug.

**Write component tests by default. Integration tests are the exception.** Write one only for:

- a new integration between two components over messaging;
- a new connection to an external system.

Do not write an integration test for behaviour a component test already covers.

## Scenarios

Written in domain language, from the user's perspective:

```gherkin
Feature: Order cancellation reaches invoicing
  Scenario: A cancelled order produces a credit note
    Given an invoiced order
    When the customer cancels the order
    Then a credit note is created for the invoiced amount
```

## Asynchronous assertions

Wait for the outcome with a timeout; never sleep for a fixed time.

```csharp
await driver.WaitForMessageAsync<CreditNoteCreated>(
    predicate: m => m.OrderId == orderId,
    timeout: TimeSpan.FromSeconds(30));
```

## Structure

- **Fixture**: neutral — only dependency injection, fakes and test stores shared across suites. No
  suite-specific concerns. Suite-specific overrides go in separate registration classes applied
  before resolving steps and drivers.
- **Steps**: named in domain language, one responsibility each. They use fixture stores but do not
  configure dependency injection.
- **Drivers**: the automation API — database, messaging, blob and trigger actions, plus small
  per-test state. Drivers never configure dependency injection and never assert.
- **Shared state** lives in a per-scenario context object, never in statics.
- Use placeholders for generated values (`<ORDER1>`) and resolve them through the scenario context,
  so scenarios stay readable and runs do not collide.
