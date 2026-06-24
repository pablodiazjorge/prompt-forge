# sync-skills.ps1
# Synchronizes skills and instruction files from .github/ (source of truth)
# to all provider packages. Run after editing any skill or instruction file.

param(
    [switch]$WhatIf = $false
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

Write-Host "prompt-forge sync tool" -ForegroundColor Cyan
Write-Host "Source of truth: .github/" -ForegroundColor Gray
Write-Host ""

# ---- Skills ----

$skillsSource = "$root\.github\skills"

$skillTargets = @(
    @{ Path = "$root\packages\copilot\.github\skills"; Name = "Copilot skills" },
    @{ Path = "$root\packages\claude\.claude\skills";   Name = "Claude skills"  },
    @{ Path = "$root\packages\custom\.github\skills";   Name = "Custom skills"  }
)

foreach ($target in $skillTargets) {
    if (-not (Test-Path $target.Path)) {
        Write-Host "  SKIP [$($target.Name)] -- directory not found" -ForegroundColor Yellow
        continue
    }
    if ($WhatIf) {
        $skills = Get-ChildItem $skillsSource -Directory
        Write-Host "  WHATIF [$($target.Name)] -- would sync $($skills.Count) skills" -ForegroundColor DarkYellow
    } else {
        Remove-Item "$($target.Path)\*" -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item "$skillsSource\*" $target.Path -Recurse -Force
        $count = (Get-ChildItem $target.Path -Directory).Count
        Write-Host "  OK   [$($target.Name)] -- $count skills" -ForegroundColor Green
    }
}

# ---- Instruction files ----

$instructionMap = @(
    @{ Src = "$root\.github\copilot-instructions.md"
       Dst = "$root\packages\copilot\.github\copilot-instructions.md"
       Name = "copilot-instructions.md -> Copilot" },
    @{ Src = "$root\.github\instructions\default.instructions.md"
       Dst = "$root\packages\copilot\.github\instructions\default.instructions.md"
       Name = "default.instructions.md -> Copilot" },
    @{ Src = "$root\.github\instructions\default.instructions.md"
       Dst = "$root\packages\custom\.github\instructions\default.instructions.md"
       Name = "default.instructions.md -> Custom" }
)

foreach ($m in $instructionMap) {
    if (-not (Test-Path $m.Src)) {
        Write-Host "  SKIP [$($m.Name)] -- source not found" -ForegroundColor Yellow
        continue
    }
    if ($WhatIf) {
        Write-Host "  WHATIF [$($m.Name)] -- would copy" -ForegroundColor DarkYellow
    } else {
        Copy-Item $m.Src $m.Dst -Force
        Write-Host "  OK   [$($m.Name)]" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Done. Run with -WhatIf to preview without changes." -ForegroundColor Cyan
