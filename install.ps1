<#
.SYNOPSIS
  Install or upgrade prompt-forge in a project.

.DESCRIPTION
  It never overwrites your files:
    - AGENTS.md gets the prompt-forge block appended (or, with -Upgrade,
      replaced between its markers). CLAUDE.md and GEMINI.md get an
      "@AGENTS.md" import line appended if they lack one.
    - knowledge/ files are created only when missing and never changed.
    - prompt-forge's own skills and agent are created when missing and
      replaced only with -Upgrade.

  Runs on Windows PowerShell 5.1 and PowerShell 7.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File $env:TEMP\prompt-forge\install.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File $env:TEMP\prompt-forge\install.ps1 -Upgrade -DryRun
#>
param(
    [string]$Target = '.',
    [switch]$Upgrade,
    [switch]$SkipClaude,
    [switch]$SkipGemini,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$Version = '2.0.0'
$Src     = Join-Path $PSScriptRoot 'template'
$Skills  = @('record-lesson', 'curate-lessons', 'git-workflow', 'powershell-patterns')
# Paths that prompt-forge 1.x installed. Reported, never deleted.
$Legacy  = @(
    '.github/skills/developer', '.github/skills/ai-engineer', '.github/skills/explore-codebase',
    '.github/skills/skill-creator', '.github/skills/track-tokens', '.github/skills/git-workflow',
    '.github/skills/powershell-patterns', '.github/agents/ai-engineer.agent.md',
    '.github/instructions/default.instructions.md',
    '.claude/skills/developer', '.claude/skills/ai-engineer', '.claude/skills/explore-codebase',
    '.claude/skills/skill-creator', '.claude/skills/track-tokens', '.claude/agents/ai-engineer.md',
    'knowledge/issues', 'scripts/session-start.ps1', 'scripts/session-end.ps1', 'DEEPSEEK-SETUP.md',
    '.prompt-forge'
)

if (-not (Test-Path -LiteralPath $Src))    { throw "template/ not found next to install.ps1" }
if (-not (Test-Path -LiteralPath $Target)) { throw "target directory not found: $Target" }
$Target = (Resolve-Path -LiteralPath $Target).Path
if ($Target.TrimEnd('\', '/') -eq $PSScriptRoot.TrimEnd('\', '/')) {
    throw "point the installer at your project, not at the prompt-forge clone"
}

Write-Host "prompt-forge $Version -> $Target"
if ($DryRun) { Write-Host "(dry run: nothing is written)" }
Write-Host ""

function Say([string]$Action, [string]$What) {
    Write-Host ("  {0,-9} {1}" -f $Action, $What)
}

# Hash with CR bytes removed, so a checkout with core.autocrlf=true still counts as current.
$Sha = [Security.Cryptography.SHA256]::Create()
function Get-TextHash([string]$Path) {
    $bytes = [byte[]]@([IO.File]::ReadAllBytes($Path) | Where-Object { $_ -ne 13 })
    return [BitConverter]::ToString($Sha.ComputeHash($bytes))
}

function Get-TreeHash([string]$Dir) {
    $map = @{}
    $base = (Resolve-Path -LiteralPath $Dir).Path.TrimEnd('\', '/')
    Get-ChildItem -LiteralPath $Dir -Recurse -File -Force | ForEach-Object {
        $map[$_.FullName.Substring($base.Length + 1)] = Get-TextHash $_.FullName
    }
    return $map
}

function Test-SameTree([string]$A, [string]$B) {
    $ha = Get-TreeHash $A; $hb = Get-TreeHash $B
    if ($ha.Count -ne $hb.Count) { return $false }
    foreach ($k in $ha.Keys) { if ($hb[$k] -ne $ha[$k]) { return $false } }
    return $true
}

function Test-SameFile([string]$A, [string]$B) {
    return (Get-TextHash $A) -eq (Get-TextHash $B)
}

function New-Parent([string]$Path) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
}

# Reads a text file, remembering whether it had a UTF-8 BOM and CRLF line endings.
function Read-Doc([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    $bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)
    return @{ Text = $text; Bom = $bom; Crlf = $text.Contains("`r`n") }
}

function Write-Doc([string]$Path, [string]$Text, [bool]$Bom) {
    [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding $Bom))
}

function Set-Eol([string]$Text, [bool]$Crlf) {
    $lf = $Text -replace "`r`n", "`n"
    if ($Crlf) { return $lf -replace "`n", "`r`n" }
    return $lf
}

# A prompt-forge-owned directory: created when missing, replaced on -Upgrade.
function Install-Dir([string]$From, [string]$Rel) {
    $dst = Join-Path $Target $Rel
    if (-not (Test-Path -LiteralPath $dst)) {
        if (-not $DryRun) { New-Parent $dst; Copy-Item -LiteralPath $From -Destination $dst -Recurse -Force }
        Say 'created' "$Rel/"
    } elseif (Test-SameTree $From $dst) {
        Say 'current' "$Rel/"
    } elseif ($Upgrade) {
        if (-not $DryRun) {
            Remove-Item -LiteralPath $dst -Recurse -Force
            Copy-Item -LiteralPath $From -Destination $dst -Recurse -Force
        }
        Say 'updated' "$Rel/"
    } else {
        Say 'kept' "$Rel/ (differs; -Upgrade replaces it)"
    }
}

# A single file. Owned files are replaced on -Upgrade; the team's files never are.
function Install-File([string]$From, [string]$Rel, [bool]$Owned) {
    $dst = Join-Path $Target $Rel
    if (-not (Test-Path -LiteralPath $dst)) {
        if (-not $DryRun) { New-Parent $dst; Copy-Item -LiteralPath $From -Destination $dst -Force }
        Say 'created' $Rel
    } elseif (Test-SameFile $From $dst) {
        Say 'current' $Rel
    } elseif ($Owned -and $Upgrade) {
        if (-not $DryRun) { Copy-Item -LiteralPath $From -Destination $dst -Force }
        Say 'updated' $Rel
    } elseif ($Owned) {
        Say 'kept' "$Rel (differs; -Upgrade replaces it)"
    } else {
        Say 'kept' "$Rel (yours; compare with template/$Rel)"
    }
}

function Merge-AgentsMd {
    $dst = Join-Path $Target 'AGENTS.md'
    $template = ([IO.File]::ReadAllText((Join-Path $Src 'AGENTS.md'), [Text.Encoding]::UTF8)) -replace "`r`n", "`n"
    $block = [regex]::Match($template, '(?s)<!-- prompt-forge:start.*?<!-- prompt-forge:end -->').Value

    if (-not (Test-Path -LiteralPath $dst)) {
        if (-not $DryRun) { Copy-Item -LiteralPath (Join-Path $Src 'AGENTS.md') -Destination $dst }
        Say 'created' 'AGENTS.md'
        return
    }

    $doc = Read-Doc $dst
    $blockEol = Set-Eol $block $doc.Crlf
    $pattern = '(?s)<!-- prompt-forge:start.*?<!-- prompt-forge:end -->'

    if ($doc.Text -match '<!-- prompt-forge:start') {
        $starts = ([regex]::Matches($doc.Text, '<!-- prompt-forge:start')).Count
        $ends   = ([regex]::Matches($doc.Text, '<!-- prompt-forge:end -->')).Count
        if ($starts -ne 1 -or $ends -ne 1) {
            throw "AGENTS.md has $starts prompt-forge:start and $ends prompt-forge:end markers; expected one of each. Fix it by hand and run again."
        }
        $merged = [regex]::Replace($doc.Text, $pattern, { param($m) $blockEol })
        if ($merged -eq $doc.Text) {
            Say 'current' 'AGENTS.md (prompt-forge block)'
        } elseif ($Upgrade) {
            if (-not $DryRun) { Write-Doc $dst $merged $doc.Bom }
            Say 'updated' 'AGENTS.md (prompt-forge block replaced)'
        } else {
            Say 'kept' 'AGENTS.md (block differs; -Upgrade replaces it)'
        }
    } else {
        $nl = if ($doc.Crlf) { "`r`n" } else { "`n" }
        $text = $doc.Text
        if ($text.Length -gt 0 -and -not $text.EndsWith("`n")) { $text += $nl }
        $text += $nl + $blockEol + $nl
        if (-not $DryRun) { Write-Doc $dst $text $doc.Bom }
        Say 'merged' 'AGENTS.md (prompt-forge block appended)'
    }
}

# Appends an "@AGENTS.md" import to CLAUDE.md or GEMINI.md, or creates the file.
function Merge-Import([string]$Rel) {
    $dst = Join-Path $Target $Rel
    if (-not (Test-Path -LiteralPath $dst)) {
        if (-not $DryRun) { Copy-Item -LiteralPath (Join-Path $Src $Rel) -Destination $dst }
        Say 'created' $Rel
        return
    }
    $doc = Read-Doc $dst
    if ($doc.Text -match '(?m)^@AGENTS\.md') {
        Say 'current' "$Rel (imports AGENTS.md)"
        return
    }
    $nl = if ($doc.Crlf) { "`r`n" } else { "`n" }
    $text = $doc.Text
    if ($text.Length -gt 0 -and -not $text.EndsWith("`n")) { $text += $nl }
    $text += $nl + '@AGENTS.md' + $nl
    if (-not $DryRun) { Write-Doc $dst $text $doc.Bom }
    Say 'merged' "$Rel (@AGENTS.md import appended)"
}

Write-Host 'Instructions'
Merge-AgentsMd
if (-not $SkipClaude) { Merge-Import 'CLAUDE.md' }
if (-not $SkipGemini) { Merge-Import 'GEMINI.md' }

Write-Host 'Skills'
foreach ($s in $Skills) {
    Install-Dir (Join-Path $Src ".agents/skills/$s") ".agents/skills/$s"
    if (-not $SkipClaude) { Install-Dir (Join-Path $Src ".claude/skills/$s") ".claude/skills/$s" }
}
if (-not $SkipClaude) {
    Install-File (Join-Path $Src '.claude/agents/curate-lessons.md') '.claude/agents/curate-lessons.md' $true
}

Write-Host 'Knowledge'
Install-File (Join-Path $Src 'knowledge/README.md') 'knowledge/README.md' $false
foreach ($d in @('lessons', 'memory')) {
    if (-not (Test-Path -LiteralPath (Join-Path $Target "knowledge/$d"))) {
        Install-File (Join-Path $Src "knowledge/$d/.gitkeep") "knowledge/$d/.gitkeep" $false
    }
}

$found = $Legacy | Where-Object { Test-Path -LiteralPath (Join-Path $Target $_) }
if ($found) {
    Write-Host ''
    Write-Host 'Possible prompt-forge 1.x files (left untouched; see docs/upgrading.md):'
    $found | ForEach-Object { Write-Host "  $_" }
}

Write-Host ''
Write-Host "Next: review with 'git status' and 'git diff', add a CODEOWNERS entry for"
Write-Host 'knowledge/memory/ (see knowledge/README.md), then commit.'
