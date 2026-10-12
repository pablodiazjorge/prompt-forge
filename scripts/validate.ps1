# validate.ps1
# Checks the shipped skills and the repository's Markdown links.
#
#   - Frontmatter uses only Agent Skills spec fields, plus the client
#     extensions listed in $Extensions.
#   - name matches its directory and the spec's character rules.
#   - description is present and at most 1024 characters.
#   - metadata.tokens matches the measured body (characters / 4, rounded to
#     0.1k), and the body stays under 500 lines.
#   - Every relative Markdown link resolves.
#
# Exit code 1 on any failure. Runs on Windows PowerShell 5.1 and PowerShell 7.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$SpecFields = @('name', 'description', 'license', 'compatibility', 'metadata', 'allowed-tools')
$Extensions = @('disable-model-invocation')   # honored by Claude Code, VS Code, Cursor
$inv        = [Globalization.CultureInfo]::InvariantCulture
$failures   = New-Object System.Collections.Generic.List[string]

function Read-Text([string]$Path) {
    # LF-normalized, decoded as UTF-8 on every PowerShell edition.
    return ([IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)) -replace "`r", ''
}

# ---- Skills -------------------------------------------------------------

$skillsDir = Join-Path $root 'template/.agents/skills'
$skillFiles = Get-ChildItem -LiteralPath $skillsDir -Directory |
    ForEach-Object { Join-Path $_.FullName 'SKILL.md' }

foreach ($file in $skillFiles) {
    $dirName = Split-Path (Split-Path $file -Parent) -Leaf
    if (-not (Test-Path -LiteralPath $file)) {
        $failures.Add("${dirName}: SKILL.md is missing"); continue
    }

    $text  = Read-Text $file
    # Split into at most 3 parts: bodies may contain --- lines of their own.
    $parts = (New-Object regex '(?m)^---[ \t]*$').Split($text, 3)
    if ($parts.Count -lt 3 -or $parts[0].Trim() -ne '') {
        $failures.Add("${dirName}: frontmatter must start on line 1 between --- lines"); continue
    }
    $front = $parts[1]
    $body  = $parts[2]

    # Top-level keys and their (possibly block-scalar) values.
    $fields = @{}
    $current = $null
    foreach ($line in ($front -split "`n")) {
        if ($line -match '^([A-Za-z][A-Za-z0-9-]*):\s*(.*)$') {
            $current = $Matches[1]
            $fields[$current] = $Matches[2].Trim()
        } elseif ($current -and $line -match '^\s+\S') {
            $fields[$current] += "`n" + $line.Trim()
        }
    }

    foreach ($key in $fields.Keys) {
        if ($SpecFields -notcontains $key -and $Extensions -notcontains $key) {
            $failures.Add("${dirName}: '$key' is not an Agent Skills field (move it under metadata)")
        }
    }

    $name = $fields['name']
    if ($name -ne $dirName) {
        $failures.Add("${dirName}: name '$name' does not match the directory")
    }
    if ($name -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$' -or $name.Length -gt 64) {
        $failures.Add("${dirName}: name must be 1-64 lowercase letters, digits and single hyphens")
    }

    $desc = $fields['description']
    if ($desc -match '^[|>][+-]?\s*\n?') { $desc = $desc -replace '^[|>][+-]?\s*\n?', '' }
    $desc = ($desc -replace '\s+', ' ').Trim()
    if (-not $desc) {
        $failures.Add("${dirName}: description is empty")
    } elseif ($desc.Length -gt 1024) {
        $failures.Add("${dirName}: description is $($desc.Length) characters (max 1024)")
    }

    $lines = ($body.TrimEnd("`n") -split "`n").Count
    if ($lines -gt 500) {
        $failures.Add("${dirName}: body is $lines lines (max 500)")
    }

    $measured = [Math]::Round($body.Length / 4000, 1)
    $declared = $null
    if ($front -match '(?m)^\s+tokens:\s*"?([0-9.]+)k"?') { $declared = [double]$Matches[1] }
    if ($null -eq $declared) {
        $failures.Add("${dirName}: metadata.tokens is missing (measured $($measured.ToString('0.0', $inv))k)")
    } elseif ([Math]::Abs($declared - $measured) -gt 0.05) {
        $failures.Add("${dirName}: metadata.tokens says $($declared.ToString('0.0', $inv))k, body measures $($measured.ToString('0.0', $inv))k")
    }

    Write-Host ("  {0,-22} {1,5}k  {2,4} chars of description" -f $dirName, $measured.ToString('0.0', $inv), $desc.Length)
}

# ---- Relative Markdown links --------------------------------------------

$mdFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Force -Filter '*.md' |
    Where-Object { $_.FullName -notmatch '[\\/](\.git|node_modules)[\\/]' }

foreach ($md in $mdFiles) {
    $text = Read-Text $md.FullName
    # Ignore fenced code blocks.
    $text = [regex]::Replace($text, '(?ms)^```.*?^```', '')
    foreach ($m in [regex]::Matches($text, '\]\(([^)\s]+)\)')) {
        $target = $m.Groups[1].Value
        if ($target -match '^(https?:|mailto:|#)') { continue }
        $path = ($target -split '#')[0]
        if (-not $path) { continue }
        $resolved = Join-Path (Split-Path $md.FullName -Parent) $path
        if (-not (Test-Path -LiteralPath $resolved)) {
            $rel = $md.FullName.Substring($root.Length + 1)
            $failures.Add("${rel}: broken link -> $target")
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "FAIL $($failures.Count) problem(s):"
    $failures | ForEach-Object { Write-Host "  $_" }
    exit 1
}
Write-Host "OK   skills and links are valid"
