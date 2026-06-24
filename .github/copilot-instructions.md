# prompt-forge — AI Agent Instructions

> This project uses `prompt-forge`, a drop-in toolkit that adds Agent Skills,
> an auto-improvement loop, and session tracking to any project.

## How prompt-forge Works Here

prompt-forge provides curated Agent Skills (agentskills.io standard) and an
auto-improvement loop that learns from coding sessions. No backend, no build
step — just Markdown skills and PowerShell scripts living alongside this
project's own code.

## Key Rules

### Skill Usage
- Skills live in `.github/skills/` — load them when their description matches
- Base skills (`explore-codebase`, `git-workflow`, `powershell-patterns`) apply
  to ALL work in this project
- Run `auto-improve` at the END of every significant iteration
- Run `track-tokens` when the user asks about cost or session stats

### Issue Registry
- Cross-session issue tracking lives in `knowledge/issues/`
- When you encounter an error, fix, or discovery, note it mentally
- `auto-improve` will formalize it after the session
- Issues with 3+ occurrences get promoted to skills or memory

### PowerShell (Windows)
- ALWAYS use `;` not `&&` for chaining
- NEVER use PowerShell heredocs (`@"..."@`) for files with `{{ }}`
- Use agent `create_file` / `replace_string_in_file` for Angular templates
- `nvm use X.Y.Z` after `nvm install` — it does NOT auto-activate

### Git
- Conventional Commits v1.0.0: `feat:`, `fix:`, `docs:`, `chore:`, etc.
- Atomic commits — one logical change per commit
- Branch naming: `feature/<name>`, `fix/<name>`, `docs/<name>`

### Codebase Exploration
- `get_errors()` FIRST before any code change
- Search before reading: `grep_search` → `semantic_search` → `file_search`
- Read 100+ lines at a time, parallel reads when possible
- NEVER read files one by one sequentially

## Directory Structure

```
.github/skills/         Agent Skills (loaded on demand by description match)
knowledge/issues/       Cross-session issue registry
scripts/                PowerShell utilities (session-start, session-end)
```

## After Each Session

1. Run `/auto-improve` to process learnings into the issue registry
2. If the user asks, run `/track-tokens` for cost summary
3. Commit changes to the issue registry and any updated skills
