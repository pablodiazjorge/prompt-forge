# Known issues

Per-tool caveats, as of October 2026. Each links to the source that documents
the behavior.

## Skills listed twice

prompt-forge installs the same skills in `.agents/skills/`, which most agents
read, and in `.claude/skills/`, the only project location
[Claude Code reads](https://code.claude.com/docs/en/skills). Several tools read
both:

- VS Code and GitHub Copilot:
  [`.github/skills`, `.claude/skills`, `.agents/skills`](https://code.visualstudio.com/docs/agent-customization/agent-skills).
  Which copy wins when two locations hold a skill with the same name is not
  documented.
- Cursor: [`.agents/skills`, `.claude/skills`, and others](https://cursor.com/docs/skills).
- [OpenCode](https://opencode.ai/docs/skills/) and
  [Amp](https://ampcode.com/docs/customize/skills) read both as well. Amp can
  turn off the `.claude` path with `amp.skills.disableClaudeCodeSkills`.

The copies are byte-identical (CI checks this), so a duplicate costs only its
listing, about 100 tokens per skill. If nobody on the team uses Claude Code,
install with `--skip-claude` and the duplication disappears.

## Claude Code and `AGENTS.md`

Claude Code reads a root `AGENTS.md` natively
[since v2.1.277](https://code.claude.com/docs/en/memory#agents-md), but only when
the project has no `CLAUDE.md`, `CLAUDE.local.md`, or `.claude/CLAUDE.md`. The
installer therefore adds an `@AGENTS.md` import to `CLAUDE.md`, which works in
every version and, per the same page, never makes Claude read `AGENTS.md` twice.

## Claude Code subagents cannot ask questions

Subagents in Claude Code
[do not have the AskUserQuestion tool](https://code.claude.com/docs/en/sub-agents),
even when it is listed. The `curate-lessons` subagent is written for that: it
never asks mid-run, lists open questions under "Needs a decision" in its report,
and leaves approval to the pull request.

## Gemini CLI

Gemini CLI reads `GEMINI.md`, not `AGENTS.md`, by default. The installer adds an
`@AGENTS.md` import to `GEMINI.md`, which
[Gemini CLI supports](https://geminicli.com/docs/cli/gemini-md/). Alternatively,
set `context.fileName` to include `AGENTS.md` in `.gemini/settings.json` and
install with `--skip-gemini`.

## Zed, Kiro, Devin Desktop, Aider

- [Zed](https://zed.dev/docs/ai/instructions) uses only the first instruction
  file it finds: `.rules`, `.cursorrules`, `.windsurfrules`, `.clinerules`,
  `.github/copilot-instructions.md`, and `AGENT.md` all take priority over
  `AGENTS.md`. Its [skills](https://zed.dev/docs/ai/skills) load from
  `.agents/skills/`.
- [Kiro](https://kiro.dev/docs/skills/) reads `AGENTS.md` but loads skills only
  from `.kiro/skills/`. Copy the skill directories there by hand.
- Windsurf is now Devin Desktop, whose agent (Devin Local) reads `AGENTS.md`
  and [`.agents/skills/`](https://docs.devin.ai/cli/extensibility/skills/overview).
- [Aider](https://aider.chat/docs/usage/conventions.html) reads `AGENTS.md` only
  when configured: add `read: AGENTS.md` to `.aider.conf.yml`. It does not
  support Agent Skills.

## DeepSeek V4 for Copilot Chat

The `Vizards.deepseek-v4-for-copilot` extension sends system messages to the
model with the user role
([issue #90](https://github.com/Vizards/deepseek-v4-for-copilot/issues/90), open
as of October 2026). `AGENTS.md` content still arrives, but with lower priority
than intended.

prompt-forge 1.x documented a workaround based on a `github.copilot.chat.instructions`
setting. That setting does not exist, so the workaround has been removed. There
is no verified workaround; follow the issue for a fix.

## Sources for the coverage table

Checked against each tool's documentation in October 2026.

| Agent | Instructions | Skills | Subagents |
|---|---|---|---|
| Claude Code | [memory](https://code.claude.com/docs/en/memory#agents-md) | [skills](https://code.claude.com/docs/en/skills) | [subagents](https://code.claude.com/docs/en/sub-agents) |
| VS Code / Copilot | [custom instructions](https://code.visualstudio.com/docs/agent-customization/custom-instructions) | [agent skills](https://code.visualstudio.com/docs/agent-customization/agent-skills) | [custom agents](https://code.visualstudio.com/docs/agent-customization/custom-agents) |
| Codex | [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md) | [skills](https://learn.chatgpt.com/docs/build-skills) | n/a |
| Cursor | [rules](https://cursor.com/docs/rules) | [skills](https://cursor.com/docs/skills) | [subagents](https://cursor.com/docs/subagents) |
| Gemini CLI | [GEMINI.md](https://geminicli.com/docs/cli/gemini-md/) | [skills](https://geminicli.com/docs/cli/skills/) | n/a |
| OpenCode | [rules](https://opencode.ai/docs/rules/) | [skills](https://opencode.ai/docs/skills/) | n/a |
| Amp | [AGENTS.md](https://ampcode.com/docs/customize/agents-md) | [skills](https://ampcode.com/docs/customize/skills) | n/a |
| Junie | [guidelines](https://junie.jetbrains.com/docs/guidelines-and-memory.html) | [skills](https://junie.jetbrains.com/docs/agent-skills.html) | n/a |
| Devin Desktop | [AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md) | [skills](https://docs.devin.ai/cli/extensibility/skills/overview) | n/a |
| Zed | [instructions](https://zed.dev/docs/ai/instructions) | [skills](https://zed.dev/docs/ai/skills) | n/a |
| Kiro | [steering](https://kiro.dev/docs/steering/) | [skills](https://kiro.dev/docs/skills/) | n/a |
| Aider | [conventions](https://aider.chat/docs/usage/conventions.html) | n/a | n/a |
