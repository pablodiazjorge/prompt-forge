---
name: powershell-patterns
description: Pitfalls and safe patterns for running commands and writing scripts in Windows PowerShell 5.1 and PowerShell 7.x. Use when running terminal commands on Windows, writing or debugging .ps1 scripts, chaining commands, checking the exit code of a native executable, writing files that contain $ or template syntax, handling file encodings, or switching toolchain versions.
license: MIT
metadata:
  author: pablodiazjorge
  url: https://github.com/pablodiazjorge/prompt-forge
  version: "2.0.0"
  tokens: "1.7k"
  sources: "https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_parsing, https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_character_encoding, https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_preference_variables, https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies"
---

# PowerShell Patterns

`powershell.exe` is **Windows PowerShell 5.1**: preinstalled, and what an agent
terminal usually gets. `pwsh` is **PowerShell 7.x**, a separate install. Check
`$PSVersionTable.PSVersion` before using modern syntax.

## 5.1 versus 7.x

| Feature | Windows PowerShell 5.1 | PowerShell 7.x |
|---|---|---|
| `&&` and `\|\|` | Parser error | 7.0+ |
| Ternary `a ? b : c`, `??`, `??=` | Not available: use `if`/`else` and `$null -eq $x` | 7.0+ |
| Null-conditional `?.` | Not available | 7.1+, written `${x}?.Prop` because `?` is legal in variable names |
| `ConvertFrom-Json -AsHashtable` | Not available (returns `PSCustomObject`) | 6.0+ |
| `curl`, `wget` | Aliases for `Invoke-WebRequest`: call `curl.exe` | Real executables |

Sequencing on either edition:

```powershell
cmd1; cmd2                # always runs cmd2
cmd1; if ($?) { cmd2 }    # runs cmd2 only if cmd1 succeeded
```

## Native executables

- Test `$LASTEXITCODE` after a build, test runner, linter, or `git`:
  `dotnet build; if ($LASTEXITCODE -ne 0) { throw "build failed" }`.
  Do not infer success from the output.
- **5.1:** redirecting a native command's stderr (`2>&1`, `2>$null`) turns each
  stderr line into an error record. Under `$ErrorActionPreference = 'Stop'` that
  throws even when the program exits 0, and `$?` can be false. Leave stderr
  alone, or run the call with `Continue` and judge by `$LASTEXITCODE`:
  `& { $ErrorActionPreference = 'Continue'; git fetch 2>&1 }`.
- **7.2+:** redirected stderr no longer triggers `$ErrorActionPreference`.
  **7.4+:** set `$PSNativeCommandUseErrorActionPreference = $true` to make a
  non-zero exit code throw.
- **7.3+ changed argument passing** (`$PSNativeCommandArgumentPassing`): empty
  strings and embedded double quotes now reach the program intact, while 5.1
  drops or mangles them. A command line that works in one edition can break in
  the other. Avoid embedded quotes in native arguments; pass complex values
  through a file.
- Plain `bash` usually resolves to WSL (`C:\Windows\System32\bash.exe`), not
  Git Bash. WSL has its own git, git config, and line-ending handling, so a
  script that commits from there fails or sees phantom changes. Check with
  `Get-Command bash -All` and call Git Bash explicitly:
  `& "C:\Program Files\Git\bin\bash.exe" script.sh`.
- `-ErrorAction SilentlyContinue` hides the error output; the command still
  failed. `try`/`catch` catches only terminating errors, so add
  `-ErrorAction Stop` to a cmdlet you want to catch.

## Quoting

