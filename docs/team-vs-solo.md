# Team or solo: which workflow fits

prompt-forge is a team tool. Its cost (recording, a curation run each sprint, a
reviewed pull request) pays off only when what one person's agent learns is
worth sharing with other people's agents. This page helps you decide, and points
to better options when prompt-forge is not the right fit.

As of October 2026. Tools change quickly, so check the linked docs.

## Decision table

| Situation | Use | Why |
|---|---|---|
| Solo developer, one agent | Your agent's built-in memory, plus a short hand-written `AGENTS.md` or `CLAUDE.md` | No setup, private, automatic |
| Solo, and you want to approve each correction | [claude-reflect](https://github.com/BayramAnnakov/claude-reflect), or tell the agent "add this to AGENTS.md" | Approval per item, still lightweight |
| Team on GitHub that uses only Copilot | [Copilot Memory](https://docs.github.com/en/copilot/concepts/agents/copilot-memory) plus committed instructions | Repository-scoped, checked against citations, expires unused entries |
| Team that uses only Claude Code | A shared `CLAUDE.md` or `AGENTS.md` that people update through review | Native, nothing to install |
| **Team with mixed agents, or no vendor cloud memory allowed** | **prompt-forge** | Works across agents, reviewed in git, gated by recurrence |
| Building new features from specs | A spec-driven tool such as [Spec Kit](https://github.com/github/spec-kit) or Kiro specs, alongside prompt-forge | Specs describe what to build next; lessons record what went wrong |
| Organization-wide standards | Your agent vendor's managed settings or team rules, or an internal plugin or skills marketplace | Enforced centrally rather than learned per repository |

## Working solo? Do this instead

1. **Let your agent remember for you.** Built-in memory such as Claude Code
   [auto memory](https://code.claude.com/docs/en/memory#auto-memory) or GitHub
   [Copilot Memory](https://docs.github.com/en/copilot/concepts/agents/copilot-memory)
   captures lessons without ceremony. For one person, that is all you need.
2. **Keep a short `AGENTS.md` you write yourself.** When the agent repeats a
   mistake, add one line. When a line stops being true, delete it.
   [Gloaguen et al. (2026)](https://arxiv.org/abs/2602.11988) found that
   context files raise cost and do not generally improve success; files written
   by developers did slightly better than generated ones, though neither effect
   was statistically significant.
3. **Turn repeat mistakes into checks.** A lint rule, test, or script that fails
   loudly beats any instruction an agent might skip.
4. **Use the prompt-forge skills on their own if you like them.**
   `git-workflow` and `powershell-patterns` work without the learning loop. Copy
   those two directories from `template/.agents/skills/` into your project, or
   into your user-level skills directory (for example `~/.agents/skills/` or
   `~/.claude/skills/`), and leave `knowledge/` and the `AGENTS.md` block out.

## Signs a team is ready for prompt-forge

- Two people have lost time to the same agent mistake in the last month.
- People use different agents, so no single vendor's memory reaches everyone.
- Someone is willing to run curation and review the pull request each sprint.

## Signs it is not working

- Curation runs promote almost nothing for several sprints. Your agents may not
  be recording, or the team's problems are already caught by checks. Look at the
  pull request checklist answers before adding more process.
- `knowledge/memory/` keeps hitting its budget. Push more lessons down the
  promotion ladder: fix the code or add a check instead of writing memory.
- Lessons describe one person's machine. Those belong in that person's own agent
  memory, not the team's.
