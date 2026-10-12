---
name: ai-engineer
description: |
  On-demand knowledge organization agent. Reviews ALL issues in the registry,
  deduplicates similar entries, recategorizes unknowns, promotes confirmed
  patterns (3+ occurrences) to skills or memory files, and cleans up stale
  single-occurrence issues. Designed to run as a subagent — invoke explicitly
  when the user says "organize knowledge", "clean up issues", "promote patterns",
  or "run ai-engineer".
disable-model-invocation: true
license: MIT
metadata:
  author: pablodiazjorge
  url: https://github.com/pablodiazjorge/prompt-forge
  version: "2.0"
  tokens: "1.8k"
---

# AI Engineer: Knowledge Organization & Promotion

## Trigger

This skill runs **on-demand only** (not automatically). Invoke it as a subagent
when:

- The user explicitly asks to "organize knowledge", "clean up issues",
  "promote patterns", or "run ai-engineer"
- A natural stopping point has been reached and there are accumulated issues
  in `open/` that need review
- The user wants to deduplicate or recategorize the issue registry

This skill is designed to run as a **subagent** with a dedicated context window.
It should review ALL issues, not just those from the current session.

## Where You Sit in the Loop

The learning loop has six phases. The `developer` skill owns Phases 1-3
(detection, cross-reference, recording) and never mutates anything outside
`knowledge/issues/`. You own Phases 4-6 and you are the only role permitted to
promote, discard, or edit skills.

## Phase 4 — Curation

### 4a. Discovery

Before doing anything else, get a complete picture of the registry:

1. **Read `knowledge/issues/INDEX.md`** — all issue IDs, titles, categories,
   certainties, and occurrence counts
2. **Read every issue file in `open/`** — full content of each
3. **Read every issue file in `promoted/`** — to avoid re-promoting
4. **Read every issue file in `discarded/`** — to detect re-emerging patterns
   (if a discarded issue appears again, it may need re-evaluation)

### 4b. Deduplication

Before promoting or recategorizing, eliminate duplicates:

1. **Group issues by keyword overlap** on title + description
2. **Within each group**, identify the oldest issue (by `first_seen`)
3. **For each duplicate**, add a note to its file:
   ```
   ## Resolution
   Merged into ISSUE-YYYYMMDD-XXXX (duplicate detected via keyword overlap)
   ```
4. **Move duplicate files** from `open/` to `discarded/`
5. **Update `INDEX.md`**: remove duplicates from Open, add to Discarded with
   reason "Merged into ISSUE-YYYYMMDD-XXXX"
6. **Increment occurrences** on the canonical issue to reflect all instances

Deduplication uses heuristic keyword matching — it may miss some duplicates
or flag false positives. When uncertain, leave both issues in `open/` and
add a note for manual review.

### 4c. Recategorization

Review issues with `category: unknown` or potentially miscategorized entries:

1. **Read each `unknown` issue** and attempt to classify:
   - A specific library's API changed → `library-api`
   - Shell, terminal, or scripting behavior → `powershell`
   - A framework's conventions or lifecycle → `framework`
   - Git operations → `git`
   - Project-specific paths or conventions → `project-specific`
   - A recurring domain with no existing skill → `skill-creation`
2. **Update the `category` field** in the issue frontmatter
3. **Update `INDEX.md`** to reflect the new category
4. **If still unclear**, leave as `unknown` and add a note:
   ```
   ## Recategorization Attempt — YYYY-MM-DD
   Unable to classify. Evidence: [summary]. Reviewed by: ai-engineer.
   ```

Also scan non-unknown issues for obvious miscategorization and fix if
the correct category is unambiguous.

## Phase 5 — Promotion

For each issue with `certainty: high` (3+ occurrences), route it using the
category table in `knowledge/issues/INDEX.md`. **That table is the single source
of truth for promotion targets** — read it rather than relying on memory, because
it is meant to grow as new categories emerge.

