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
  version: "1.0"
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

## Algorithm

### Phase 0 — Discovery (NEW)

Before doing anything else, get a complete picture of the registry:

1. **Read `knowledge/issues/INDEX.md`** — get all issue IDs, titles, categories,
   certainties, and occurrence counts
2. **Read every issue file in `open/`** — full content of each
3. **Read every issue file in `promoted/`** — to avoid re-promoting
4. **Read every issue file in `discarded/`** — to detect re-emerging patterns
   (if a discarded issue appears again, it may need re-evaluation)

### Phase 1 — Deduplication (NEW)

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

### Phase 2 — Recategorization (NEW)

Review issues with `category: unknown` or potentially miscategorized entries:

1. **Read each `unknown` issue** and attempt to classify:
   - Look for language/framework names → `library-api`
   - Look for shell/terminal commands → `powershell`
   - Look for Angular-specific patterns → `angular`
   - Look for Git operations → `git`
   - Look for project-specific paths/conventions → `project-specific`
2. **Update the `category` field** in the issue frontmatter
3. **Update `INDEX.md`** to reflect the new category
4. **If still unclear**, leave as `unknown` and add a note:
   ```
   ## Recategorization Attempt — YYYY-MM-DD
   Unable to classify. Evidence: [summary]. Reviewed by: ai-engineer.
   ```

Also scan non-unknown issues for obvious miscategorization and fix if
the correct category is unambiguous.

### Phase 3 — Evaluate Promotion Criteria

For each issue with `certainty: high` (3+ occurrences):

| Category | Promotion Target | Action |
|----------|-----------------|--------|
| `library-api` | `/memories/<lib>-api.md` | Check if memory file exists; if so, `str_replace` to add. If not, `create`. |
| `powershell` | `powershell-patterns/SKILL.md` | `replace_string_in_file` to add new pitfall/pattern. |
| `angular` | `/memories/` or angular skill | If Angular-specific API version info → user memory. If scaffold pattern → angular-scaffold skill. |
| `git` | `git-workflow/SKILL.md` | `replace_string_in_file` to add new pattern. |
| `skill-creation` | New `.github/skills/<name>/SKILL.md` | Load `skill-creator` skill and follow its procedure to create a new skill from scratch. |
| `project-specific` | `/memories/repo/` | Create or update repo memory file. |
| `unknown` | — | Do NOT promote. Leave in `open/` with recategorization note. |

After promotion:
1. Move issue file from `open/` to `promoted/`
2. Update issue frontmatter: `status: promoted`, add `reviewed_by: "ai-engineer"`,
   add resolution date
3. Update `INDEX.md`: remove from Open, add to Promoted table with `Reviewed By`

### Phase 4 — Periodic Cleanup

For issues in `open/` with:
- `occurrences: 1` AND `first_seen > 30 days ago`
- `certainty: low`

→ Move to `discarded/`, update status to `discarded`, set
`reviewed_by: "ai-engineer"`, add reason: "Single occurrence, >30 days without recurrence."

For issues previously discarded that have re-emerged (found new evidence in
Phase 0), move back to `open/` and increment occurrences.

### Phase 5 — Report

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
| 📦 Promoted | ISSUE-003 | powershell | powershell-patterns/SKILL.md | 3 |

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

2. **ALWAYS get user confirmation before promoting to a skill** — use
   `vscode_askQuestions` to ask: "I found pattern X occurring 3 times.
   Promote to a skill?" Unless the user previously said "always auto-promote."

3. **Prefer updating existing skills over creating new ones** — a new pitfall
   in PowerShell belongs in `powershell-patterns/SKILL.md`, not a new skill.

4. **When creating a new skill, load `skill-creator`** — the `skill-creator`
   skill has the full procedure for creating skills per the agentskills.io
   spec and prompt-forge conventions. Follow it exactly.

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
| User memory | `/memories/<topic>.md` |
| Repo memory | `/memories/repo/<topic>.md` |
| Skills | `.github/skills/<name>/SKILL.md` |
| Sync script | `sync-skills.ps1` |
