@AGENTS.md

## Claude Code

Claude Code discovers skills and subagents natively, so skip steps 1-3 of the
startup sequence above. In this repository the skills live in `.github/skills/`
(the source of truth), not `.claude/skills/` — read them explicitly when a task
matches. The `packages/claude/` distribution is the one laid out for native
discovery.

## Maintaining this repository

prompt-forge is the toolkit itself, not a host project using it.

- `.github/skills/`, `.github/agents/`, `AGENTS.md` and `knowledge/` at the root
  are the **source of truth**. Everything under `packages/` is generated.
- Run `.\sync-skills.ps1` after editing anything in those directories. Preview
  with `-WhatIf` first.
- Never edit a file under `packages/` directly for content that is synced — the
  next sync wipes it. Provider-specific files (`CLAUDE.md`, the Claude subagent
  definition) are the exception and are marked as such in the script.
- After changing a skill body, re-measure `metadata.tokens` (body characters
  divided by 4, rounded to 0.1k). The maintenance section of `architecture.md`
  has the script.
