# How prompt-forge compares

As of October 2026. This replaces the 1.x `strategy.md`, whose comparisons had
gone stale (for example, it said Copilot had no learning loop).

## The short version

Several good tools already capture what an agent learns. Most do it for **one
person** or inside **one vendor's product**, and most promote knowledge either
automatically or one item at a time. prompt-forge adds three things for teams:

1. **A recurrence gate across people.** A lesson is promoted only after two or
   more teammates hit it. One person's broken machine does not become everyone's
   rule.
2. **Review as code.** Promotion is a pull request with a decision table, owned
   through CODEOWNERS. Git history is the audit trail.
3. **Agent-neutral output.** Knowledge lands in plain Markdown that any agent
   reading `AGENTS.md` can use, so a team that mixes agents shares one memory.

If you do not need those three, a built-in feature is simpler.

## Built-in memory

| | Scope and storage | How knowledge is kept | Notes |
|---|---|---|---|
| [Claude Code auto memory](https://code.claude.com/docs/en/memory#auto-memory) | Machine-local, shared across worktrees of a repository | Claude saves notes automatically | Personal. Pairs well with prompt-forge for individual preferences |
| [GitHub Copilot Memory](https://docs.github.com/en/copilot/concepts/agents/copilot-memory) | Repository-scoped, in GitHub's cloud; public preview | Copilot creates memories while users with write access work; citations are checked against the current branch before use; unused entries are deleted after 28 days | The strongest option for a Copilot-only team. Not reviewed in git, Copilot only |
| Shared `AGENTS.md` / `CLAUDE.md` | Repository | People edit it, often by asking the agent to add a line | The no-tool baseline. prompt-forge adds the gate, the budget, and the review routine on top |

## Open-source projects in the same space

| Project | What it does | Difference from prompt-forge |
|---|---|---|
| [compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) | A plugin for Claude Code, Codex, Cursor and more that documents solutions after each piece of work so later work compounds | Broader workflow (plan, work, review, compound). Records every solution; no cross-person recurrence gate |
| [claude-reflect](https://github.com/BayramAnnakov/claude-reflect) | Captures corrections and preferences in Claude Code and syncs them into `CLAUDE.md` and `AGENTS.md` after review | Approval per item, aimed at individuals. A good solo alternative |
| [self-improving-agent](https://github.com/pskoett/self-improving-agent) | A skill for OpenClaw that records learnings, errors and feature requests across sessions | Very similar idea for a single agent. No team review step |
| [ECC](https://github.com/affaan-m/ECC) (formerly everything-claude-code) | A large collection of skills, memory, and optimization tooling for several agents | A personal power-user harness rather than a team process |

## Research and practice

- **Context files are not free.**
  [Gloaguen et al., "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?"](https://arxiv.org/abs/2602.11988)
  (ETH Zurich and LogicStar.ai) found that context files do not generally
  improve task success and raise inference cost by more than 20% on average. In
  the current version (v3), LLM-generated files changed success by −0.5% to −2%
  and developer-written files by +2.4%, neither statistically significant. This
  is why prompt-forge budgets memory, prefers fixing code or adding a check over
  writing memory, and keeps a human in the loop.
- **Industry radar.** The Thoughtworks Technology Radar (Vol. 34, April 2026)
  places
  [curated shared instructions for software teams](https://www.thoughtworks.com/radar/techniques/curated-shared-instructions-for-software-teams)
  in Adopt, and the
  [feedback flywheel](https://www.thoughtworks.com/radar/techniques/feedback-flywheel)
  in Assess.

## When to choose something else

- You work alone: built-in memory, or claude-reflect.
- Your team uses only Copilot and is happy with cloud-stored memory: Copilot
  Memory.
- You want a full plan-build-review workflow, not just a lessons loop:
  compound-engineering.
- You want agents to build from specifications: a spec-driven tool. It
  complements prompt-forge rather than replacing it.
