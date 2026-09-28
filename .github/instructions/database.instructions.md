---
description: 'Database project rules: migrations, expand-and-contract, deployment safety settings, change data capture impact per schema change, and generated files.'
applyTo: 'src/**/Database/**/*.sql'
---

# Database projects

The schema is owned by the database project (for example an SQL database project deployed as a
DACPAC), not by the ORM. Schema changes are made here; the ORM mapping follows.

## Core rules

- **Every schema change is backwards compatible** with the code currently in production: the database
  is deployed before the application. Use expand and contract (see the `rep-protocol` skill).
- Separate aggregates or bounded contexts by schema; no foreign keys across aggregate boundaries.
- New columns are added at the end of the table. With table recreation disabled, the deployment
  cannot insert a column in the middle.
- A new non-nullable column needs a default, or a multi-step rollout: add nullable, fill, then
  tighten.
- **Never edit generated files** (for example migration runner scripts produced by a pre-build step).
- **Never edit data classification files by hand** when they are owned by data governance. When a
  schema change affects captured or classified columns, say so in the REP and the pull request, so
  the owners can update the classification.

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

## Change data capture

When downstream consumers read changes through change data capture, every schema change has an
effect on the capture instances. Name it in the REP.

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
