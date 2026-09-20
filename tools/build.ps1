[CmdletBinding()]
param(
    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engineInfoPath = Join-Path $PSScriptRoot 'engine.json'
$engineInfo = Get-Content -LiteralPath $engineInfoPath -Raw | ConvertFrom-Json
$engineRoot = Join-Path $projectRoot '.tools\godot'
$godotPath = Join-Path $engineRoot $engineInfo.console_executable
$templateRoot = Join-Path (Join-Path $engineRoot 'editor_data\export_templates') $engineInfo.export_templates_directory
$templatePath = Join-Path $templateRoot 'windows_release_x86_64.exe'
$templateVersionPath = Join-Path $templateRoot 'version.txt'
$archivePath = Join-Path $engineRoot 'export_templates.tpz'
$downloadPath = "$archivePath.download"
$buildRoot = Join-Path $projectRoot 'builds'
$windowsRoot = Join-Path $buildRoot 'windows'
$executablePath = Join-Path $windowsRoot 'Briarwatch.exe'
$readmePath = Join-Path $windowsRoot 'README.txt'
$zipPath = Join-Path $buildRoot 'Briarwatch-Windows-x64.zip'
$smokeLogPath = Join-Path $buildRoot 'windows-smoke-test.log'

function Assert-LastExitCode([string]$message) {
    if ($LASTEXITCODE -ne 0) {
        throw "$message (exit code $LASTEXITCODE)."
    }
}

function Install-WindowsExportTemplate {
    if (Test-Path -LiteralPath $templatePath) {
        Write-Host "Godot $($engineInfo.version) Windows export template already exists."
        return
    }

    New-Item -ItemType Directory -Force $engineRoot | Out-Null
    if (Test-Path -LiteralPath $downloadPath) {
        Remove-Item -LiteralPath $downloadPath -Force
    }

    $archiveIsValid = $false
    if (Test-Path -LiteralPath $archivePath) {
        $archiveHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
        $archiveIsValid = $archiveHash -eq $engineInfo.export_templates_sha256
        if (-not $archiveIsValid) {
            Remove-Item -LiteralPath $archivePath -Force
        }
    }

    if (-not $archiveIsValid) {
        Write-Host "Downloading official Godot $($engineInfo.version) export templates (about 1.2 GB)..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $engineInfo.export_templates_url -OutFile $downloadPath -UseBasicParsing
        $downloadHash = (Get-FileHash -LiteralPath $downloadPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($downloadHash -ne $engineInfo.export_templates_sha256) {
            Remove-Item -LiteralPath $downloadPath -Force
            throw 'Godot export-template checksum mismatch. The downloaded archive was removed.'
        }
        Move-Item -LiteralPath $downloadPath -Destination $archivePath
    }

    Write-Host 'Extracting the Windows x64 release template...'
    New-Item -ItemType Directory -Force $templateRoot | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        $requiredEntries = @{
            'templates/windows_release_x86_64.exe' = $templatePath
            'templates/version.txt' = $templateVersionPath
        }
        foreach ($entryName in $requiredEntries.Keys) {
            $entry = $archive.GetEntry($entryName)
            if ($null -eq $entry) {
                throw "The official template archive does not contain $entryName."
            }
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $requiredEntries[$entryName], $true)
        }
    }
    finally {
        $archive.Dispose()
    }

    if ((Get-Item -LiteralPath $templatePath).Length -lt 1MB) {
        throw 'The extracted Windows export template is unexpectedly small.'
    }
    Remove-Item -LiteralPath $archivePath -Force
}

if (-not (Test-Path -LiteralPath $godotPath)) {
    & (Join-Path $PSScriptRoot 'setup.ps1')
    Assert-LastExitCode 'Godot setup failed'
}

$versionText = & $godotPath --version
Assert-LastExitCode 'Could not read the Godot version'
if ($versionText -notmatch ('^' + [regex]::Escape($engineInfo.version) + '\.stable')) {
    throw "Expected Godot $($engineInfo.version) stable; found $versionText"
}

Install-WindowsExportTemplate

if (-not $SkipTests) {
    Write-Host 'Running the complete automated test suite...'
    & (Join-Path $PSScriptRoot 'launch.ps1') -Mode test
    Assert-LastExitCode 'Automated tests failed'
}

New-Item -ItemType Directory -Force $windowsRoot | Out-Null
foreach ($oldFile in @($executablePath, $readmePath, $zipPath, $smokeLogPath)) {
    if (Test-Path -LiteralPath $oldFile) {
        Remove-Item -LiteralPath $oldFile -Force
    }
}

Write-Host 'Importing project resources...'
Push-Location $projectRoot
try {
    & $godotPath --headless --path . --editor --import --quit
    Assert-LastExitCode 'Godot resource import failed'

    Write-Host 'Exporting the Windows x64 release build...'
    & $godotPath --headless --path . --export-release 'Windows Desktop' $executablePath
    Assert-LastExitCode 'Windows export failed'
}
finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $executablePath)) {
    throw 'Godot reported success but did not create Briarwatch.exe.'
}
if ((Get-Item -LiteralPath $executablePath).Length -lt 1MB) {
    throw 'Briarwatch.exe is unexpectedly small.'
}

$playerReadme = @'
BRIARWATCH - WINDOWS x64

1. Pak ZIP-filen helt ud.
2. Dobbeltklik på Briarwatch.exe.

Spillet kraever ingen installation, Godot-konto eller internetforbindelse.
Windows SmartScreen kan vise en advarsel, fordi denne private test-build ikke er
digitalt signeret. Vælg i så fald "Flere oplysninger" og "Kør alligevel", hvis
du har modtaget filen direkte fra udvikleren.

Gemte spil ligger i:
%APPDATA%\Godot\app_userdata\Briarwatch\
'@
Set-Content -LiteralPath $readmePath -Value $playerReadme -Encoding UTF8

Write-Host 'Starting the exported game in isolated headless smoke-test mode...'
$smokeArguments = @(
    '--headless',
    '--log-file', ('"{0}"' -f $smokeLogPath),
    '--quit-after', '180',
    '--', '--test'
)
$smokeProcess = Start-Process -FilePath $executablePath -ArgumentList $smokeArguments -Wait -PassThru -WindowStyle Hidden
if ($smokeProcess.ExitCode -ne 0) {
    throw "Exported-game smoke test failed (exit code $($smokeProcess.ExitCode)). See $smokeLogPath"
}
$smokeLog = Get-Content -LiteralPath $smokeLogPath -Raw
if ($smokeLog -match '(?m)^(SCRIPT ERROR|ERROR):') {
    throw "Exported-game smoke test logged an error. See $smokeLogPath"
}

Compress-Archive -LiteralPath $executablePath, $readmePath -DestinationPath $zipPath -CompressionLevel Optimal -Force
$zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
$zipSizeMb = [math]::Round((Get-Item -LiteralPath $zipPath).Length / 1MB, 1)

Write-Host ''
Write-Host 'Windows build completed and passed its smoke test.'
Write-Host "Package: $zipPath"
Write-Host "Size:    $zipSizeMb MB"
Write-Host "SHA-256: $zipHash"
