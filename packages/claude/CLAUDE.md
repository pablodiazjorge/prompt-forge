# CLAUDE.md

## Startup Sequence — Mandatory

At the start of every session, before doing anything else:

1. Read the directories under `.claude/skills/` to discover all available skills.

2. For each skill, read only the YAML frontmatter (lines between the first two
   `---` delimiters) to get the `name` and `description`.

3. Compare the current task against each description. If it matches, read the
   full `SKILL.md` body and follow its instructions.

4. The `developer` skill handles continuous issue tracking and applies to ALL
   work. Load it immediately. All other skills use progressive disclosure
   (steps 2-3): read only their frontmatter descriptions and load the full
   body only when the task matches the description.

5. Run any available lint/compile checks before making changes.

## During the Session

- Run the `developer` skill at the end of every significant iteration. It
  records issues in `knowledge/issues/open/` but never promotes or modifies
  skills.
- Run the `ai-engineer` skill as a subagent when the user asks to organize
  knowledge, clean up issues, or promote patterns to skills/memories.
- Run `track-tokens` when the user asks about session cost.
- Note errors, API changes, and workarounds mentally. The `developer` skill
  formalizes them into `knowledge/issues/` after the session.

## Git

Use Conventional Commits v1.0.0. One logical change per commit.
Branch naming: `feature/<name>`, `fix/<name>`, `docs/<name>`, `chore/<name>`.

## After Each Session

1. Run the `developer` skill to capture learnings.
2. Run track-tokens if the user asks for cost data.
3. Commit changes to `knowledge/issues/` and any updated skills.
