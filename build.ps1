[CmdletBinding()]
param(
    [string]$Version,
    [switch]$SkipToolDownload,
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$isWindowsHost = $env:OS -eq "Windows_NT"
if (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue) {
    $isWindowsHost = [bool](Get-Variable -Name IsWindows).Value
}

$repoRoot = $PSScriptRoot
$packagePath = Join-Path $repoRoot "package.json"
$package = Get-Content -LiteralPath $packagePath -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = [string]$package.version
}

if ($Version -notmatch '^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$') {
    throw "Version '$Version' is not a valid semantic version."
}

$modRoot = Join-Path $repoRoot "src/Mods/DialogueEnterConfirm"
$requiredFiles = @(
    "meta.lsx",
    "ScriptExtender/Config.json",
    "ScriptExtender/Lua/BootstrapClient.lua",
    "ScriptExtender/Lua/Client/DialogueEnterHandler.lua"
)

foreach ($relativePath in $requiredFiles) {
    $path = Join-Path $modRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required mod file is missing: $relativePath"
    }
}

$configPath = Join-Path $modRoot "ScriptExtender/Config.json"
$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
if ([int]$config.RequiredVersion -lt 32) {
    throw "Config.json must require BG3SE v32 or newer."
}

try {
    $meta = [xml](Get-Content -LiteralPath (Join-Path $modRoot "meta.lsx") -Raw)
} catch {
    throw "meta.lsx is not valid XML: $($_.Exception.Message)"
}

$moduleInfo = @($meta.save.region.node.children.node) |
    Where-Object { $_.id -eq "ModuleInfo" } |
    Select-Object -First 1
$uuidAttribute = @($moduleInfo.attribute) |
    Where-Object { $_.id -eq "UUID" } |
    Select-Object -First 1
if (-not $uuidAttribute -or [string]$uuidAttribute.value -ne [string]$package.bg3.uuid) {
    throw "meta.lsx UUID does not match package.json bg3.uuid."
}

if ($ValidateOnly) {
    Write-Host "Validation passed for Dialogue Enter Confirm v$Version"
    exit 0
}

$lslibVersion = "1.20.4"
$lslibUrl = "https://github.com/Norbyte/lslib/releases/download/v$lslibVersion/ExportTool-v$lslibVersion.zip"
$lslibSha256 = "5E02368FB8ACAFDA9B45ACBA37A3F3BF507FC3D65A083A159ABBEAB06337190E"
$toolsRoot = Join-Path $repoRoot ".tools"
$lslibRoot = Join-Path $toolsRoot "lslib-$lslibVersion"
$divine = Get-ChildItem -LiteralPath $lslibRoot -Filter "Divine.exe" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $divine) {
    if ($SkipToolDownload) {
        throw "LSLib $lslibVersion is not installed under $lslibRoot."
    }

    New-Item -ItemType Directory -Path $lslibRoot -Force | Out-Null
    $archivePath = Join-Path $toolsRoot "ExportTool-v$lslibVersion.zip"
    Write-Host "Downloading pinned LSLib $lslibVersion..."
    Invoke-WebRequest -Uri $lslibUrl -OutFile $archivePath
    $actualSha256 = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
    if ($actualSha256 -ne $lslibSha256) {
        throw "LSLib checksum mismatch. Expected $lslibSha256, got $actualSha256."
    }
    Expand-Archive -LiteralPath $archivePath -DestinationPath $lslibRoot -Force
    $divine = Get-ChildItem -LiteralPath $lslibRoot -Filter "Divine.exe" -Recurse -File | Select-Object -First 1
}

if (-not $divine) {
    throw "Divine.exe was not found in the LSLib archive."
}

$buildRoot = Join-Path $repoRoot "build"
$releasesRoot = Join-Path $repoRoot "releases"
if (Test-Path -LiteralPath $buildRoot) { Remove-Item -LiteralPath $buildRoot -Recurse -Force }
if (Test-Path -LiteralPath $releasesRoot) { Remove-Item -LiteralPath $releasesRoot -Recurse -Force }
New-Item -ItemType Directory -Path $buildRoot, $releasesRoot | Out-Null

$stagingMods = Join-Path $buildRoot "Mods"
New-Item -ItemType Directory -Path $stagingMods | Out-Null
Copy-Item -Path (Join-Path $repoRoot "src/Mods/*") -Destination $stagingMods -Recurse

$divineDll = Get-ChildItem -LiteralPath $lslibRoot -Filter "Divine.dll" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $divineDll) {
    throw "Divine.dll was not found in the LSLib archive."
}
function Invoke-Divine {
    param([string[]]$Arguments)
    if ($isWindowsHost) {
        & $divine.FullName @Arguments
    } else {
        & dotnet $divineDll.FullName @Arguments
    }
}