- The escape character is the backtick. `\` is literal, so Windows paths need no
  escaping.
- Launch an executable whose path has spaces with the call operator:
  `& "C:\Program Files\App\app.exe" --flag`.
- Quote arguments that contain `@{`, `{`, `}`, `(`, `)`, `;`, `,`, `$`, or a
  backtick. `git rev-parse @{u}` is a parser error; `git rev-parse '@{u}'` works.
- `--%` passes the rest of the line verbatim, up to a `|` or the end of the line,
  still expanding `%VAR%`: `icacls .\data --% /grant Users:(OI)(CI)R`.
- There is no inline `VAR=x cmd`. Use `$env:VAR = 'x'; cmd`.

## Writing files

Double-quoted strings and here-strings silently expand `$name`, `$env:X`, and
`$(...)`: a workflow line such as `echo "x=1" >> $GITHUB_OUTPUT` is written with
an empty variable. `${{ ... }}` inside them is a parser error, so nothing is
written at all. `{{ }}` without a `$` (Jinja, Handlebars, Helm) is literal.

```powershell
# BAD: $GITHUB_OUTPUT is expanded to an empty string
Set-Content ci.yml "      run: echo 'x=1' >> $GITHUB_OUTPUT"

# OK: a single-quoted here-string is literal; the closing '@ must be at column 0
Set-Content ci.yml -Encoding utf8 @'
      run: echo 'x=1' >> $GITHUB_OUTPUT
      env: { TOKEN: ${{ secrets.TOKEN }} }
'@
```

Better: write files with the agent's own file-creation or edit tool. It writes
bytes verbatim and avoids both expansion and encoding problems.

`New-Item -Force` on an existing file **truncates it**. There is no `touch`:
`if (-not (Test-Path p)) { New-Item -ItemType File p }`.

## Encoding (5.1)

| Command | Default output encoding in 5.1 |
|---|---|
| `Out-File`, `>`, `>>` | UTF-16LE |
| `Set-Content`, `Add-Content` | The system ANSI code page |
| Any of them with `-Encoding UTF8` | UTF-8 **with** a byte-order mark |
| `Get-Content` on a file without a BOM | Reads it as ANSI: pass `-Encoding UTF8` |

For UTF-8 without a BOM in 5.1, use
`[IO.File]::WriteAllText((Join-Path $PWD 'f.txt'), $text)`. Give .NET methods a
full path: they resolve relative paths against the process directory, not the
current PowerShell location. PowerShell 7 defaults to UTF-8 without a BOM
everywhere.

## Never block a non-interactive shell

Agent shells have no usable stdin. These hang until timeout instead of prompting:

- `Read-Host`, `Get-Credential`, `Out-GridView`, `pause`,
  `$Host.UI.PromptForChoice`.
- Cmdlets that ask for confirmation (`Remove-Item` on a directory,
  `Stop-Process`): pass `-Confirm:$false` when the action is intended, and
  `-Force` for read-only or hidden items.
- Anything that opens an editor, such as `git commit` without `-m`.

Start long-running servers with `Start-Process`, or the agent's background
command feature, so the shell returns. Do not poll with `Start-Sleep` loops.

## Execution policy

Windows PowerShell 5.1 defaults to `Restricted` on Windows client editions (no
`.ps1` runs) and `RemoteSigned` on Windows Server; the PowerShell 7 docs give
`RemoteSigned` as the Windows default. Run a script for one invocation without
persisting anything:

```powershell
powershell -ExecutionPolicy Bypass -File .\script.ps1
```

Never change the policy at the `CurrentUser` or `LocalMachine` scope without the
user's explicit approval. It is a persistent security setting.

## Toolchain version managers

nvm-windows, pyenv-win, rustup, and the .NET SDK (`global.json`) each switch
versions differently. nvm-windows swaps a symlink, pyenv-win uses shims, rustup
uses proxy binaries, and `dotnet` reads `global.json` per directory. What
transfers:

1. Installing a version does not activate it. Run the manager's `use` or
   `global` step, or pin the version in the file the toolchain reads.
2. PATH changes apply to new processes. Start a new shell after switching.
3. Verify the binary that actually resolves, not the manager's report:
   `(Get-Command node).Source; node --version`.

## Unix equivalents

| Unix | PowerShell |
|---|---|
| `head -n N` / `tail -n N` | `Get-Content f -TotalCount N` / `-Tail N`; piped: `Select-Object -First N` / `-Last N` |
| `which x` | `(Get-Command x).Source` |
| `wc -l` | `(Get-Content f \| Measure-Object -Line).Lines` |
| `mkdir -p` | `New-Item -ItemType Directory -Force p` |
| `rm -rf` | `Remove-Item -Recurse -Force p` |
| `grep -r x .` | `Get-ChildItem -Recurse -File \| Select-String -Pattern x` |

Prefer full cmdlet names over aliases in scripts, and cap long output with
`Select-Object -First N`.
