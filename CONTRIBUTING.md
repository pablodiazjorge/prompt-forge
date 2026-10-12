# Contributing

Thanks for helping. prompt-forge is small on purpose, so the most valuable
contributions are corrections, evidence, and simplifications rather than new
features.

## Good first contributions

- **A fact that is wrong or stale.** Tools change monthly. Open an issue or pull
  request with the primary source (official docs, changelog, or the code).
- **A lesson your team promoted** that would help everyone, such as a PowerShell
  or git pitfall. Propose it for the shipped skills, with evidence.
- **An installer edge case**: a file layout the installer mishandles, with a test
  case.
- **Evaluation.** A reproducible way to measure whether promoted memory helps is
  the most wanted contribution. See [ROADMAP.md](ROADMAP.md).

## Layout

`template/` is exactly what the installer copies into a project. The skills'
source of truth is `template/.agents/skills/`, and `template/.claude/skills/` is
a generated copy. [AGENTS.md](AGENTS.md) describes the rest.

## Before you open a pull request

You need git, bash, and PowerShell (5.1 on Windows, or `pwsh` 7 anywhere).

```bash
pwsh scripts/sync-template.ps1      # regenerate template/.claude/skills
pwsh scripts/validate.ps1           # frontmatter, token counts, links
pwsh scripts/test-install.ps1       # installer tests (PowerShell)
bash scripts/test-install.sh        # installer tests (bash)
```

On Windows PowerShell 5.1, run each `.ps1` with
`powershell -ExecutionPolicy Bypass -File <script>`. Run the bash tests in Git
Bash: from PowerShell, plain `bash` usually starts WSL, which has its own git
configuration and line-ending behavior.

CI runs the same checks. If `validate.ps1` reports a token mismatch after you
edit a skill, copy the measured value into that skill's `metadata.tokens`.

## Conventions

- Skills follow the [Agent Skills specification](https://agentskills.io/specification).
  Keep custom keys under `metadata`.
- Name capabilities, not one vendor's tools ("the agent's file-edit tool").
- Add only what an agent would otherwise get wrong. Every line in a skill costs
  tokens for every user.
- Any change to the installers needs matching changes and tests in both
  `install.sh` and `install.ps1`.
- Design changes get an ADR in [architecture.md](architecture.md), and
  user-visible changes get a [CHANGELOG.md](CHANGELOG.md) entry.
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/), one
  logical change per commit.

## Disclosure

Much of this project, including documentation, was written with AI coding
agents and reviewed by a person. Contributions written with AI help are welcome
on the same terms: you are responsible for checking every claim and every line.
