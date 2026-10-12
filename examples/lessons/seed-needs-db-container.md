---
title: The seed script assumes the local database container is already running
category: repo
scope: "scripts/seed.*"
fix: "Make the seed script check the database and print 'run make db-up' (proposed 2026-10-26)"
---

**Lesson:** Start the database with `make db-up` before running `pnpm seed`.

**Why:** The seed script connects to `<host>:5432` without starting anything and
fails with a connection-refused error that looks like a credentials problem.

## Sightings

- 2026-10-14 | @chen | feature/invoices | codex | seed failed; agent changed credentials before finding the cause
- 2026-10-22 | @ben | fix/tax-rounding | copilot | seed failed, connection refused
