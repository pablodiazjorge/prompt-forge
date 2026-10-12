---
title: The API client is generated from api/openapi.yaml and committed, so edits to the schema need a regeneration
category: repo
scope: "api/openapi.yaml"
---

**Lesson:** After editing `api/openapi.yaml`, run `make gen` and commit the
regenerated files under `src/generated/`.

**Why:** CI type-checks the committed client but never regenerates it, so a
schema change without `make gen` fails with type errors far from the cause.

## Sightings

- 2026-10-13 | @ana | feature/invoice-export | claude-code | type errors in src/billing after adding a schema field
- 2026-10-16 | @ben | fix/tax-rounding | copilot | CI failed on a renamed schema property
- 2026-10-21 | @ana | feature/credit-notes | claude-code | agent hand-edited src/generated/ instead of regenerating