Whatever the target:

- To extend an existing skill, use the agent's targeted-edit tool and add a new
  section rather than rewriting the file. Re-read the file immediately before
  editing; another session may have changed it.
- To create a new skill, **load `skill-creator` first** and follow its procedure.
- To write a memory file, create it if absent, append a section if present.

After promotion:

1. Move issue file from `open/` to `promoted/`
2. Update issue frontmatter: `status: promoted`, add `reviewed_by: "ai-engineer"`,
   add resolution date
3. Update `INDEX.md`: remove from Open, add to Promoted table with `Reviewed By`

## Phase 6 — Cleanup

For issues in `open/` with:
- `occurrences: 1` AND `first_seen > 30 days ago`
- `certainty: low`

→ Move to `discarded/`, update status to `discarded`, set
`reviewed_by: "ai-engineer"`, add reason: "Single occurrence, >30 days without recurrence."

For issues previously discarded that have re-emerged (found new evidence in
Phase 4a), move back to `open/` and increment occurrences.

## Report

Output a comprehensive summary table:

```
## AI Engineer Report — YYYY-MM-DD

### Deduplication
| Action | Duplicate ID | Merged Into | Reason |
|--------|-------------|-------------|--------|
| 🔗 Merged | ISSUE-005 | ISSUE-001 | Keyword overlap on title |

### Recategorization
| ID | Title | Old Category | New Category |
|----|-------|-------------|--------------|
| 🔄 Recategorized | ISSUE-006 | unknown | powershell |

### Promotion
| ID | Title | Category | Promoted To | Occurrences |
|----|-------|----------|-------------|-------------|
| 📦 Promoted | ISSUE-003 | powershell | powershell-patterns skill | 3 |

### Cleanup
| ID | Title | Action | Reason |
|----|-------|--------|--------|
| 🗑️ Discarded | ISSUE-004 | → discarded/ | >30 days, single occurrence |

### Registry Summary
| Status | Before | After |
|--------|--------|-------|
| 🔴 Open | 12 | 8 |
| 🟢 Promoted | 2 | 3 |
| ⚫ Discarded | 1 | 4 |
```

## Important Rules

1. **Review ALL issues, not just recent ones.** Unlike `developer` which only
   looks at the current session, the AI Engineer has a global view.

2. **ALWAYS get user confirmation before promoting to a skill** — use the agent's
   question mechanism to ask: "I found pattern X occurring 3 times. Promote to a
   skill?" Unless the user previously said "always auto-promote."

3. **Prefer updating existing skills over creating new ones** — a new shell
   pitfall belongs in the `powershell-patterns` skill, not a new skill.

4. **When creating a new skill, load `skill-creator`** — it has the full procedure
   per the agentskills.io spec and prompt-forge conventions. Follow it exactly.

5. **Set `reviewed_by` on every issue you touch** — this provides an audit
   trail. Use `reviewed_by: "ai-engineer"` for automated reviews.

6. **Run `sync-skills.ps1` after modifying skills** — if you promote to a
   skill file or create a new skill, sync the changes to all packages.

7. **Be conservative with deduplication** — two issues that look similar may
   be describing different aspects of the same problem. When uncertain, leave
   both in `open/` and add cross-reference notes instead of merging.

## File Paths Reference

| Resource | Path |
|----------|------|
| Issue registry index | `knowledge/issues/INDEX.md` |
| Issue template | `knowledge/issues/TEMPLATE.md` |
| Open issues | `knowledge/issues/open/ISSUE-XXX.md` |
| Promoted issues | `knowledge/issues/promoted/ISSUE-XXX.md` |
| Discarded issues | `knowledge/issues/discarded/ISSUE-XXX.md` |
| Project memory | `knowledge/memory/<topic>.md` |
| Skills | the project's skills directory (see `AGENTS.md` / `CLAUDE.md`) |
| Sync script | `sync-skills.ps1` |
