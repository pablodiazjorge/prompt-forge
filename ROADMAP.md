# Roadmap

Ordered by expected value. Nothing here is promised. Open an issue to argue for
or against an item.

## Next

- **Evaluation.** A small, reproducible benchmark: a sample repository with a
  recurring agent failure, measured with and without the promoted memory entry,
  across at least two agents. Until this exists, prompt-forge's benefit is a
  hypothesis.
- **Optional hooks for recording.** Deterministic reminders at the end of a turn
  for agents that support blocking stop hooks (Claude Code `Stop`, Codex `Stop`,
  Copilot `agentStop`, Cursor `stop`, Gemini CLI `AfterAgent`). They would be
  opt-in, shipped as snippets to merge rather than files that overwrite, and
  fire only after a tool failure. Hooks execute code on teammates' machines, so
  they need CODEOWNERS review and careful defaults.
- **A lint for `knowledge/`**: required fields, memory budgets, invisible
  Unicode, and obvious secrets, runnable in CI without dependencies.

## Later

- **Distribution channels**, once tested: `npx skills add` (which needs a direct
  tree URL for `template/.agents/skills`), `gh skill install` (public preview),
  and plugin marketplaces. These cover skills only. The `AGENTS.md` block and
  `knowledge/` still need the installer.
- **Import from built-in memory.** Help a person turn relevant entries from their
  own agent's memory into candidate lessons.
- **Kiro and other agent-specific skill directories**, as an installer option.

## Not planned

- A server, database, or hosted dashboard. Plain files in git are the point.
- Automatic promotion without review.
