# Agent Instructions: maintaining prompt-forge

This repository is the prompt-forge toolkit itself, not a project that uses it.
What users install lives in `template/`; everything else is documentation,
installers, and maintainer scripts.

## Layout

| Path | What it is |
|---|---|
| `template/` | Exactly what `install.sh` / `install.ps1` put into a project |
| `template/.agents/skills/` | **Source of truth** for the shipped skills |
| `template/.claude/skills/` | Generated copy for Claude Code. Never edit by hand |
| `template/.claude/agents/` | The `curate-lessons` subagent (Claude Code, also read by VS Code and Cursor) |
| `template/AGENTS.md` | The block merged into a project's `AGENTS.md`, between markers |
| `template/knowledge/` | The empty knowledge skeleton, including the team policy `README.md` |
| `install.sh`, `install.ps1` | Installers; keep their behavior identical |
| `scripts/` | Maintainer scripts: sync, validation, installer tests |
| `examples/` | A fictional registry showing the loop end to end |
| `architecture.md` | Decision record (ADRs). Add an ADR for any design change |

The shipped skills are not loaded natively in this repository. When a task
touches PowerShell, git, or skill authoring, read the matching file in
`template/.agents/skills/` yourself.

## After changing anything in `template/`

Run these from the repository root and fix what they report:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-template.ps1
powershell -ExecutionPolicy Bypass -File scripts/validate.ps1
powershell -ExecutionPolicy Bypass -File scripts/test-install.ps1
bash scripts/test-install.sh
```

`validate.ps1` measures each skill body (characters / 4, rounded to 0.1k). Copy
the measured value into `metadata.tokens` when it reports a mismatch.

## Rules

- Skills name capabilities, not one vendor's tool names ("the agent's file-edit
  tool", not `replace_string_in_file`). Concrete names only as examples.
- Every factual claim about a tool, spec, or study needs a primary source. Date
  claims that can go stale ("as of 2026-10").
- Installers must never overwrite a user's file. Add a test case to both
  `scripts/test-install.*` for any new behavior.
- Record user-visible changes in `CHANGELOG.md`.
- Conventional Commits, one logical change per commit. Branches:
  `feature/`, `fix/`, `docs/`, `chore/`, `refactor/`.

## Terminal on Windows

The maintainer shell is usually Windows PowerShell 5.1: no `&&` or `||`, check
`$LASTEXITCODE` after native commands, and write files containing `$` or `${{ }}`
with the file-edit tool rather than a here-string. From PowerShell, plain `bash`
starts WSL, not Git Bash; run the bash tests with
`& "C:\Program Files\Git\bin\bash.exe" scripts/test-install.sh`. The full set of
rules is in `template/.agents/skills/powershell-patterns/SKILL.md`.
