[CmdletBinding()]
param(
    [ValidateSet('play', 'editor', 'test', 'capture')]
    [string]$Mode = 'play',
    [string]$GodotPath = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engineInfo = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'engine.json') -Raw | ConvertFrom-Json
if (-not $GodotPath) {
    $GodotPath = Join-Path (Join-Path $projectRoot '.tools/godot') $engineInfo.console_executable
}
if (-not (Test-Path -LiteralPath $GodotPath)) {
    throw 'Godot was not found. Run tools/setup.ps1 first, or pass -GodotPath with your Godot executable.'
}
$versionText = & $GodotPath --version
if ($versionText -notmatch ('^' + [regex]::Escape($engineInfo.version) + '\.stable')) {
    throw "Expected Godot $($engineInfo.version) stable; found $versionText"
}
Push-Location $projectRoot
try {
    if ($Mode -in @('test', 'capture')) {
        New-Item -ItemType Directory -Force 'test-results' | Out-Null
        New-Item -ItemType File -Force 'test-results/.gdignore' | Out-Null
        # Import is required on a fresh clone before running class_name-based tests.
        & $GodotPath --headless --path . --editor --import --quit
        if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
    }
    switch ($Mode) {
        'play' { & $GodotPath --path . }
        'editor' { & $GodotPath --editor --path . }
        'test' {
            & $GodotPath --headless --path . --script res://tests/integration.gd -- --test
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --headless --path . --script res://tests/watchtower.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --headless --path . --script res://tests/progression_warwick.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --headless --path . --script res://tests/ability_combat.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --headless --path . --script res://tests/talent_ui.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --headless --path . --script res://tests/dark_woods.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --headless --path . --script res://tests/encounter_feedback.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --headless --path . --script res://tests/music.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --headless --path . --script res://tests/hollowmere.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --headless --path . --script res://tests/marsh_movement.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --headless --path . --script res://tests/drowned_patrol.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --headless --path . --script res://tests/darkmere.gd -- --test
            }
        }
        'capture' {
            & $GodotPath --path . --script res://tests/visual_capture.gd -- --test
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --path . --script res://tests/update_capture.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --path . --script res://tests/den_capture.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --path . --script res://tests/hollowmere_capture.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --path . --script res://tests/chapel_capture.gd -- --test
            }
            if ($LASTEXITCODE -eq 0) {
                & $GodotPath --path . --script res://tests/darkmere_capture.gd -- --test
            }
        }
    }
    $runExit = $LASTEXITCODE
}
finally { Pop-Location }
exit $runExit
