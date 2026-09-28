---
description: 'Frontend rules for React with TypeScript: structure, typing, error handling, linting, comments and the split between unit and component tests.'
applyTo: 'ui/**'
---

# Frontend

The frontend is a React application in TypeScript.

## Structure

- Feature code lives in its feature folder; code used by more than one feature lives in `shared/`.
- Named exports everywhere.
- Absolute imports through the `@/` alias for `src/`.
- Routes are defined in one place.
- Configuration comes from environment variables; never hardcode secrets.

```
src/
  orders/            feature
    components/
    hooks/
    services/        API calls for this feature
    contracts/       request and response types
  shared/
    components/
    hooks/
    services/        API client
    utils/           pure helpers
```

Rule: used by one feature → feature folder. Otherwise → `shared/`.

## TypeScript

- **Never `any`.** Use `unknown` and narrow it with type guards.
- API request and response types live in a `contracts/` folder.
- Use `satisfies` for type-checked literals without widening.

## State

- Context providers only for truly global state: authentication, theme, feature flags.
- No context for server state; use a data-fetching library.

```tsx
const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
    const ctx = useContext(AuthContext);
    if (!ctx) throw new Error('useAuth must be used within AuthProvider');
    return ctx;
};
```

## Errors from the API

The backend returns `ProblemDetails` for errors. Turn them into a typed error in one place — the API
client — and show `detail` or `title` in the component.

```ts
if (!response.ok) {
    const problem: ProblemDetails = await response.json();
    throw new ApiError(problem.title, problem.status, problem.detail);
}
```

## Code style

- Follow the ESLint and Prettier configuration.
- **Run the linter after every change** and fix every problem before calling the work done.
- Do not silence floating promises with the `void` operator (static analysis such as SonarQube rule
  S3735 forbids it). Attach a `.catch(...)`, or use a small helper for deliberate fire-and-forget.
- No class components, no deprecated React APIs.

## Comments

- A comment means the code does not explain itself: first try a better name or an extracted
  function.
- If a comment is still needed, explain *why* in one line — never what the code already says.
- No trivial JSDoc, no commented-out code, no TODO without a work item.

## Tests

| Kind | Tool | What |
|---|---|---|
| Unit tests (`test/unit/`) | Vitest | Pure logic, hooks, services — no rendering |
| Component tests (`test/component/`) | Playwright | Component behaviour in a real browser |

Prefer many fast unit tests over a few slow browser tests. Component test rules are in
`frontend-component-tests.instructions.md`.

```ts
import { describe, it, expect } from 'vitest';
import { formatDateOnly } from '@/shared/dates/formatDateOnly';

describe('formatDateOnly', () => {
    it('formats a valid date', () => {
        expect(formatDateOnly('2024-03-15')).toBe('15-03-2024');
    });
});
```
