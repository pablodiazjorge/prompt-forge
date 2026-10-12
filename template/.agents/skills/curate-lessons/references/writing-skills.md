# Writing a Team Skill

Read this only when a lesson is promoted to a new skill (rung 4). Most lessons
belong in `knowledge/memory/`; a skill is for a multi-step procedure that would
not fit in a few memory lines.

## Location

Create `.agents/skills/<name>/SKILL.md`. If the repository also has
`.claude/skills/`, copy the same directory there, because Claude Code reads only
that location. The directory name must equal the `name` field.

## Frontmatter

The [Agent Skills specification](https://agentskills.io/specification) defines
these fields and no others:

| Field | Required | Rule |
|---|---|---|
| `name` | Yes | 1-64 characters: lowercase letters, digits, single hyphens; no leading or trailing hyphen |
| `description` | Yes | 1-1024 characters; says what the skill does and when to use it |
| `license` | No | License name or bundled license file |
| `compatibility` | No | Up to 500 characters of environment requirements |
| `metadata` | No | Map of string keys to string values |
| `allowed-tools` | No | Experimental; space-separated pre-approved tools |

`disable-model-invocation: true` is a client extension, not part of the
specification. Claude Code, VS Code, and Cursor honor it to make a skill load
only on explicit request; other clients ignore it. Use it only for skills that
must never run on their own.

prompt-forge skills also set `metadata.author`, `metadata.url`,
`metadata.version`, and `metadata.tokens`. Team skills may omit them.

## Description

The description is all an agent sees when it decides whether to load the skill.

- State what the skill does and when to use it, with the words a user or task
  would actually contain ("Use when deploying to staging, editing
  `deploy/*.yaml`, or when a deploy fails").
- Write in the third person. Do not describe the implementation.
- Keep it to a few sentences.

## Body

- Add only what the agent lacks: project conventions, non-obvious steps, and
  gotchas. Do not explain what the agent already knows.
- Prefer a procedure (numbered steps, a checklist) to a list of facts.
- Give one default; mention an alternative only when it is genuinely needed.
- Keep the body under 500 lines and 5,000 tokens. Move long reference material
  to `references/<topic>.md`, one level deep, and say when to read it.
- Avoid dates and version numbers that will go stale, unless the skill exists to
  record them.
- Use forward slashes in paths.

## Measure

Estimate tokens as body characters divided by 4 (the body is the text after the
second `---`), rounded to 0.1k:

```bash
awk 'c>=2{n+=length($0)+1} /^---$/{c++} END{printf "%.1fk\n", n/4000}' SKILL.md
```

```powershell
$t = (Get-Content SKILL.md -Raw -Encoding UTF8) -replace "`r", ''
[Math]::Round((($t -split "(?m)^---[ \t]*$", 3)[2].Length / 4000), 1)
```

To validate the frontmatter against the specification, run
`skills-ref validate <dir>` from the
[agentskills reference library](https://github.com/agentskills/agentskills) if
Python is available. It rejects client extensions such as
`disable-model-invocation`; that error is expected.

## Checklist

- [ ] Directory name equals `name`
- [ ] `description` says what and when, in under 1024 characters
- [ ] No content the agent already knows
- [ ] Body under 500 lines; long material moved to `references/`
- [ ] Copied to `.claude/skills/` if that directory exists
- [ ] Added in the curation pull request, listed in its report
