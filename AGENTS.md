# Agent Instructions

This project uses **prompt-forge**: a set of Agent Skills plus a learning loop
that records recurring problems and promotes the confirmed ones into permanent
guidance.

This file is the single source of truth for agent instructions. It is read
natively by VS Code, GitHub Copilot, Codex, Cursor, Windsurf, Zed, Aider and
others. Claude Code reads it through the `@AGENTS.md` import at the top of
`CLAUDE.md`.

## Startup Sequence

1. **Discover the skills.** List the directories under this project's skills
   directory: `.claude/skills/` if it exists, otherwise `.github/skills/`. If
   your agent discovers skills natively, it has already done this — skip to
   step 3.

2. **Read only the frontmatter** of each `SKILL.md` — the block between the first
   two `---` delimiters. That is the `name` and `description`, about 100 tokens
   per skill. Do not read the bodies yet.

3. **Load on match.** Compare the task against each description. Read the full
   `SKILL.md` body only for the skills that match. This is progressive
   disclosure: discovery is cheap, bodies are not.

4. **`developer` is the exception** — load it immediately, every session. It
   handles issue tracking and applies to all work.

5. **Check for existing errors** before making changes. Use the agent's
   diagnostics if it has them, otherwise run the project's lint or build command.
   Fix what is already broken first.

## During the Session

- Run the `developer` skill at the end of every significant iteration, or when
  the user signals a task is done. It records issues in `knowledge/issues/open/`
  and never promotes or modifies skills.
- Run `ai-engineer` as a subagent when the user asks to organize knowledge, clean
  up issues, or promote patterns. It is the only role allowed to promote,
  discard, or edit skills.
- When you hit an error, an API change, or a workaround worth remembering, note
  it. `developer` will formalize it into the registry at the end of the session.

## Terminal on Windows

These rules are ambient — they apply even when the `powershell-patterns` skill
has not been triggered. Load that skill for the full set.

- `powershell.exe` is Windows PowerShell 5.1; `pwsh` is PowerShell 7.x. Check
  `$PSVersionTable.PSVersion` before using `&&`, `||`, or ternary syntax — they
  are 7.x only and are a parser error in 5.1. Sequence with `;`, or
  `cmd1; if ($?) { cmd2 }` when the second command depends on the first.
- Check `$LASTEXITCODE` after a native executable. Do not infer success from
  stdout.
- Never write files containing `{{ }}` or `${{ }}` through shell redirection or
  an interpolating here-string. Use the agent's file-creation or edit tool.
- Never run a cmdlet that blocks on stdin (`Read-Host`, `Get-Credential`,
  `pause`) or opens an editor. The agent shell has no usable stdin.

## Git

Conventional Commits v1.0.0. One logical change per commit.

```
feat:     New feature
fix:      Bug fix
docs:     Documentation
chore:    Build, deps, tooling
refactor: Code change, no fix or feature
test:     Adding or correcting tests
```

Branch naming: `feature/<name>`, `fix/<name>`, `docs/<name>`, `chore/<name>`.

See the `git-workflow` skill for breaking changes, stacked PRs, and worktrees.

## After Each Session

1. Run the `developer` skill to capture learnings into the issue registry.
2. Commit changes to `knowledge/` and any updated skills.