$pakName = "DialogueEnterConfirm_v$Version.pak"
$pakPath = Join-Path $releasesRoot $pakName
Write-Host "Packing $pakName with LSLib $lslibVersion..."
Invoke-Divine @("-g", "bg3", "-a", "create-package", "-s", $buildRoot, "-d", $pakPath)
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $pakPath -PathType Leaf)) {
    throw "Divine failed to create $pakName."
}

$verifyRoot = Join-Path ([System.IO.Path]::GetTempPath()) "dialogue-enter-confirm-$([guid]::NewGuid().ToString('N'))"
try {
    Invoke-Divine @("-g", "bg3", "-a", "extract-package", "-s", $pakPath, "-d", $verifyRoot)
    if ($LASTEXITCODE -ne 0) { throw "Divine failed while extracting the package for verification." }
    $topLevelEntries = @(Get-ChildItem -LiteralPath $verifyRoot -Force)
    if ($topLevelEntries.Count -ne 1 -or $topLevelEntries[0].Name -ne "Mods" -or
        -not (Test-Path -LiteralPath (Join-Path $verifyRoot "Mods/DialogueEnterConfirm") -PathType Container)) {
        throw "Packed archive must have exactly the Mods/DialogueEnterConfirm root."
    }
    foreach ($relativePath in $requiredFiles) {
        $expected = Join-Path $verifyRoot (Join-Path "Mods/DialogueEnterConfirm" $relativePath)
        if (-not (Test-Path -LiteralPath $expected -PathType Leaf)) {
            throw "Packed archive is missing Mods/DialogueEnterConfirm/$relativePath"
        }
    }
} finally {
    if (Test-Path -LiteralPath $verifyRoot) { Remove-Item -LiteralPath $verifyRoot -Recurse -Force }
}

$installStage = Join-Path $buildRoot "Install"
New-Item -ItemType Directory -Path $installStage | Out-Null
Copy-Item -LiteralPath $pakPath -Destination (Join-Path $installStage $pakName)
Copy-Item -LiteralPath (Join-Path $repoRoot "docs/INSTALL.md") -Destination (Join-Path $installStage "INSTALL.md")
$installZipName = "DialogueEnterConfirm_v${Version}_Install.zip"
$installZipPath = Join-Path $releasesRoot $installZipName
Compress-Archive -Path (Join-Path $installStage "*") -DestinationPath $installZipPath -CompressionLevel Optimal

$sourceStage = Join-Path $buildRoot "Source"
New-Item -ItemType Directory -Path $sourceStage | Out-Null
$sourceItems = @(
    "src",
    "tests",
    "docs",
    ".github",
    "build.ps1",
    "build.sh",
    "package.json",
    "README.md",
    "CHANGELOG.md",
    "GITHUB_SETUP.md",
    "LICENSE"
)
foreach ($sourceItem in $sourceItems) {
    Copy-Item -LiteralPath (Join-Path $repoRoot $sourceItem) -Destination $sourceStage -Recurse
}
$sourceZipName = "DialogueEnterConfirm_v${Version}_Source.zip"
$sourceZipPath = Join-Path $releasesRoot $sourceZipName
Compress-Archive -Path (Join-Path $sourceStage "*") -DestinationPath $sourceZipPath -CompressionLevel Optimal

$notesTemplatePath = Join-Path $repoRoot "docs/RELEASE_NOTES.md"
$notes = (Get-Content -LiteralPath $notesTemplatePath -Raw).Replace("__VERSION__", $Version)
$notesPath = Join-Path $releasesRoot "RELEASE_NOTES_v$Version.md"
Set-Content -LiteralPath $notesPath -Value $notes -Encoding UTF8

$buildInfo = @(
    "Dialogue Enter Confirm v$Version",
    "LSLib: $lslibVersion",
    "LSLib SHA-256: $lslibSha256",
    "Package verification: passed",
    "Development game: BG3 4.1.1.7398727 / Steam BuildID 24532579 (Patch 8)",
    "BG3SE v32 game run: unavailable in the build environment",
    "Game verification: pending (requires an in-game test)",
    "Multiplayer verification: pending"
)
Set-Content -LiteralPath (Join-Path $releasesRoot "BUILD_INFO.txt") -Value $buildInfo -Encoding UTF8

$artifacts = @($pakPath, $installZipPath, $sourceZipPath)
$checksums = foreach ($artifact in $artifacts) {
    $hash = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $([System.IO.Path]::GetFileName($artifact))"
}
Set-Content -LiteralPath (Join-Path $releasesRoot "SHA256SUMS.txt") -Value $checksums -Encoding UTF8

Write-Host "Build complete. Artifacts are in $releasesRoot"
Get-ChildItem -LiteralPath $releasesRoot -File | Select-Object Name, Length | Format-Table -AutoSize
