# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-10-12

A redesign for teams. See [docs/upgrading.md](docs/upgrading.md) before
upgrading from 1.x.

### Added

- `install.sh` and `install.ps1`. They merge into an existing project without
  overwriting anything, support `--upgrade`, `--dry-run`, `--skip-claude`, and
  `--skip-gemini`, and report 1.x leftovers. Both are covered by tests that run
  in CI on Linux, macOS, and Windows (PowerShell 5.1 and 7).
- `knowledge/lessons/`: one file per lesson, with an append-only `Sightings`
  list (date, reporter, branch, agent). Counts are derived from it, so parallel
  branches no longer lose increments in merges.
- `knowledge/README.md`: the team's policy (thresholds, budgets, cadence), which
  the curator reads and upgrades never overwrite.
- A promotion ladder: fix the code, then add a check, then write memory, then
  create a skill.
- Memory budgets, `review after` dates, and a retirement path for wrong entries
  (`contradicts:`).
- Redaction and anti-injection rules for recording and curation.
- `AGENTS.md` now tells agents to read the `knowledge/memory/` files that match
  their task. In 1.x nothing read promoted memory.
- `GEMINI.md` import shim for Gemini CLI.
- Docs: [team-vs-solo](docs/team-vs-solo.md), [team-setup](docs/team-setup.md),
  [comparison](docs/comparison.md), [known-issues](docs/known-issues.md),
  [upgrading](docs/upgrading.md). A worked [example](examples/README.md).
- CI: skill frontmatter and token validation, template drift check, link check,
  and installer tests.

### Changed

- **Breaking:** `developer` is renamed `record-lesson`. It is no longer loaded
  every session; agents run it at checkpoints (before a commit or pull request,
  or when finishing a task), and it applies an admission test first.
- **Breaking:** `ai-engineer` is renamed `curate-lessons`. It works on a branch
  and ends with a report for a pull request. Merging the pull request is the
  approval, so the in-chat confirmation and the "always auto-promote" escape
  hatch are gone. It no longer edits the skills that prompt-forge ships.
- **Breaking:** promotion requires two or more distinct reporters instead of
  three occurrences of any kind. Lessons from a single reporter are held unless a
  person fast-tracks them.
- **Breaking:** one installer replaces the per-agent packages
  (`packages/copilot`, `packages/claude`, and `packages/custom` in 1.0.0).
  Skills now live in `.agents/skills/`, read by Codex, Copilot, VS Code, Cursor,
  Gemini CLI, and others, with a generated copy in `.claude/skills/` for Claude
  Code.
- The shipped `AGENTS.md` is a short block between markers. The Git and Windows
  terminal rules moved into the `git-workflow` and `powershell-patterns` skills.
- `git-workflow`: rewritten around non-interactive git (it previously
  recommended `git add -p`, which hangs an agent shell). It now attributes
  commit types correctly (the Conventional Commits specification defines only
  `feat` and `fix`) and defers to the team's own commitlint configuration.
- `powershell-patterns`: corrected the 5.1 encoding table (`Out-File` writes
  UTF-16LE), the execution policy defaults, and the version-manager section.
  Added the 7.3 native-argument change, the 7.2 and 7.4 stderr and
  error-handling changes, a better `--%` example, and a warning that plain `bash`
  in PowerShell usually starts WSL rather than Git Bash. It no longer suggests
  persisting an execution policy change.
- Skill frontmatter now passes the Agent Skills specification. Only
  `curate-lessons` uses the `disable-model-invocation` client extension.

### Removed

- **Breaking:** `explore-codebase`. Its token-savings figure had no source and
  current agents explore well natively.
- **Breaking:** `skill-creator`. Its guidance, corrected against the
  specification, is now `curate-lessons/references/writing-skills.md`. The name
  also clashed with skills that Anthropic and Codex ship.
- **Breaking:** `knowledge/issues/` with `INDEX.md` and the `open/`,
  `promoted/`, and `discarded/` folders.
- The DeepSeek workaround. It relied on a VS Code setting that does not exist.
  The underlying extension bug is described in
  [docs/known-issues.md](docs/known-issues.md).
- **Breaking:** the `track-tokens` skill and the `scripts/session-start.ps1` /
  `scripts/session-end.ps1` scripts. Agents do not reliably expose token counts.
- `.github/copilot-instructions.md` and `.github/instructions/default.instructions.md`,
  replaced by the `AGENTS.md` block.
- `sync-skills.ps1`, replaced by `scripts/sync-template.ps1`.

## [1.0.0] - 2026-06-27

Initial release: Agent Skills, an issue registry, and per-provider packages for
Copilot, Claude Code, and custom setups.

[2.0.0]: https://github.com/pablodiazjorge/prompt-forge/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/pablodiazjorge/prompt-forge/releases/tag/v1.0.0
