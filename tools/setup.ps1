[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engineInfo = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'engine.json') -Raw | ConvertFrom-Json
$toolsRoot = Join-Path $projectRoot '.tools'
$engineRoot = Join-Path $toolsRoot 'godot'
$engineExe = Join-Path $engineRoot $engineInfo.executable
if (Test-Path -LiteralPath $engineExe) {
    Write-Host "Godot $($engineInfo.version) already exists in .tools/godot."
    exit 0
}
New-Item -ItemType Directory -Force $toolsRoot | Out-Null
New-Item -ItemType File -Force (Join-Path $toolsRoot '.gdignore') | Out-Null
$archivePath = Join-Path $toolsRoot 'godot.zip'
$ProgressPreference = 'SilentlyContinue'
Write-Host "Downloading official Godot $($engineInfo.version) for Windows x64..."
Invoke-WebRequest -Uri $engineInfo.url -OutFile $archivePath -UseBasicParsing
$actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualHash -ne $engineInfo.sha256) {
    throw 'Godot archive checksum mismatch. The archive has not been extracted.'
}
Expand-Archive -LiteralPath $archivePath -DestinationPath $engineRoot -Force
# Self-contained editor configuration stays out of the repository and user settings.
New-Item -ItemType File -Force (Join-Path $engineRoot '._sc_') | Out-Null
Write-Host 'Setup complete. Run tools/launch.ps1 or open project.godot in Godot.'
