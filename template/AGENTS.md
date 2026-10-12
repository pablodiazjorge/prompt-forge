# AGENTS.md

<!-- Project instructions go here, outside the prompt-forge block. Keep them
short: only what an agent cannot infer from the code. -->

<!-- prompt-forge:start -->
## Team knowledge (prompt-forge)

- **Before a task**, read the `description:` line at the top of each file in
  `knowledge/memory/` (a content search for `^description:` lists them all) and
  open only the files that match the task. They hold facts the team has
  verified. If an entry turns out to be wrong, say so and record it with
  `record-lesson`.
- **At a checkpoint** (before committing, before opening a pull request, or when
  reporting a task as done), if you hit a non-obvious failure that a teammate's
  agent would likely repeat, run the `record-lesson` skill. Most tasks produce no
  lesson; then say nothing about it.
- **Curation** runs only when a person asks for `curate-lessons`. Outside a
  curation run, agents do not edit `knowledge/memory/`.
- Skills live in `.agents/skills/` (and in `.claude/skills/` for Claude Code). If
  your agent does not load Agent Skills natively, read a skill's `SKILL.md` when
  the task matches its `description`.
<!-- prompt-forge:end -->
