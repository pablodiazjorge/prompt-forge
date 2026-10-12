# Tests install.ps1 against throwaway project directories.
#   powershell -ExecutionPolicy Bypass -File scripts\test-install.ps1
# Runs on Windows PowerShell 5.1 and PowerShell 7.

$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$install = Join-Path $root 'install.ps1'
$work    = Join-Path ([IO.Path]::GetTempPath()) ("pf-test-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $work | Out-Null
$script:fails = 0
$script:out = ''

function Check([string]$Name, [scriptblock]$Test) {
    $ok = $false
    try { $ok = [bool](& $Test) } catch { $ok = $false }
    if ($ok) { Write-Host "  ok   $Name" } else { Write-Host "  FAIL $Name"; $script:fails++ }
}
# Run the installer with the same edition that runs this test (powershell or pwsh).
$shell = (Get-Process -Id $PID).Path
$policy = @()
if ([Environment]::OSVersion.Platform -eq 'Win32NT') { $policy = @('-ExecutionPolicy', 'Bypass') }
function Run([string[]]$InstallArgs) {
    # 5.1 turns redirected stderr into errors under 'Stop'; judge by the exit code.
    $ErrorActionPreference = 'Continue'
    $script:out = & $shell -NoProfile @policy -File $install @InstallArgs 2>&1 | Out-String
    $script:code = $LASTEXITCODE
}
function New-Project([string]$Name) {
    $p = Join-Path $work $Name
    New-Item -ItemType Directory -Path $p | Out-Null
    return $p
}
function Text([string]$Path) { return [IO.File]::ReadAllText($Path) }
function Put([string]$Path, [string]$Text) {
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [IO.File]::WriteAllText($Path, $Text)
}
function Count([string]$Pattern, [string]$Path) { return ([regex]::Matches((Text $Path), $Pattern)).Count }
function Tree-Hash([string]$Dir) {
    (Get-ChildItem -LiteralPath $Dir -Recurse -File -Force | Sort-Object FullName |
        ForEach-Object { $_.FullName + (Get-FileHash -LiteralPath $_.FullName).Hash }) -join '|'
}
function Same([string]$A, [string]$B) { return (Get-FileHash $A).Hash -eq (Get-FileHash $B).Hash }

try {
    Write-Host 'fresh install'
    $p = New-Project 'fresh'
    Run @('-Target', $p)
    Check 'AGENTS.md matches template'      { Same (Join-Path $root 'template/AGENTS.md') (Join-Path $p 'AGENTS.md') }
    Check 'CLAUDE.md and GEMINI.md created' { (Test-Path "$p/CLAUDE.md") -and (Test-Path "$p/GEMINI.md") }
    foreach ($s in 'record-lesson', 'curate-lessons', 'git-workflow', 'powershell-patterns') {
        Check "skill $s in .agents and .claude" { (Test-Path "$p/.agents/skills/$s/SKILL.md") -and (Test-Path "$p/.claude/skills/$s/SKILL.md") }
    }
    Check 'curator reference file copied'   { Test-Path "$p/.agents/skills/curate-lessons/references/writing-skills.md" }
    Check 'curate-lessons agent'            { Test-Path "$p/.claude/agents/curate-lessons.md" }
    Check 'knowledge skeleton'              { (Test-Path "$p/knowledge/README.md") -and (Test-Path "$p/knowledge/lessons/.gitkeep") -and (Test-Path "$p/knowledge/memory/.gitkeep") }

    Write-Host 're-run is a no-op'
    $before = Tree-Hash $p; Run @('-Target', $p); $after = Tree-Hash $p
    Check 'no file changed'                 { $before -eq $after }

    Write-Host 'CRLF checkouts of shipped files count as current'
    $f = "$p/.agents/skills/git-workflow/SKILL.md"
    Put $f ((Text $f) -replace "`n", "`r`n")
    Run @('-Target', $p)
    Check 'reported as current'               { $script:out -match 'current +\.agents/skills/git-workflow/' }

    Write-Host 'a start marker without an end marker is refused'
    $p = New-Project 'broken'
    $broken = "# X`n<!-- prompt-forge:start -->`nold text`n"
    Put "$p/AGENTS.md" $broken
    Run @('-Target', $p, '-Upgrade')
    Check 'installer exits non-zero'          { $script:code -ne 0 }
    Check 'AGENTS.md unchanged'               { (Text "$p/AGENTS.md") -eq $broken }
    Check 'nothing else written'              { -not (Test-Path "$p/.agents") -and -not (Test-Path "$p/knowledge") }

    Write-Host 'existing project files are merged, not overwritten'
    $p = New-Project 'existing'
    Put "$p/AGENTS.md" "# My project`n`nUse pnpm, not npm."
    Put "$p/CLAUDE.md" "Be terse.`n"
    Put "$p/knowledge/README.md" "custom policy`n"
    Put "$p/.agents/skills/record-lesson/SKILL.md" "locally edited`n"
    Run @('-Target', $p)
    Check 'AGENTS.md keeps project text'      { (Text "$p/AGENTS.md").StartsWith('# My project') -and (Text "$p/AGENTS.md").Contains('Use pnpm, not npm.') }
    Check 'AGENTS.md gets one block'          { (Count 'prompt-forge:start' "$p/AGENTS.md") -eq 1 }
    Check 'CLAUDE.md keeps text, imports'     { (Text "$p/CLAUDE.md").Contains('Be terse.') -and (Count '(?m)^@AGENTS\.md' "$p/CLAUDE.md") -eq 1 }
    Check 'knowledge/README.md untouched'     { (Text "$p/knowledge/README.md") -eq "custom policy`n" }
    Check 'edited skill kept without upgrade' { (Text "$p/.agents/skills/record-lesson/SKILL.md").Contains('locally edited') }
    Run @('-Target', $p)
    Check 'second run adds no second block'   { (Count 'prompt-forge:start' "$p/AGENTS.md") -eq 1 -and (Count '(?m)^@AGENTS\.md' "$p/CLAUDE.md") -eq 1 }

    Write-Host '-Upgrade replaces only prompt-forge content'
    Put "$p/AGENTS.md" ((Text "$p/AGENTS.md").Replace('Team knowledge (prompt-forge)', 'Old heading'))
    Run @('-Target', $p, '-Upgrade')
    Check 'block restored to template'        { (Text "$p/AGENTS.md").Contains('Team knowledge (prompt-forge)') -and -not (Text "$p/AGENTS.md").Contains('Old heading') }
    Check 'project text survives upgrade'     { (Text "$p/AGENTS.md").Contains('Use pnpm, not npm.') }
    Check 'skill replaced on upgrade'         { Same (Join-Path $root 'template/.agents/skills/record-lesson/SKILL.md') "$p/.agents/skills/record-lesson/SKILL.md" }
    Check 'knowledge/README.md still custom'  { (Text "$p/knowledge/README.md") -eq "custom policy`n" }

    Write-Host 'CRLF files stay CRLF'
    $p = New-Project 'crlf'
    Put "$p/AGENTS.md" "# Windows project`r`n`r`nRules.`r`n"
    Run @('-Target', $p)
    Check 'no bare LF in AGENTS.md'           { $t = Text "$p/AGENTS.md"; $t.Contains('prompt-forge:start') -and -not ($t -match "[^`r]`n") }

    Write-Host '-SkipClaude, -SkipGemini'
    $p = New-Project 'skip'
    Run @('-Target', $p, '-SkipClaude', '-SkipGemini')
    Check 'no CLAUDE.md, GEMINI.md, .claude/' { -not (Test-Path "$p/CLAUDE.md") -and -not (Test-Path "$p/GEMINI.md") -and -not (Test-Path "$p/.claude") }

    Write-Host '-DryRun writes nothing'
    $p = New-Project 'dry'
    Run @('-Target', $p, '-DryRun')
    Check 'directory still empty'             { @(Get-ChildItem -LiteralPath $p -Force).Count -eq 0 }

    Write-Host '1.x leftovers are reported, not touched'
    $p = New-Project 'legacy'
    New-Item -ItemType Directory -Force -Path "$p/knowledge/issues/open" | Out-Null
    Run @('-Target', $p)
    Check 'warning printed'                   { $script:out.Contains('knowledge/issues') }
    Check 'legacy directory kept'             { Test-Path "$p/knowledge/issues/open" }
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($script:fails -eq 0) { Write-Host 'OK   install.ps1 passed' } else { Write-Host "FAIL $($script:fails) check(s)"; exit 1 }
