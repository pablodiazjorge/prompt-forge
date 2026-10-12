# sync-skills.ps1
# Synchronizes the source of truth into the provider distribution packages.
# Run after editing anything under .github/, .claude/agents/, AGENTS.md, or knowledge/.
#
# Source of truth          Goes to
#   .github/skills/          packages/vscode/.github/skills/, packages/claude/.claude/skills/
#   .github/agents/          packages/vscode/.github/agents/
#   .claude/agents/          packages/claude/.claude/agents/
#   AGENTS.md                both packages
#   knowledge/               both packages
#
# Provider-specific files that are NOT generated and must be edited in place:
#   packages/claude/CLAUDE.md

param(
    [switch]$WhatIf = $false
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

Write-Host "prompt-forge sync tool" -ForegroundColor Cyan
Write-Host "Source of truth: .github/, .claude/agents/, AGENTS.md, knowledge/" -ForegroundColor Gray
Write-Host ""

# Mirrors a whole directory: wipes the target contents, then copies the source in.
# Used for trees where the source is authoritative and package-local edits are
# not allowed (skills, agents, knowledge).
function Sync-Tree {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Name,
        [switch]$Preview
    )

    if (-not (Test-Path $Source)) {
        Write-Host "  SKIP [$Name] -- source not found: $Source" -ForegroundColor Yellow
        return
    }

    if ($Preview) {
        $count = (Get-ChildItem $Source -Recurse -File).Count
        Write-Host "  WHATIF [$Name] -- would mirror $count files" -ForegroundColor DarkYellow
        return
    }

    if (-not (Test-Path $Target)) {
        New-Item -ItemType Directory -Force -Path $Target | Out-Null
    }
    Remove-Item "$Target\*" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item "$Source\*" $Target -Recurse -Force
    $count = (Get-ChildItem $Target -Recurse -File).Count
    Write-Host "  OK   [$Name] -- $count files" -ForegroundColor Green
}

function Sync-File {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Name,
        [switch]$Preview
    )

    if (-not (Test-Path $Source)) {
        Write-Host "  SKIP [$Name] -- source not found: $Source" -ForegroundColor Yellow
        return
    }

    if ($Preview) {
        Write-Host "  WHATIF [$Name] -- would copy" -ForegroundColor DarkYellow
        return
    }

    $parent = Split-Path $Target -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    Copy-Item $Source $Target -Force
    Write-Host "  OK   [$Name]" -ForegroundColor Green
}

# ---- Skills (auto-discovers every directory under .github/skills/) ----

Sync-Tree -Source "$root\.github\skills" `
          -Target "$root\packages\vscode\.github\skills" `
          -Name   "skills -> vscode" -Preview:$WhatIf

Sync-Tree -Source "$root\.github\skills" `
          -Target "$root\packages\claude\.claude\skills" `
          -Name   "skills -> claude" -Preview:$WhatIf

# ---- Agents (format differs per provider, so each has its own source) ----

Sync-Tree -Source "$root\.github\agents" `
          -Target "$root\packages\vscode\.github\agents" `
          -Name   "agents -> vscode" -Preview:$WhatIf

Sync-Tree -Source "$root\.claude\agents" `
          -Target "$root\packages\claude\.claude\agents" `
          -Name   "agents -> claude" -Preview:$WhatIf

# ---- Knowledge registry ----

Sync-Tree -Source "$root\knowledge" `
          -Target "$root\packages\vscode\knowledge" `
          -Name   "knowledge -> vscode" -Preview:$WhatIf

Sync-Tree -Source "$root\knowledge" `
          -Target "$root\packages\claude\knowledge" `
          -Name   "knowledge -> claude" -Preview:$WhatIf

# ---- Instructions ----

Sync-File -Source "$root\AGENTS.md" `
          -Target "$root\packages\vscode\AGENTS.md" `
          -Name   "AGENTS.md -> vscode" -Preview:$WhatIf

Sync-File -Source "$root\AGENTS.md" `
          -Target "$root\packages\claude\AGENTS.md" `
          -Name   "AGENTS.md -> claude" -Preview:$WhatIf

Write-Host ""
Write-Host "packages/claude/CLAUDE.md is provider-specific and not synced." -ForegroundColor Gray
Write-Host "Done. Run with -WhatIf to preview without changes." -ForegroundColor Cyan
