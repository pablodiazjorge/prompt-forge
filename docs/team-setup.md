# Team setup

The installer gives you the files. This page covers the three pieces of process
that make them work for a team: ownership, a checklist line, and a curation
routine. Each takes a few minutes to set up.

## CODEOWNERS

Everything in `knowledge/memory/`, the `AGENTS.md` block, and the skills
directories is loaded into every teammate's agent. Require review from someone
who owns that:

```
# .github/CODEOWNERS (GitHub) or CODEOWNERS (GitLab)
/knowledge/memory/     @your-org/agent-knowledge-owners
/knowledge/README.md   @your-org/agent-knowledge-owners
/AGENTS.md             @your-org/agent-knowledge-owners
/CLAUDE.md             @your-org/agent-knowledge-owners
/GEMINI.md             @your-org/agent-knowledge-owners
/.agents/skills/       @your-org/agent-knowledge-owners
/.claude/              @your-org/agent-knowledge-owners
```

`knowledge/README.md` is included because it holds the thresholds: changing it
changes what gets promoted. CODEOWNERS only requests reviews; to make them
required, enable "Require review from Code Owners" in branch protection (GitHub)
or the equivalent approval rule elsewhere.

Leave `knowledge/lessons/` out. Lessons are candidates that ride along with
ordinary pull requests, and requiring an extra reviewer for them adds friction
where you want none.

## Pull request checklist

Recording relies on agents following `AGENTS.md`, and agents sometimes forget. A
single checkbox in the pull request template is the human backstop:

```markdown
- [ ] Agent lessons: none, or recorded in `knowledge/lessons/`
```

If the author remembers a mistake their agent made that a teammate's agent would
repeat, they ask the agent to run `record-lesson` before merging.

## Curation routine

Once per sprint, a rotating steward:

1. Asks an agent to run `curate-lessons`. In Claude Code, Cursor, or VS Code it
   can use the `curate-lessons` subagent; elsewhere the skill runs directly.
2. Reads the returned report and the diff on the `chore/curate-lessons-*`
   branch, then opens the pull request with the report as its description.
3. Gets it reviewed by a CODEOWNER and merges it.

Expect a few minutes when there is little to do.

Once a quarter, the steward also prunes: run your agent's instruction audit over
`AGENTS.md`, the skills, and `knowledge/memory/` (in Claude Code,
`/doctor prompt-audit`), and accept the deletions it can justify.

## Tuning

Thresholds and budgets live in `knowledge/README.md`, and the curator reads them
on every run. Common adjustments:

- **Large team or monorepo:** raise the memory budget, and split memory files by
  area so agents load only the relevant one.
- **Slow-moving repository:** lengthen `stale_after` so quiet periods do not
  delete real candidates.

## Recommended: union merges for lessons

Two branches that each append a sighting to the same lesson conflict on the last
lines of the file. The right resolution is always "keep both lines", which git
can do for you. Add this to the repository's `.gitattributes`:

```
knowledge/lessons/*.md merge=union
```

## Optional: secret scanning

Lessons are paraphrased and redacted by instruction, but instructions are not
guarantees. If your CI already runs a secret scanner such as gitleaks or GitHub
secret scanning, make sure it covers `knowledge/`.
