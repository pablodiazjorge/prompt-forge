# prompt-forge

A drop-in toolkit that adds Agent Skills, an auto-improvement loop, and session
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
standard, plus a cross-session issue registry, agent instructions, and optional
session tracking.

### Skills

| Skill | Triggers when | Body tokens |
|-------|---------------|-------------|
| `auto-improve` | End of iteration; "analyze this session" | 1.5k |
| `explore-codebase` | "Where is X?"; "How does Y work?" | 0.7k |
| `git-workflow` | Committing, branching, reviewing PRs | 0.5k |
| `powershell-patterns` | Terminal commands, .ps1 scripts, npm on Windows | 0.6k |
| `skill-creator` | Creating or fixing Agent Skills; auto-improve promotion target | 2.3k |
| `track-tokens` | "What did this cost?"; "Session stats" | 1.2k |

Total discovery overhead across all six skills is approximately 600 tokens per
session. Skill bodies are loaded only when the conversation context matches the
skill's description.

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

### Session Tracking (Optional)

PowerShell scripts that log token usage and estimate costs across six AI
providers. The `track-tokens` skill provides a cross-platform alternative that
queries VS Code's internal session store directly.

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
`.github/instructions/`, `knowledge/`, and `scripts/` into your project.

### Package: Claude (Claude Code, Anthropic)

```powershell
git clone https://github.com/pablodiazjorge/prompt-forge.git temp-pf
Copy-Item -Path temp-pf\packages\claude\* -Destination .\ -Recurse
Remove-Item -Recurse -Force temp-pf
```

Copies `.claude/skills/`, `CLAUDE.md`, `knowledge/`, and `scripts/` into your
project. Claude discovers skills from `.claude/skills/` and reads `CLAUDE.md`
as its instruction file.

### Package: Custom (DeepSeek V4, OpenRouter, third-party models)

```powershell
git clone https://github.com/pablodiazjorge/prompt-forge.git temp-pf
Copy-Item -Path temp-pf\packages\custom\* -Destination .\ -Recurse
Remove-Item -Recurse -Force temp-pf
```

Copies `.github/skills/`, `.github/instructions/`, `knowledge/`, and
`scripts/` into your project. Does not include `copilot-instructions.md` since
third-party model providers may not load it. Uses `.instructions.md` format
which is discovered by VS Code regardless of the model provider.

**DeepSeek V4 users:** read [DEEPSEEK-SETUP.md](packages/custom/DEEPSEEK-SETUP.md)
for additional configuration required due to a known bug in the extension.

### After Copying

Add `.prompt-forge/` to your `.gitignore` (the shipped `.gitignore` only
covers prompt-forge artifacts and can be merged with yours).

---

## AI Model Pricing Reference

All prices in USD per 1M tokens. Last updated: 2026-06-24. Used by
`session-end.ps1` and the `track-tokens` skill.

| Provider / Model | Input | Output | Cached |
|------------------|-------|--------|--------|
| **OpenAI** | | | |
| GPT-5.5 | $5.00 | $30.00 | $0.50 |
| GPT-5.4 | $2.50 | $15.00 | $0.25 |
| GPT-5.4 Mini | $0.75 | $4.50 | $0.075 |
| **Anthropic** | | | |
| Claude Fable 5 | $10.00 | $50.00 | $1.00 |
| Claude Opus 4.8 | $5.00 | $25.00 | $0.50 |
| Claude Sonnet 4.6 | $3.00 | $15.00 | $0.30 |
| Claude Haiku 4.5 | $1.00 | $5.00 | $0.10 |
| **DeepSeek** | | | |
| V4 Flash | $0.14 | $0.28 | $0.003 |
| V4 Pro | $0.44 | $0.87 | $0.004 |
| **Kimi / Moonshot** | | | |
| K2.7 Code | $0.90 | $3.73 | $0.18 |
| K2.6 | $0.90 | $3.73 | $0.15 |
| **MiniMax** | | | |
| M3 | $0.30 | $1.20 | $0.06 |
| M2.7 | $0.30 | $1.20 | $0.06 |

### GitHub Copilot Plans

| Plan | Price/month | Includes |
|------|-------------|----------|
| Free | $0 | 2K completions, Haiku 4.5 + GPT-5 Mini |
| Pro | $10 | Unlimited, Cloud agent, model selection, $15 credits |
| Pro+ | $39 | Premium models (Opus), 4x usage, $70 credits |
| Max | $100 | Priority access, 2.9x usage vs Pro+, $200 credits |

---

## Project Structure

```
prompt-forge/
├── .github/
│   ├── copilot-instructions.md       Source of truth for Copilot instructions
│   ├── instructions/
│   │   └── default.instructions.md   Source of truth for VS Code instructions
│   └── skills/                       Source of truth for all 6 skills
├── packages/                         Distribution packages (pick one)
│   ├── copilot/                      Drop-in for GitHub Copilot / VS Code
│   │   ├── .github/
│   │   │   ├── copilot-instructions.md
│   │   │   ├── instructions/default.instructions.md
│   │   │   └── skills/  (6 SKILL.md)
│   │   ├── knowledge/issues/
│   │   └── scripts/
│   ├── claude/                       Drop-in for Claude Code / Anthropic
│   │   ├── .claude/
│   │   │   └── skills/  (6 SKILL.md)
│   │   ├── CLAUDE.md
│   │   ├── knowledge/issues/
│   │   └── scripts/
│   └── custom/                       Drop-in for DeepSeek, OpenRouter, etc.
│       ├── .github/
│       │   ├── instructions/default.instructions.md
│       │   └── skills/  (6 SKILL.md)
│       ├── knowledge/issues/
│       └── scripts/
├── knowledge/issues/                 Issue registry template
├── scripts/                          Session tracking scripts
└── sync-skills.ps1                   Syncs .github/skills/ → all packages
```

---

## Documentation

- [architecture.md](architecture.md) -- Full architectural decision record (10 ADRs, system context, data flow, token economics)
- [.github/instructions/default.instructions.md](.github/instructions/default.instructions.md) -- Agent instructions (loaded by VS Code on all model providers)
- [knowledge/issues/INDEX.md](knowledge/issues/INDEX.md) -- Issue registry index and decision criteria
- [knowledge/issues/TEMPLATE.md](knowledge/issues/TEMPLATE.md) -- Issue template

---

## Author

pablodiazjorge -- [github.com/pablodiazjorge/prompt-forge](https://github.com/pablodiazjorge/prompt-forge)

## License

MIT
