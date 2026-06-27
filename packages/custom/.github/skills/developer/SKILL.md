---
name: developer
description: |
  Continuous issue tracking at the end of every coding iteration. Scans the
  chat for errors, API discoveries, workarounds, and patterns. Cross-references
  with the issue registry and creates or updates issues in knowledge/issues/open/.
  Safe and non-destructive — NEVER promotes issues, NEVER modifies skills or
  memory files. Runs by default at session end or when the user says "analyze
  this session", "what did we learn", or "save lessons".
disable-model-invocation: false
license: MIT
metadata:
  author: pablodiazjorge
  url: https://github.com/pablodiazjorge/prompt-forge
  version: "1.0"
  tokens: "1.2k"
---

# Developer: Continuous Issue Tracking

## Trigger

Run at the END of every significant coding iteration OR when the user explicitly
requests it. Do NOT run mid-task — wait for a natural stopping point.

This skill is loaded by default at session start. It is safe and non-destructive:
it only writes to `knowledge/issues/open/` and `knowledge/issues/INDEX.md`.

## Algorithm

### Phase 1 — Scan Current Chat

Review the current conversation for these signal types:

| Signal | Examples | Priority |
|--------|----------|----------|
| **Error fixed** | "PowerShell interpretó `{{ }}` mal", "ngx-translate v18 no tiene `forRoot()`" | HIGH |
| **API discovery** | "`linkedSignal` requires Node ≥22", "`provideZonelessChangeDetection()` is stable in Angular 22" | HIGH |
| **Workaround found** | "Usa `create_file` en vez de `Set-Content` para templates" | MEDIUM |
| **Pattern repeated** | Same error occurred 2+ times in this session alone | HIGH |
| **Project quirk** | "Este monorepo usa npm workspaces", "El `.gitignore` excluye `.github/`" | MEDIUM |
| **Tool limitation** | "Copilot no expone `usage.prompt_tokens` directamente" | LOW |
| **User preference** | "Prefiere comandos separados con `;` no `&&`" | MEDIUM |

### Phase 2 — Cross-Reference with Issue Registry

1. **Read `knowledge/issues/INDEX.md`** — get all existing issue IDs, titles, categories
2. **For each signal from Phase 1**, attempt to match against existing issues:
   - Match by keyword overlap (title + description)
   - Match by category + similar error pattern
   - Use `grep_search` on `knowledge/issues/open/` for related content

### Phase 3 — Create or Update Issues

#### NEW issue (no match found)
```
Generate ID: ISSUE-YYYYMMDD-XXXX where XXXX = first 4 hex chars of a UUID
  PowerShell: [guid]::NewGuid().ToString().Substring(0, 4)
  Example: ISSUE-20260624-a1b2
Create knowledge/issues/open/ISSUE-YYYYMMDD-XXXX.md using TEMPLATE.md
Set occurrences=1, certainty=low, status=open
Set created_by to "developer" (or current agent identifier)
Insert a new row into INDEX.md → Open Issues table
If you have session token data, optionally add it to Evidence section
```
IDs are UUID-based — no need to read INDEX.md first. Zero collision risk
across multiple developers working simultaneously.

#### UPDATE existing issue (match found)
```
Increment occurrences by 1
Update last_seen to today's date
Append current session info to sessions array
Re-evaluate certainty:
  - 1 occurrence → low
  - 2 occurrences → medium
  - 3+ occurrences → high
Update the issue file in open/ using replace_string_in_file
Update INDEX.md counts and row data
```

#### INDEX.md merge conflicts
If two developers add rows to INDEX.md simultaneously, a Git merge
conflict will occur on the table body. Resolution: keep ALL rows from
both branches; re-count directories to update Summary numbers.

### Report

Output a summary table:

```
## Developer Report — YYYY-MM-DD

| Action | ID | Title | Category | Detail |
|--------|----|-------|----------|--------|
| 🆕 New | ISSUE-001 | ... | ... | Created in open/ |
| 📈 Updated | ISSUE-002 | ... | ... | 1→2 occurrences, certainty low→medium |
```

## Important Rules

1. **NEVER promote issues.** Promotion is the responsibility of the
   `ai-engineer` skill. Your only output is issue files in `open/` and
   updates to `INDEX.md`.

2. **NEVER modify skills or memory files.** You are a read-only observer
   of `.github/skills/` and `/memories/`. Do not touch them.

3. **NEVER create a skill for something the model already knows** — if it's
   common knowledge (e.g., "use `const` not `var`"), skip it entirely.

4. **Keep issue files concise** — the TEMPLATE.md format is the maximum, not
   the minimum. Don't write essays.

5. **Session isolation** — the `sessions` array in frontmatter stores session
   UUIDs. Use `session_store_sql` to find the current session UUID if available,
   otherwise use a date-based identifier.

6. **Always populate `created_by`** — set it to the agent name or session
   identifier so the `ai-engineer` can trace issue origins during review.

## Handoff to AI Engineer

When an issue reaches `certainty: high` (3+ occurrences), the `ai-engineer`
skill handles promotion. The `developer` skill does NOT decide what to promote
or where — it only records the signal strength. Run the `ai-engineer` skill as
a subagent when the user asks to organize knowledge, clean up issues, or
promote patterns.

## File Paths Reference

| Resource | Path |
|----------|------|
| Issue registry index | `knowledge/issues/INDEX.md` |
| Issue template | `knowledge/issues/TEMPLATE.md` |
| Open issues | `knowledge/issues/open/ISSUE-XXX.md` |
| Promoted issues | `knowledge/issues/promoted/ISSUE-XXX.md` |
| Discarded issues | `knowledge/issues/discarded/ISSUE-XXX.md` |
