# Upgrading from 1.x to 2.0

2.0 is a breaking release. The learning loop was redesigned for teams, the two
roles were renamed, three skills were removed, and the per-agent packages were
replaced by one installer. Plan about fifteen minutes.

## What changed

| 1.x | 2.0 |
|---|---|
| `developer` skill, loaded every session | `record-lesson`, run at checkpoints |
| `ai-engineer` skill and subagent | `curate-lessons`, ending in a reviewed pull request |
| `knowledge/issues/{open,promoted,discarded}/` and `INDEX.md` | `knowledge/lessons/`, one file per lesson; git history replaces the status folders |
| `occurrences` and `certainty` counters | A `Sightings` list; counts are derived from it |
| Promotion after 3 occurrences, approved in chat | 2 or more distinct reporters, approved by merging a pull request |
| Promotions edited the shipped skills | Promotions go to `knowledge/memory/` or a team-owned skill; shipped skills are never edited |
| Nothing read `knowledge/memory/` | `AGENTS.md` tells agents to read matching memory files |
| `explore-codebase`, `skill-creator`, `track-tokens` | Removed. Skill-writing guidance is now a reference inside `curate-lessons` |
| `scripts/session-start.ps1`, `scripts/session-end.ps1` | Removed (token tracking was dropped before 2.0) |
| Packages for Copilot, Claude Code, and custom setups | `install.sh` / `install.ps1`, which merge instead of overwriting |
| Skills in `.github/skills/` or `.claude/skills/` | Skills in `.agents/skills/`, plus a copy in `.claude/skills/` for Claude Code |

## Steps

1. **Preview.** The installer reports 1.x files it finds and never deletes them.

   ```bash
   git clone --depth 1 https://github.com/pablodiazjorge/prompt-forge.git /tmp/prompt-forge
   bash /tmp/prompt-forge/install.sh --dry-run /path/to/project
   ```

   ```powershell
   git clone --depth 1 https://github.com/pablodiazjorge/prompt-forge.git $env:TEMP\prompt-forge
   powershell -ExecutionPolicy Bypass -File $env:TEMP\prompt-forge\install.ps1 -Target C:\path\to\project -DryRun
   ```

2. **Rescue promoted knowledge.** If `ai-engineer` added sections to your copies
   of `powershell-patterns` or `git-workflow`, move those sections into
   `knowledge/memory/` now. The next step replaces both skills.

3. **Install with upgrade**, so the 2.0 versions replace any 1.x copies of
   `git-workflow` and `powershell-patterns` under `.claude/skills/`:

   ```bash
   bash /tmp/prompt-forge/install.sh --upgrade /path/to/project
   ```

   ```powershell
   powershell -ExecutionPolicy Bypass -File $env:TEMP\prompt-forge\install.ps1 -Target C:\path\to\project -Upgrade
   ```

4. **Carry over open issues, if any.** Ask your agent:

   > Convert each file in knowledge/issues/open/ into a lesson in
   > knowledge/lessons/ using the record-lesson format. Turn each recorded
   > session into a Sightings line, taking the reporter from
   > `git log -1 --format=%an -- <file>`. Drop issues that fail record-lesson's
   > admission test.

   Converted lessons keep their old dates. Those with a single reporter and no
   sighting in the last 90 days are deleted by the first curation run. That is
   usually right; record a fresh sighting for any that still matter.

5. **Remove the 1.x files** after reviewing them. The installer listed the ones
   it found:

   ```
   .github/skills/{developer,ai-engineer,explore-codebase,skill-creator,track-tokens}/
   .github/skills/{git-workflow,powershell-patterns}/   (2.0 ships them in .agents/skills/)
   .claude/skills/{developer,ai-engineer,explore-codebase,skill-creator,track-tokens}/
   .github/agents/ai-engineer.agent.md
   .claude/agents/ai-engineer.md
   .github/instructions/default.instructions.md
   knowledge/issues/
   scripts/session-start.ps1, scripts/session-end.ps1
   DEEPSEEK-SETUP.md
   .prompt-forge/   (old session logs, if any)
   ```

   The 1.x Copilot package also shipped `.github/copilot-instructions.md`.
   Delete it only if it contains nothing but the prompt-forge startup sequence.

6. **Review the instruction files.** Your `AGENTS.md` or `CLAUDE.md` may still
   contain the 1.x startup sequence ("load the developer skill every session").
   Delete it; the block between the `prompt-forge:start` and `prompt-forge:end`
   markers replaces it.

7. **Set up the team pieces** in [team-setup.md](team-setup.md): CODEOWNERS, the
   pull request checklist line, and a curation routine.
