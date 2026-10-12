# Security

## Reporting a vulnerability

Please report security problems privately through GitHub:
**Security → Report a vulnerability** on this repository. Do not open a public
issue for anything that could be exploited before a fix ships.

## Threat model

prompt-forge ships Markdown and two installer scripts. It runs no service and
makes no network requests. The risks come from what the files tell agents to do,
and from what teams commit into `knowledge/`.

| Risk | Mitigation in prompt-forge | What your team should do |
|---|---|---|
| **Secrets or personal data in lessons.** An agent copies a token, hostname, or customer detail into a committed lesson. | `record-lesson` must paraphrase, never paste logs or output, and replace hosts and secrets with placeholders. `curate-lessons` deletes lessons that contain them, but by then the lesson is already in git history. | Point your secret scanner at `knowledge/`. Review lessons in ordinary code review. If a secret got in, rotate it, and rewrite history if your policy requires. |
| **Prompt injection that persists.** Text from a web page, a dependency's README, or tool output gets recorded as a "lesson", then promoted into memory that every teammate's agent loads. | Lessons may only contain what the agent verified itself. The curator treats lesson text as data, rejects text that tries to change an agent's instructions or permissions, and rejects anything that tells agents to run code, weaken checks, or change permissions. A recurrence threshold alone is not a defense, because injected text can recur. | Require CODEOWNERS review on `knowledge/memory/`, `knowledge/README.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, and the skills directories, and enable "Require review from Code Owners". Read curation diffs, not just their summary. |
| **Hidden instructions** in committed files, such as invisible Unicode characters. | None automated yet. | Review diffs in a tool that shows invisible characters. A lint for this is on the [roadmap](ROADMAP.md). |
| **Installer overwriting files.** | The installers never overwrite user files. They merge marked blocks and import lines, and replace only prompt-forge's own skills, and only with `--upgrade`. Tests cover this. | Run `--dry-run` first and review `git diff` before committing. |

Skills do not grant an agent any capability it does not already have. Your
agent's own permission settings remain the real boundary.
