---
description: 'Guidelines for building C# applications'
applyTo: '**/*.cs'
---

<!-- Based on awesome-copilot's csharp.instructions.md (MIT), rewritten; see THIRD-PARTY-NOTICES.md. -->

# C#

## Core rules

- Use the latest C# language version the project targets.
- Make only high-confidence suggestions in code reviews.
- Write for maintainability: the next reader matters more than the next keystroke.

## Comments (Clean Code, chapter 4)

A comment is a workaround for code that does not explain itself, and it goes stale independently of
the code. Solve it in code first: extract a method, name a constant, remove duplication.

**Write only:** intent (*why* this choice), a warning about consequences, clarification of something
you cannot change (external behaviour), an explanation of deliberately missing code, and XML docs on
public APIs that are used outside the solution.

**Remove:** comments that repeat the code or the log line below them; noise (`// Constructor`); XML
docs added only because something is `public`; a specification that is implemented authoritatively
elsewhere (refer to it); paraphrases of a method name (rename the method); commented-out code;
closing-brace comments.

Rule of thumb in review: can the code say this itself? Then change the code and delete the comment.

## Naming

- PascalCase for types, methods and public members.
- camelCase for locals and parameters; `_camelCase` for private fields.
- Prefix interfaces with `I`.

## Formatting

- Follow `.editorconfig`.
- File-scoped namespaces and single-line `using` directives.
- Opening brace on a new line for every block.
- Pattern matching and switch expressions where they read better than `if` chains.
- `nameof` instead of string literals for member names.

## Nullable reference types

- Declare non-nullable by default and check for `null` at entry points.
- Use `is null` and `is not null`, never `== null` or `!= null`.
- Trust the annotations: do not add null checks where the type system says a value cannot be null.
- Avoid the null-forgiving operator (`!`) in production code; prefer nullable types and flow
  attributes such as `[NotNullWhen(true)]`, `[MaybeNullWhen(false)]` or `[MemberNotNull]`.

## Async and cancellation

- Follow CA1068: `CancellationToken` is always the last parameter.
- Apply it consistently to public APIs, interfaces, overrides and internal helpers.
- Reorder an existing signature only when all call sites can safely change in the same change.
- Pass the token all the way down; never replace it with `CancellationToken.None` halfway.

## Exceptions

- Custom exceptions have at least the three standard constructors: `()`, `(string message)` and
  `(string message, Exception innerException)`.
- Add domain-specific constructors only when the context does not fit in the message.
- Give extra properties safe defaults.
- Use exceptions for unexpected failures; use a result type for expected ones (not found,
  validation), if the codebase has one.

## Tests

- Always test critical paths.
- Copy the naming and structure of nearby tests.
- Use the mocking and assertion libraries the test project already uses; do not introduce another.
