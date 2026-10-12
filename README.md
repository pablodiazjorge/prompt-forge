# prompt-forge

**Shared, reviewed memory for a team's AI coding agents.**

When one developer's agent trips over something in your repository, prompt-forge
has it write that down as a lesson. When the same lesson shows up for more than
one person, a curation step turns it into a short rule that every teammate's
agent reads, whether that is Claude Code, GitHub Copilot, Codex, Cursor, or
Gemini CLI. Promotion goes through an ordinary pull request, so a person reviews
it first.

It is Markdown and git, nothing else: an `AGENTS.md` block, four
[Agent Skills](https://agentskills.io), and a `knowledge/` directory. No
service, no database, no runtime dependency.

[![validate](https://github.com/pablodiazjorge/prompt-forge/actions/workflows/validate.yml/badge.svg)](https://github.com/pablodiazjorge/prompt-forge/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Is this for you?

prompt-forge is built for **teams that share a repository and review changes
through pull requests**.

**Use it if**

- Two or more people work in the same repository with AI coding agents,
  especially different agents.
- You already do code review, and someone can own `knowledge/`.
- Your agents keep tripping over the same project-specific things: build quirks,
  internal conventions, dependency upgrades, shell pitfalls.
- You want that knowledge versioned, reviewable, and portable across agents
  rather than locked inside one vendor's memory feature.

**Skip it if**

- **You work alone.** Recording, review, and promotion are overhead when there
  is nobody to share the result with. Your agent's built-in memory does this
  with no ceremony.
- Nobody will curate regularly. Unreviewed lessons are noise, and noise in an
  agent's context makes it worse.
- Your whole team uses one agent whose built-in repository memory already covers
  you.

[docs/team-vs-solo.md](docs/team-vs-solo.md) has a decision table and what to
use instead.

---

## How it works

```
  any teammate, any agent                 once per sprint                  every task
 ─────────────────────────────     ──────────────────────────────     ─────────────────────
  hits a non-obvious failure  ─►   curate-lessons on a branch:   ─►   agents read the
  record-lesson writes or          merge, screen, count people,       knowledge/memory/
  extends knowledge/lessons/       promote or propose a fix           files that match
  (ships in the normal PR)         ─► pull request, human review      the task
```

1. **Record.** `AGENTS.md` asks every agent to check, at a natural checkpoint
   (before a commit or a pull request, or when it reports a task as done),
   whether it hit something a teammate's agent would repeat. If so, it runs
   `record-lesson`. That skill applies an admission test, redacts hosts and
   secrets, and writes one small file to `knowledge/lessons/`, or appends a
   *sighting* (date, person, branch, agent) to an existing one. Most tasks
   record nothing.
2. **Curate.** A person asks for `curate-lessons`, usually once per sprint. The
   agent works on its own branch. It merges duplicates, rejects unsafe or
   trivial lessons, and checks eligibility: a lesson is eligible once **two or
   more people** have hit it. Many sightings from one person are held, since they
   usually point at one machine. For each eligible lesson the agent takes the
   cheapest durable fix: fix the code, then add a check, then a memory entry,
   then a skill.
3. **Review.** The curation run ends as a pull request with a decision table.
   Merging it is the approval. With CODEOWNERS and branch protection's "Require
   review from Code Owners", only the owners of `knowledge/` can approve it.
4. **Use.** Memory files carry a one-line `description`, and agents read only
   the ones that match their task. Entries have a size budget and a
   `review after` date, so memory stays small and current.

Lessons cost nothing at run time: agents never read `knowledge/lessons/` during
ordinary work. Only reviewed memory is loaded, and only when it matches.

A lesson, as `record-lesson` writes it:

```markdown
---
title: The API client is generated from api/openapi.yaml and committed, so edits to the schema need a regeneration
category: repo
scope: "api/openapi.yaml"
---

**Lesson:** After editing `api/openapi.yaml`, run `make gen` and commit the
regenerated files under `src/generated/`.

**Why:** CI type-checks the committed client but never regenerates it, so a
schema change without `make gen` fails with type errors far from the cause.

## Sightings

- 2026-10-13 | @ana | feature/invoice-export | claude-code | type errors in src/billing after adding a schema field
- 2026-10-16 | @ben | fix/tax-rounding | copilot | CI failed on a renamed schema property
```

And the memory entry that curation turned it into, in `knowledge/memory/api-client.md`:

```markdown
---
description: Read when editing api/openapi.yaml or code under src/generated/.
---

# API client

- Regenerate the client with `make gen` after editing `api/openapi.yaml`, and
  never hand-edit `src/generated/`: CI type-checks the committed client.
  <!-- verified 2026-10-26 | review after 2027-04 | from lesson regenerate-client-after-schema-edit -->
```

The [examples/](examples/) directory walks through the whole cycle, including a
proposed fix and a held lesson.

---

## Install

Requirements: git, plus bash (macOS, Linux, Git Bash) or PowerShell 5.1+.

**macOS, Linux, Git Bash**

```bash
git clone --depth 1 https://github.com/pablodiazjorge/prompt-forge.git /tmp/prompt-forge
bash /tmp/prompt-forge/install.sh /path/to/your/project
```

**Windows PowerShell**

```powershell
git clone --depth 1 https://github.com/pablodiazjorge/prompt-forge.git $env:TEMP\prompt-forge
powershell -ExecutionPolicy Bypass -File $env:TEMP\prompt-forge\install.ps1 -Target C:\path\to\your\project
```

The installer **never overwrites your files**:

- `AGENTS.md` gets a block between `<!-- prompt-forge:start -->` markers
  appended. `CLAUDE.md` and `GEMINI.md` get an `@AGENTS.md` import line if they
  lack one.
- `knowledge/` is created only where missing and is never changed afterwards.
- prompt-forge's own skills are created when missing and replaced only with
  `--upgrade` (`-Upgrade`).

Options: `--dry-run`, `--upgrade`, `--skip-claude` (no `CLAUDE.md` or
`.claude/`), `--skip-gemini`. PowerShell uses `-DryRun`, `-Upgrade`,
`-SkipClaude`, `-SkipGemini`.

Then review the changes with `git status` and `git diff` (new files show as
untracked), add the [CODEOWNERS entries](docs/team-setup.md#codeowners), and
commit.
[docs/team-setup.md](docs/team-setup.md) covers the pull request checklist and
the curation routine.

To upgrade later, update the clone (`git -C /tmp/prompt-forge pull`, or clone
again) and run the installer with `--upgrade`. Upgrading from 1.x? Read
[docs/upgrading.md](docs/upgrading.md) first.

---

## What gets installed

```
AGENTS.md                         prompt-forge block, merged into yours
CLAUDE.md, GEMINI.md              one line: @AGENTS.md (merged into yours)
.agents/skills/                   the skills, for most agents
  record-lesson/                    writes candidate lessons
  curate-lessons/                   promotes them through a pull request
  git-workflow/                     non-interactive git and commit conventions
  powershell-patterns/              Windows PowerShell 5.1 and 7 pitfalls
.claude/skills/                   identical copy: Claude Code reads only this path
.claude/agents/curate-lessons.md  runs curation in its own context
knowledge/
  README.md                         your team's policy: thresholds and budgets
  lessons/                          candidates
  memory/                           verified team facts
```

Discovery costs about 100 tokens per skill. Bodies load only when a task matches:
`record-lesson` is about 1.1k tokens and `curate-lessons` about 1.6k.

### Agent coverage

As of October 2026. **I** = reads the instructions, **S** = loads the skills,
**A** = can run curation as a separate subagent. Where there is no subagent,
invoke the `curate-lessons` skill directly. In Claude Code, `/curate-lessons`
runs in your conversation; ask for the `curate-lessons` subagent to run it in a
context of its own.

| Agent | I | S | A | Notes |
|---|---|---|---|---|
| Claude Code | ✓ | ✓ | ✓ | Through `CLAUDE.md` → `@AGENTS.md` and `.claude/` |
| GitHub Copilot (VS Code, CLI, cloud agent) | ✓ | ✓ | in VS Code | VS Code reads the subagent from `.claude/agents/` |
| Codex | ✓ | ✓ | — | Reads `AGENTS.md` and `.agents/skills/` |
| Cursor | ✓ | ✓ | ✓ | Reads `.claude/agents/` too |
| Gemini CLI | ✓ | ✓ | — | Through `GEMINI.md` → `@AGENTS.md` |
| OpenCode, Amp, Junie, Devin Desktop (formerly Windsurf) | ✓ | ✓ | — | `.agents/skills/` |
| Zed | ✓ | ✓ | — | Uses `AGENTS.md` only if no `.rules`, `.cursorrules`, `AGENT.md` or similar file exists |
| Kiro | ✓ | — | — | Reads skills only from `.kiro/skills/` |
| Aider | manual | — | — | Add `read: AGENTS.md` to `.aider.conf.yml` |

Tools that read both `.agents/skills/` and `.claude/skills/` (VS Code, Cursor,
OpenCode, Amp) may list each skill twice. If nobody on the team uses Claude Code,
install with `--skip-claude`. Details and sources:
[docs/known-issues.md](docs/known-issues.md).

---

## Compared with built-in memory

Built-in memories capture knowledge automatically, for one person or inside one
vendor's product. prompt-forge does something narrower: it decides what a
*team* should share, and it records that in git where people review it.

| | Built-in memory (e.g. Claude Code, Copilot) | prompt-forge |
|---|---|---|
| Scope | Your machine, or one vendor's cloud | The repository, for every agent |
| Who decides what sticks | The agent | Two or more people hitting it, then a reviewed PR |
| Audit trail | Varies | Git history and PR descriptions |
| Effort | None | Someone curates each sprint |

You can use both: personal preferences in your agent's memory, team facts in
`knowledge/`. [docs/comparison.md](docs/comparison.md) compares
prompt-forge with Copilot Memory, Claude Code auto memory,
compound-engineering, claude-reflect, and others, with sources.

---

## Limitations

- **Recording depends on the agent following `AGENTS.md`.** No hook forces it
  yet; the pull request checklist in [docs/team-setup.md](docs/team-setup.md) is
  the backstop. Optional hooks are on the [roadmap](ROADMAP.md).
- **No evaluation yet.** Nobody has measured whether promoted memory improves
  task success on a benchmark. Research on context files is mixed:
  [Gloaguen et al. (2026)](https://arxiv.org/abs/2602.11988) found that
  `AGENTS.md`-style files do not generally improve success and raise cost by over
  20%. The budgets and the "fix the code first" ladder are a response to that,
  not proof that it works.
- **It needs a curator.** If nobody runs `curate-lessons`, lessons pile up.
- **Possible duplicate skill listings** in tools that read both skill
  directories (see above).

---

## Documentation

- [docs/team-vs-solo.md](docs/team-vs-solo.md): who should use this, and what to
  use otherwise
- [docs/team-setup.md](docs/team-setup.md): CODEOWNERS, the PR checklist, and the
  curation routine
- [docs/comparison.md](docs/comparison.md): related tools and research, with
  sources
- [docs/upgrading.md](docs/upgrading.md): moving from 1.x
- [docs/known-issues.md](docs/known-issues.md): per-tool caveats
- [architecture.md](architecture.md): design decisions (ADRs)
- [CHANGELOG.md](CHANGELOG.md), [ROADMAP.md](ROADMAP.md),
  [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md)

## License

[MIT](LICENSE)
