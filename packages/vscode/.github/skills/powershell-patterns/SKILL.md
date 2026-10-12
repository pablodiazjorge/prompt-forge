---
name: powershell-patterns
description: |
  PowerShell patterns, pitfalls, and cmdlet choices for Windows development,
  covering both Windows PowerShell 5.1 and PowerShell 7.x. Use when running
  terminal commands on Windows, writing or debugging .ps1 scripts, chaining
  commands, checking the exit code of a build or test executable, escaping
  template syntax in generated files, or activating a toolchain version manager.
license: MIT
metadata:
  author: pablodiazjorge
  url: https://github.com/pablodiazjorge/prompt-forge
  version: "2.0"
  tokens: "1.2k"
  sources: "learn.microsoft.com/powershell: about_Parsing, about_Quoting_Rules, about_Execution_Policies, about_Automatic_Variables"
---

# PowerShell Patterns

`powershell.exe` is **Windows PowerShell 5.1** (preinstalled, what an agent
terminal usually gets). `pwsh` is **PowerShell 7.x**, a separate install. Check
`$PSVersionTable.PSVersion` before using modern syntax: Major 5 means every rule
below applies, Major 7 lifts most of them.

## 5.1 vs 7.x

| Feature | Windows PowerShell 5.1 | PowerShell 7.x |
|---|---|---|
| `&&` / `\|\|` chain operators | Parser error | Supported |
| Ternary `? :`, `??`, `??=`, `?.` | Not available (use `if/else`, `$null -eq`) | Supported |
| `ConvertFrom-Json -AsHashtable` | Not available (returns PSCustomObject) | Supported |
| `Set-Content`/`Out-File` encoding | ANSI codepage — pass `-Encoding utf8` | UTF-8, no BOM |

Sequencing on both editions:

```powershell
cmd1; cmd2                # unconditional
cmd1; if ($?) { cmd2 }    # only if cmd1 succeeded
```

## Exit Codes and Errors

- `$LASTEXITCODE` is the exit code of the last **native executable** — the thing to
  test after a build, test run, or linter: `dotnet build; if ($LASTEXITCODE) { throw }`.
- `$?` is per-command success, but unreliable around native exes: `2>&1` in 5.1
  wraps each stderr line in a `NativeCommandError` record and can make `$?` false
  even when the exe exited 0. Prefer `2>$null`, or leave stderr alone.
- `-ErrorAction SilentlyContinue` suppresses error *output*; the command still failed.
- `try/catch` catches only terminating errors; add `-ErrorAction Stop` to make a
  cmdlet failure catchable.

## Quoting, Escaping, Environment

- Escape char is a backtick; `\` is literal, so Windows paths need no escaping.
- Quote paths with spaces and launch executables with the call operator:
  `& "C:\Program Files\App\app.exe" --flag`.
- `--%` stops PowerShell parsing the rest of the line: `git log --% --format=%H`.
- No inline `VAR=x cmd` prefix. Use `$env:VAR = 'x'; cmd`.

### Files containing `{{ }}`, `${{ }}`, or `$`

Template syntax (Jinja2, Handlebars, Mustache, Liquid, Django, Go templates, Vue,
Helm, GitHub Actions) collides with PowerShell interpolation.

```powershell
# BAD — $ and {{ }} are expanded or mangled
Set-Content f.yml @"
value: {{ name }}
"@

# OK — literal here-string; the closing '@ MUST be at column 0
Set-Content f.yml -Encoding utf8 @'
value: {{ name }}
'@
```

Better: use the agent's native file-creation/edit tool (`Write`, `create_file`, or
the harness equivalent) instead of shell redirection — it writes bytes verbatim.

`New-Item -Force` on an existing file **truncates it**. There is no `touch`; use
`if (-not (Test-Path p)) { New-Item -ItemType File p }`.

## Never Block a Non-Interactive Shell

An agent shell has no usable stdin: these hang until timeout instead of prompting.

- `Read-Host`, `Get-Credential`, `Out-GridView`, `pause`, `$Host.UI.PromptForChoice`
- Destructive cmdlets that confirm (`Remove-Item`, `Stop-Process`): pass
  `-Confirm:$false` when the action is intended, `-Force` for read-only/hidden items
- Anything that opens an editor (`git rebase -i`, `git commit` without `-m`)
- Never `Start-Sleep` to wait for work; the agent is notified when a command ends.
  Launch a long-lived server with `Start-Process` so the shell returns.

## Toolchain Version Managers

nvm-windows, pyenv-win, rustup, jabba, sdkman, `global.json` SDK pinning — all work
by rewriting PATH through a shim. Transferable rules:

1. **Install is not activate.** Run the manager's `use`/`global` step, or pin the
   version in the file the toolchain reads (`.nvmrc`, `.python-version`,
   `rust-toolchain.toml`, `global.json`).
2. **The current shell can be stale.** PATH edits apply to new processes; re-launch
   the shell — elevated, if the manager writes symlinks or machine PATH.
3. **Globally installed CLIs are per-version** and are not migrated on switch.
4. Verify against the resolved binary, not the manager: `(Get-Command tool).Source`.

## Unix Command Equivalents

| Unix | PowerShell |
|---|---|
| `head -n N` / `tail -n N` | `Get-Content f -TotalCount N` / `-Tail N`; piped: `Select-Object -First N` / `-Last N` |
| `which x` | `(Get-Command x).Source` |
| `wc -l` | `(Get-Content f \| Measure-Object -Line).Lines` |
| `mkdir -p` | `New-Item -ItemType Directory -Force p` |
| `rm -rf` | `Remove-Item -Recurse -Force p` |

Aliases (`ls`, `cat`, `curl`) exist but can be shadowed — use real cmdlet names.

## Execution Policy

Windows defaults to `Restricted`; `.ps1` files will not run.

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser     # no admin needed
powershell -ExecutionPolicy Bypass -File .\s.ps1        # one-shot, nothing persisted
```

## Habits

1. `Test-Path` before reading, writing, or changing directory.
2. `Push-Location` / `Pop-Location` instead of bare `Set-Location`.
3. `Select-Object -First N` on any command that can produce long output.
