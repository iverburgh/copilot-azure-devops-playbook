---
description: 'Database project rules: changes that survive any deploy order, the three-PR column pattern, deployment safety settings, permission scripts, change data capture impact and generated files.'
applyTo: 'src/**/Database/**/*.sql'
---

# Database projects

The schema is owned by the database project (for example an SQL database project deployed as a
DACPAC), not by the ORM. Schema changes are made here; the ORM mapping follows.

## Core rules

- **The deploy order is not guaranteed.** The database may be deployed before or after the
  application, and the old and new application version may run side by side. Every pull request
  must therefore be backwards *and* forwards compatible: old code works on the new schema, new code
  works on the old schema.
- **Never combine schema, code and data migration in one pull request.**
- Separate aggregates or bounded contexts by schema; no foreign keys across aggregate boundaries.
- New columns are added at the end of the table. With table recreation disabled, the deployment
  cannot insert a column in the middle.
- **Never edit generated files** (for example migration runner scripts produced by a pre-build step).
- **Never edit data classification files by hand** when they are owned by data governance. When a
  schema change affects captured or classified columns, say so in the pull request, so the owners
  can update the classification.

## A new column on a table with data: three pull requests

1. **Schema:** add the column as nullable, with no NOT NULL, UNIQUE or CHECK constraint.
2. **Code:** read and write the column, and tolerate NULL wherever it is read.
3. **Data:** an idempotent migration that fills the column, ending with a check on the result (for
   example, count the rows that are still NULL and fail when there are any).

Only after that, in a later change, add NOT NULL and any UNIQUE or CHECK constraint. NOT NULL is safe
only when every row is filled *and* every running version of the code fills the column.

Removing or renaming a column runs the other way: first stop using it in code, and clean up the
schema in a later pull request.

Each pull request states its part ("part 2 of 3") and the merge order.

## Migrations

- Only when the declarative deployment cannot do it safely on its own: data conversions, renames,
  splitting columns, anything that would lose data. New tables, new columns and new non-unique
  indexes usually need no migration.
- One folder per migration, numbered with the next free integer and a short description:
  `48_AddRemarksToOrder`.
- Scripts are rerunnable: check before changing (`IF COL_LENGTH(...) IS NULL`).
- No `GO` batch separators inside migration scripts; use `sp_executesql` for statements that must
  run in their own batch.
- Build the database project after every change. SQL database projects often need MSBuild rather
  than `dotnet build`.
- Keep column descriptions or other schema metadata complete if the build enforces them.

## Deployment safety

Recommended publish settings for a declarative deployment:

| Setting | Value | Why |
|---|---|---|
| `BlockOnPossibleDataLoss` | True | A narrowing or dropping change fails instead of losing data |
| `AllowTableRecreation` | False | No silent table rebuilds that break change data capture and locks |
| `IgnoreColumnOrder` | True | Column order in source does not force a rebuild |
| `DropObjectsNotInSource` | True | The project is the single source of truth |

## Post-deployment permission scripts

Scripts that grant an application identity access (for example `GRANT EXECUTE` on a schema, a
procedure or a table type) run after every deployment.

- **One application identity can map to several database principals** — one per deployment slot, for
  example. Never pick one with `SELECT TOP 1`; grant to **every** matching principal.
- Find the matches in `sys.database_principals`, build the statements with `QUOTENAME` and
  `STRING_AGG`, and run them with `sp_executesql`.
- Idempotent: running the script twice changes nothing, and when no principal matches it does
  nothing.
- End with a check: when a matching principal still lacks the permission (look it up in
  `sys.database_permissions`), `THROW`, so the deployment fails instead of the application.
- Keep all permission scripts on the same pattern. Search for `TOP 1` in them now and then.
- A new procedure, schema or table type gets its grant in the same pattern, in the same pull request.

```sql
DECLARE @sql nvarchar(max);

SELECT @sql = STRING_AGG(
    CONVERT(nvarchar(max), N'GRANT EXECUTE ON SCHEMA::[orders] TO ' + QUOTENAME(name) + N';'), N' ')
FROM sys.database_principals
WHERE name LIKE N'app-orders%';

IF @sql IS NOT NULL
    EXEC sp_executesql @sql;
```

## Change data capture

When downstream consumers read changes through change data capture, every schema change has an
effect on the capture instances. Name it in the pull request.

| Change | Effect |
|---|---|
| Add a column | Capture instance unchanged; the column is invisible to consumers until it is added to the capture configuration, which recreates the capture instance |
| Drop a column that is not captured | No effect; a migration is still needed because of data loss |
| Drop a captured column | Capture instance keeps the column, delivering NULLs. Agree with consumers first |
| Stop capturing a column (reclassify) | Capture instance is recreated without it |
| Widen a column | No recreation; consumers may still need to widen their side |
| Narrow a column | Deployment blocks on possible data loss. Historic change data is not converted, so capture and source can drift apart |

Safest way to narrow a captured column:

1. Add a new column of the right type.
2. Let the application fill both.
3. Switch capture from the old column to the new one (this triggers a full load downstream).
4. Drop the old column.

A table with a primary key can only be captured if the key columns are captured too.

Dropping a captured table needs agreement with its consumers: disable capture in a controlled way,
empty the table, then remove it from the project.

## Quality

- Small changes, grouped per aggregate.
- Test a migration against a copy of an existing database, and verify both the migration and the
  declarative deployment.
