# prompt-forge

A drop-in toolkit that adds Agent Skills, a learning loop, and session
tracking to any software project. Copy the files in and your AI coding agent
gets smarter with every session. No dependencies, no build step, no backend.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Why prompt-forge Exists

AI coding agents are powerful but stateless. They enter each session with the
same baseline knowledge and make the same mistakes across sessions and across
developers. A team of five engineers using Copilot might independently discover
the same PowerShell pitfall, the same broken ngx-translate API, and the same
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
| Agent-agnostic | No skill assumes a specific AI coding platform; works with Copilot, Claude Code, and Codex |

For a detailed rationale behind every architectural decision, see
[architecture.md](architecture.md).

---

## What You Get

Six Agent Skills following the [agentskills.io](https://agentskills.io)
standard, plus a cross-session issue registry, agent instructions, and a custom
agent.

### Skills

| Skill | Triggers when | Body tokens |
|-------|---------------|-------------|
| `developer` | End of iteration; "analyze this session" | 1.2k |
| `ai-engineer` | On-demand; "organize knowledge", "promote patterns" | 1.8k |
| `explore-codebase` | "Where is X?"; "How does Y work?" | 0.7k |
| `git-workflow` | Committing, branching, reviewing PRs | 0.5k |
| `powershell-patterns` | Terminal commands, .ps1 scripts, npm on Windows | 0.6k |
| `skill-creator` | Creating or fixing Agent Skills; ai-engineer promotion target | 2.3k |

Total discovery overhead across all six skills is approximately 600 tokens per
session. Skill bodies are loaded only when the conversation context matches the
skill's description. Only the `developer` skill is loaded eagerly at startup.

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

---

## Installation

prompt-forge is organized into provider-specific packages under `packages/`.
Pick the folder that matches your AI coding agent, copy its contents into your
project root, and you are done.

### Package: Copilot (GitHub Copilot, VS Code)

```powershell
git clone https://github.com/pablodiazjorge/prompt-forge.git temp-pf
Copy-Item -Path temp-pf\packages\copilot\* -Destination .\ -Recurse
Remove-Item -Recurse -Force temp-pf
```

Copies `.github/skills/`, `.github/copilot-instructions.md`,
`.github/instructions/`, and `knowledge/` into your project.

### Package: Claude (Claude Code, Anthropic)

```powershell
git clone https://github.com/pablodiazjorge/prompt-forge.git temp-pf
Copy-Item -Path temp-pf\packages\claude\* -Destination .\ -Recurse
Remove-Item -Recurse -Force temp-pf
```

Copies `.claude/skills/`, `CLAUDE.md`, and `knowledge/` into your
project. Claude discovers skills from `.claude/skills/` and reads `CLAUDE.md`
as its instruction file.

### Package: Custom (DeepSeek V4, OpenRouter, third-party models)

```powershell
git clone https://github.com/pablodiazjorge/prompt-forge.git temp-pf
Copy-Item -Path temp-pf\packages\custom\* -Destination .\ -Recurse
Remove-Item -Recurse -Force temp-pf
```

Copies `.github/skills/`, `.github/instructions/`, and `knowledge/`
into your project. Does not include `copilot-instructions.md` since
third-party model providers may not load it. Uses `.instructions.md` format
which is discovered by VS Code regardless of the model provider.

**DeepSeek V4 users:** read [DEEPSEEK-SETUP.md](packages/custom/DEEPSEEK-SETUP.md)
for additional configuration required due to a known bug in the extension.

### After Copying

Add `.prompt-forge/` to your `.gitignore` (the shipped `.gitignore` only
covers prompt-forge artifacts and can be merged with yours).

---

## Project Structure

```
prompt-forge/
├── .github/
│   ├── copilot-instructions.md       Source of truth for Copilot instructions
│   ├── instructions/
│   │   └── default.instructions.md   Source of truth for VS Code instructions
│   ├── agents/                       Custom agents (AI Engineer)
│   └── skills/                       Source of truth for all 6 skills
├── packages/                         Distribution packages (pick one)
│   ├── copilot/                      Drop-in for GitHub Copilot / VS Code
│   │   ├── .github/
│   │   │   ├── copilot-instructions.md
│   │   │   ├── instructions/default.instructions.md
│   │   │   ├── agents/   (AI Engineer agent)
│   │   │   └── skills/   (6 SKILL.md)
│   │   ├── knowledge/issues/
│   ├── claude/                       Drop-in for Claude Code / Anthropic
│   │   ├── .claude/
│   │   │   └── skills/   (6 SKILL.md)
│   │   ├── CLAUDE.md
│   │   └── knowledge/issues/
│   └── custom/                       Drop-in for DeepSeek, OpenRouter, etc.
│       ├── .github/
│       │   ├── instructions/default.instructions.md
│       │   └── skills/   (6 SKILL.md)
│       └── knowledge/issues/
├── knowledge/issues/                 Issue registry template
└── sync-skills.ps1                   Syncs .github/skills/ → all packages
```

---

## Documentation

- [architecture.md](architecture.md) -- Full architectural decision record (11 ADRs, system context, data flow, token economics)
- [knowledge/strategy.md](knowledge/strategy.md) -- Knowledge strategy: two-tier learning loop, industry comparison, promotion pipeline
- [.github/instructions/default.instructions.md](.github/instructions/default.instructions.md) -- Agent instructions (loaded by VS Code on all model providers)
- [knowledge/issues/INDEX.md](knowledge/issues/INDEX.md) -- Issue registry index and decision criteria
- [knowledge/issues/TEMPLATE.md](knowledge/issues/TEMPLATE.md) -- Issue template

---

## License

This project's code is licensed under the [MIT License](LICENSE).