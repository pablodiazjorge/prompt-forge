---
name: auto-improve
description: |
  Post-session learning loop. Use at the END of every coding iteration or when
  the user says "analyze this session", "what did we learn", "save lessons",
  or "run auto-improve". Reviews the chat for errors, fixes, API discoveries,
  and patterns. Cross-references with the issue registry to detect recurrence.
  Promotes confirmed patterns to user memory, repo memory, or new skills.
  NEVER invoke mid-task — only at natural stopping points.
disable-model-invocation: false
license: MIT
metadata:
  author: pablodiazjorge
  url: https://github.com/pablodiazjorge/prompt-forge
  version: "1.0"
  tokens: "0.4k"
---

# Auto-Improve (Legacy Wrapper)

> **⚠️ This skill has been split into two specialized roles.**
> It is retained for backward compatibility with existing references.
> New sessions should use the individual skills directly.

## What Changed

The original `auto-improve` skill combined two distinct responsibilities into
one monolithic workflow. It has been split into:

| Role | Skill | When Loaded | What It Does |
|------|-------|-------------|--------------|
| **Developer** | `developer/SKILL.md` | By default (always) | Phases 1-3: scan chat → create/update issues in `open/`. NEVER promotes or touches skills. |
| **AI Engineer** | `ai-engineer/SKILL.md` | On demand (subagent) | Phases 4-6 + dedup + recategorization: review ALL issues → deduplicate → recategorize → promote to skills/memories → clean stale entries. |

## How to Use

- **Everyday tracking**: The `developer` skill is loaded by default. It runs at
  the end of every iteration, recording issues in `knowledge/issues/open/`. You
  don't need to do anything — it works automatically.

- **Knowledge cleanup**: When you want to organize accumulated issues, run the
  `ai-engineer` skill as a subagent. It will review all issues, deduplicate,
  recategorize, and promote confirmed patterns.

If you're reading this because an old reference triggered `auto-improve`, the
agent will automatically redirect to `developer` for the current session's
tracking needs. For promotion and cleanup, invoke `ai-engineer` explicitly.
