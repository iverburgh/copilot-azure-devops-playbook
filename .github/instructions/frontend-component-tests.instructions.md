---
description: 'Guidelines for writing Playwright component tests: file responsibilities, locator strategy and required coverage levels.'
applyTo: 'ui/test/component/**'
---

# Frontend component tests

## Folder structure

Organise tests the way users find the screens: **follow the navigation menu**. Read the navigation
definition before creating a test folder; the top-level menu item is the first folder, a child item
the subfolder (PascalCase, no spaces).

Each feature folder has: `<Name>.spec.tsx`, `Fixture.tsx`, `PageModel.ts`, `Driver.ts`, plus test data
builders in a shared folder.

## File responsibilities

| File | Responsibility | May contain | May not contain |
|---|---|---|---|
| **PageModel** | All locators and assertions | `getByRole`, `getByLabel`, `getByText`, `getByTestId`, `locator('#id')`, `shouldShow*` methods | CSS selectors, XPath, business logic |
| **Fixture** | Orchestrates Driver and PageModel | `with*()` → Driver, `shouldShow*()` → PageModel, `render()` | Locators, direct `page.*` calls |
| **Driver** | API mocks via `page.route()` | Typed `with*(data: T)` methods | Assertions, business logic |
| **TestDataBuilder** | Test data for one contract type | Fluent `with*()` per field, `build()` returning a copy | `Partial<T>`, inline literals, several types |
| **Spec** | Scenarios (arrange, act, assert) | Fixture methods, `test.describe`, `test` | `page.*` calls, locators, object literals |

- The PageModel receives only `Page`; locators are `readonly` properties.
- The Driver sets up mocks **before** `render()` and is typed on the exact contract — never `any` or
  `unknown`.
- One `test.describe` per spec file; no state shared outside a `test` block.

## Locator strategy

Read the component source for the exact `id`, `data-testid`, `aria-label`, text and role. **Never
guess.**

| Priority | Method | When |
|---|---|---|
| 1 | `page.locator('#id')` | The element has an `id` |
| 2 | `getByTestId()` | A `data-testid` exists |
| 3 | `getByRole()` with exact `name` | ARIA role with a stable accessible name |
| 4 | `getByLabel()` with exact text | Form field with a label |
| 5 | `getByRole()` with a regex `name` | Only when part of the name is dynamic and irrelevant |
| 6 | `getByText()` with exact text | Non-interactive elements |

Always match the full text, never a fragment. For dynamic names, add a PageModel method that takes a
parameter.

## Required coverage

A test that only proves elements are visible, without checking data, is **not enough**.

| Level | What | Required |
|---|---|---|
| 1 | Structure: title, buttons, inputs, default state — all initial elements in one test | Always |
| 2 | Interaction: filling in, clearing, validation messages, empty results | Always |
| 3 | Results: the **full content** of rows or cards | When data is shown |
| 4 | Detail views: expanding or opening shows the right data | When rows expand |
| 5 | Every search or filter type | When there are several |
| 6 | Outgoing request body, via `waitForRequest` | For every create or update |
