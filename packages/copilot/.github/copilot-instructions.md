# Agent Instructions

## Startup Sequence — Mandatory

At the start of every session, before doing anything else, execute these steps
in order:

1. Read the list of directories under `.github/skills/` to discover all
   available skills.

2. For each skill found, read only the YAML frontmatter block (lines between
   the first two `---` delimiters). This exposes the skill's `name` and
   `description` at minimal token cost.

3. Compare the current task against each skill's description. If the task
   matches, read the FULL `SKILL.md` body for that skill and follow its
   instructions.

4. Skills `explore-codebase`, `git-workflow`, `powershell-patterns`, and
   `skill-creator` apply to ALL work regardless of the specific task. Load
   them immediately.

5. Run `get_errors()` across the workspace. Fix any existing errors before
   making new changes.

## During the Session

- Run `auto-improve` at the end of every significant iteration or when the
  user signals they are done with a task.
- Run `track-tokens` when the user asks about session cost or token usage.
- When you encounter an error, API change, or workaround worth remembering,
  note it mentally. `auto-improve` will formalize it into the issue registry
  at `knowledge/issues/` after the session.

## PowerShell (Windows)

These rules are ambient and apply even if the `powershell-patterns` skill is
not explicitly triggered:

- Chain commands with `;`, never `&&`.
- Never use `@"..."@` heredocs for files containing `{{ }}`. Use the
  `create_file` or `replace_string_in_file` tools instead.
- `nvm use X.Y.Z` after `nvm install`. It does not auto-activate.

## Git

Use Conventional Commits v1.0.0. One logical change per commit.

```
feat:     New feature
fix:      Bug fix
docs:     Documentation
chore:    Build, deps, tooling
refactor: Code change, no fix or feature
test:     Adding or correcting tests
```

Branch naming: `feature/<name>`, `fix/<name>`, `docs/<name>`, `chore/<name>`.

## After Each Session

1. Run auto-improve to capture learnings into the issue registry.
2. Run track-tokens if the user asks for cost data.
3. Commit changes to `knowledge/issues/` and any updated skills.
