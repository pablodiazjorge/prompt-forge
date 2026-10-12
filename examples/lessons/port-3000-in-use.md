---
title: Dev server fails to start because port 3000 is already in use
category: tooling
---

**Lesson:** If `pnpm dev` reports that the port is in use, stop the previous dev
server process instead of changing the configured port.

**Why:** A dev server from an earlier session was still running in the
background.

## Sightings

- 2026-10-13 | @chen | feature/invoices | codex | EADDRINUSE on start
- 2026-10-15 | @chen | feature/invoices | codex | EADDRINUSE on start
- 2026-10-20 | @chen | fix/pdf-export | codex | EADDRINUSE on start
- 2026-10-23 | @chen | fix/pdf-export | codex | EADDRINUSE on start
