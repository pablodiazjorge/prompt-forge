---
name: git-workflow
description: Non-interactive git usage and commit conventions for AI coding agents. Use when staging changes, committing, writing commit messages, naming branches, splitting work into pull requests, rebasing, or checking out a pull request in a worktree for review.
license: MIT
metadata:
  author: pablodiazjorge
  url: https://github.com/pablodiazjorge/prompt-forge
  version: "2.1.0"
  tokens: "0.8k"
  sources: "https://www.conventionalcommits.org/en/v1.0.0/, https://github.com/conventional-changelog/commitlint/tree/master/%40commitlint/config-conventional, https://git-scm.com/docs"
---

# Git Workflow

## The team's rules win

Before applying the defaults below, look for the team's own conventions and
follow them instead: a commitlint config (`commitlint.config.*`,
`.commitlintrc*`), `CONTRIBUTING.md`, a pull request template, and the commit
history (`git log --oneline -20`).

## Never block on an editor or a prompt

An agent shell has no usable stdin, so interactive commands hang until they time
out.

| Instead of | Use |
|---|---|
| `git add -p`, `git add -i` | `git add <path>...` with explicit paths |
| `git commit` with no message | `git commit -m "<subject>" -m "<body>"`, or `-F <file>` for long messages |
| `git rebase -i` to squash fixes | `git commit --fixup <sha>`, then `git -c sequence.editor=true rebase -i --autosquash <base>`; for any other history edit, ask the user |
| `git rebase --continue` | `git -c core.editor=true rebase --continue` |
| `git merge` that opens an editor | `git merge --no-edit <branch>` |
| Paged output (`log`, `diff`, `show`) | `git --no-pager log -n 20 --oneline` |

## Safety

- Never pass `--no-verify`. A failing hook is a failing check: fix the cause.
- Never force-push a shared branch. When you must rewrite your own branch, use
  `git push --force-with-lease`.
- Read `git diff --cached` before every commit. Unstage anything that looks like
  a secret, a local config file, or an unrelated change.
- Do not commit to the default branch directly when the team works through pull
  requests. Create a branch first.

## Commits

One logical change per commit, staged by path.

Default to [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
with the `@commitlint/config-conventional` types. Whether a type other than
`feat` or `fix` triggers a release depends on the project's release tool, so
check its configuration rather than assuming.

## Branches

`<type>/<short-name>`, for example `feature/export-csv`, `fix/login-timeout`,
`docs/install-guide`, `chore/bump-deps`, `refactor/split-parser`, unless the team
uses another scheme.

## Pull requests

- Every pull request builds and passes its tests on its own. Tests ship with the
  code they cover, not in a later pull request.
- Split a large change along layers (types and schema, then logic, then the
  delivery surface) only when each step is reviewable and working by itself.
- When a base pull request in a stack is squash-merged, move the next branch
  onto the default branch with `git rebase --onto <default> <old-base> <branch>`.

## Reviewing a pull request in a worktree

```bash
git fetch origin pull/<n>/head:pr-<n>      # GitHub; GitLab uses merge-requests/<n>/head
git worktree add ../pr-<n> pr-<n>
# review, build, test in ../pr-<n>
git worktree remove ../pr-<n>
git branch -D pr-<n>
```

If your sandbox blocks writes outside the repository, put the worktree in a
git-ignored directory inside it instead.

## Before you commit

If the repository has a `knowledge/lessons/` directory and this task hit a
non-obvious failure that a teammate's agent would likely repeat, run the
`record-lesson` skill first, so the lesson ships in the same pull request.
