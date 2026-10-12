# Project Memory

Promotion targets for confirmed knowledge that does not belong in a skill.

The `ai-engineer` skill writes here during Phase 5 (Promotion), following the
category routing table in [../issues/INDEX.md](../issues/INDEX.md):

| File | Holds |
|------|-------|
| `<lib>-api.md` | Version-specific API facts for a dependency (`library-api`) |
| `<framework>-pitfalls.md` | Conventions and lifecycle gotchas of the project's framework (`framework`) |
| `repo.md` | Quirks scoped to this repository only (`project-specific`) |

Why here and not a skill: these files are short, factual, and stack-specific.
Skills teach a procedure and are worth their trigger cost across projects; memory
files record facts that only matter inside this repository.

Why in the repo and not in agent-local memory: this directory is version
controlled, so the whole team inherits each discovery. Machine-local agent memory
is not shared.

Keep each file short. If one grows past roughly 50 lines, that is a signal the
knowledge has become a procedure — promote it to a skill via `skill-creator`.
