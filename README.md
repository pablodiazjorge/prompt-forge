# prompt-forge

A drop-in toolkit that adds Agent Skills and a learning loop to any software
project. Copy the files in and your AI coding agent gets smarter with every
session. No dependencies, no build step, no backend.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Why prompt-forge Exists

AI coding agents are powerful but stateless. They enter each session with the
same baseline knowledge and make the same mistakes across sessions and across
developers. A team of five engineers might independently discover the same
PowerShell pitfall, the same breaking change in a dependency, and the same
inefficient codebase exploration pattern -- each paying the token cost to debug
it from scratch.

prompt-forge solves this by giving the agent a memory. It captures recurring
errors, API changes, and workarounds as structured issues. When a pattern
surfaces three times, it is promoted to a permanent skill or memory file that
all future sessions benefit from automatically.

The architecture is designed around five principles:

| Principle | Implication |
|-----------|-------------|
| Zero runtime dependencies | Works in any project without npm, pip, or any package manager |
| Host-project safety | Never interferes with build systems, linters, or existing `.gitignore` rules |
| Progressive disclosure | Skills cost ~100 tokens at discovery time; full instructions load only when triggered |
| Git-native persistence | The issue registry is a directory of Markdown files -- diffable, mergeable, version-controlled |
| Agent-agnostic | Skills name capabilities, not vendor tool names, and instructions live in `AGENTS.md` |

For a detailed rationale behind every architectural decision, see
[architecture.md](architecture.md).

---

## What You Get

Six Agent Skills following the [agentskills.io](https://agentskills.io)
standard, a cross-session issue registry, an `AGENTS.md` instruction file, and a
knowledge-curation subagent.

### Skills

| Skill | Triggers when | Body tokens |
|-------|---------------|-------------|
| `developer` | End of iteration; "analyze this session" | 1.2k |
| `ai-engineer` | On-demand; "organize knowledge", "promote patterns" | 1.8k |
| `explore-codebase` | "Where is X?"; "How does Y work?" | 0.8k |
| `git-workflow` | Committing, branching, reviewing PRs | 0.5k |
| `powershell-patterns` | Terminal commands and `.ps1` scripts on Windows | 1.2k |
| `skill-creator` | Creating or fixing Agent Skills; ai-engineer promotion target | 2.3k |

Discovery overhead across all six is roughly 600 tokens per session. Bodies load
only when the conversation matches the skill's description. Only `developer` is
loaded eagerly at startup.

### Issue Registry

A filesystem-based knowledge base at `knowledge/issues/`. Each issue is a
Markdown file with YAML frontmatter. Issues progress through three states:

```
open/         Detected but not yet confirmed as a pattern
promoted/     Confirmed (3+ occurrences) and encoded into a skill or memory
discarded/    Single occurrence, >30 days without recurrence
```

Issue IDs use a collision-free format (`ISSUE-YYYYMMDD-XXXX`) designed for
multi-developer teams. Two developers can create issues simultaneously without
coordination.

Confirmed knowledge that is factual rather than procedural lands in
`knowledge/memory/` instead of a skill. The routing table in
[knowledge/issues/INDEX.md](knowledge/issues/INDEX.md) decides which.

---

## Instructions: one file, every agent

prompt-forge keeps its agent instructions in a single root **`AGENTS.md`**, the
open standard stewarded by the Agentic AI Foundation. It is read natively by VS
Code, GitHub Copilot, Codex, Cursor, Windsurf, Zed, Aider and others.

Claude Code reads `CLAUDE.md` rather than `AGENTS.md`, so the Claude package
ships a thin `CLAUDE.md` whose first line is `@AGENTS.md`. Both agents end up
with the same instructions and there is only one file to maintain.

---

## Installation

Pick the package that matches your agent, copy its contents into your project
root, and you are done.

### Package: VS Code (Copilot, Codex, Cursor, DeepSeek, OpenRouter)

```powershell
git clone https://github.com/pablodiazjorge/prompt-forge.git temp-pf
Copy-Item -Path temp-pf\packages\vscode\* -Destination .\ -Recurse
Remove-Item -Recurse -Force temp-pf
```

Copies `AGENTS.md`, `.github/skills/`, `.github/agents/`, and `knowledge/`.

Confirm `chat.useAgentsMdFile` is enabled in VS Code settings -- without it,
`AGENTS.md` is never loaded.

**DeepSeek V4 users:** read [docs/DEEPSEEK-SETUP.md](docs/DEEPSEEK-SETUP.md).
That extension has a known bug that downgrades system messages, and needs one
extra setting.

### Package: Claude Code

```powershell
git clone https://github.com/pablodiazjorge/prompt-forge.git temp-pf
Copy-Item -Path temp-pf\packages\claude\* -Destination .\ -Recurse
Remove-Item -Recurse -Force temp-pf
```

Copies `AGENTS.md`, `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, and
`knowledge/`. Claude Code discovers the skills and the `ai-engineer` subagent
natively.

Verify with `/context` in a new session: `CLAUDE.md` should appear under
**Memory files** with `AGENTS.md` expanded into it.

---

## Project Structure

```
prompt-forge/
├── AGENTS.md                         Source of truth for agent instructions
├── CLAUDE.md                         Maintainer instructions; imports AGENTS.md
├── .github/
│   ├── agents/                       VS Code custom agent (ai-engineer)
│   └── skills/                       Source of truth for all 6 skills
├── .claude/
│   └── agents/                       Claude Code subagent (ai-engineer)
├── knowledge/
│   ├── issues/                       Issue registry: INDEX, template, 3 states
│   └── memory/                       Promoted facts that aren't skills
├── docs/
│   ├── strategy.md                   Two-tier learning loop, industry comparison
│   └── DEEPSEEK-SETUP.md             Workaround for a DeepSeek extension bug
├── packages/                         Distribution packages (pick one)
│   ├── vscode/                       AGENTS.md + .github/{skills,agents} + knowledge/
│   └── claude/                       AGENTS.md + CLAUDE.md + .claude/{skills,agents} + knowledge/
├── architecture.md                   Architectural decision record
└── sync-skills.ps1                   Syncs the source of truth into both packages
```

Everything under `packages/` is generated. Edit the source of truth, then run
`.\sync-skills.ps1`.

---

## Documentation

- [architecture.md](architecture.md) -- Full architectural decision record (12 ADRs, system context, data flow, token economics)
- [docs/strategy.md](docs/strategy.md) -- Knowledge strategy: two-tier learning loop, industry comparison, promotion pipeline
- [AGENTS.md](AGENTS.md) -- The agent instructions themselves
- [knowledge/issues/INDEX.md](knowledge/issues/INDEX.md) -- Issue registry index, decision criteria, and the category routing table
- [knowledge/issues/TEMPLATE.md](knowledge/issues/TEMPLATE.md) -- Issue template

---

## License

This project's code is licensed under the [MIT License](LICENSE).
