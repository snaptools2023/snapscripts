<#
.SYNOPSIS
    Renames emotes_assets_all_*.bundle files to disable Marvel Snap emotes.

.DESCRIPTION
    Reads the Steam install path from the registry, parses libraryfolders.vdf
    to find all Steam library folders, then renames all emotes_assets_all_*.bundle
    files by appending a .rename suffix.
    Checks both HKLM (64-bit) and HKCU registry locations.
#>

[CmdletBinding()]
param()

function Get-SteamBasePaths {
    $paths = @()

    # Registry key 1: HKLM (64-bit install)
    try {
        $reg1 = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -ErrorAction Stop
        if ($reg1.InstallPath) {
            $paths += $reg1.InstallPath
        }
    }
    catch {
        Write-Verbose "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam not found."
    }

    # Registry key 2: HKCU (current user)
    try {
        $reg2 = Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction Stop
        if ($reg2.SteamPath) {
            $paths += $reg2.SteamPath
        }
    }
    catch {
        Write-Verbose "HKCU:\Software\Valve\Steam not found."
    }

    return $paths | Select-Object -Unique
}

function Get-SteamLibraryPaths {
    param([string]$SteamPath)

    $vdfPath = "$SteamPath\steamapps\libraryfolders.vdf"

    if (-not (Test-Path $vdfPath)) {
        Write-Verbose "Could not find libraryfolders.vdf at $vdfPath"
        return @()
    }

    $vdfContent = Get-Content $vdfPath

    # Extract all "path" values from the VDF file
    $libraries = $vdfContent |
        Select-String -Pattern '"path"\s+"([^"]+)"' |
        ForEach-Object {
            $_.Matches.Groups[1].Value -replace '\\\\', '\'
        }

    Write-Host "Detected Steam Libraries:" -ForegroundColor Cyan
    $libraries | ForEach-Object { Write-Host "  $_" }

    return $libraries
}

$steamBasePaths = Get-SteamBasePaths

if (-not $steamBasePaths) {
    Write-Host "No Steam installation found in registry." -ForegroundColor Yellow
    exit 1
}

$allLibraryPaths = @()
foreach ($basePath in $steamBasePaths) {
    if (-not (Test-Path $basePath)) {
        Write-Verbose "Path '$basePath' from registry does not exist on disk."
        continue
    }
    $allLibraryPaths += Get-SteamLibraryPaths -SteamPath $basePath
}

$allLibraryPaths = $allLibraryPaths | Select-Object -Unique

if (-not $allLibraryPaths) {
    Write-Host "No Steam library folders found." -ForegroundColor Yellow
    exit 1
}

$foundCount = 0

$mockCdnRelative = "steamapps\common\MARVEL SNAP\SNAP_Data\StreamingAssets\aa\StandaloneWindows64\MockCdn"

foreach ($libPath in $allLibraryPaths) {
    if (-not (Test-Path $libPath)) {
        Write-Verbose "Library path '$libPath' does not exist on disk."
        continue
    }

    $searchPath = Join-Path $libPath $mockCdnRelative

    if (-not (Test-Path $searchPath)) {
        Write-Verbose "MockCdn path not found: $searchPath"
        continue
    }

    Write-Host "Searching in: $searchPath" -ForegroundColor Cyan

    $files = Get-ChildItem -Path $searchPath -Filter "emotes_assets_all_*.bundle" -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        $newName = $file.FullName + ".rename"
        Write-Host "  Renaming: $($file.FullName)" -ForegroundColor Green
        Write-Host "       -> : $newName" -ForegroundColor Green
        Rename-Item -Path $file.FullName -NewName ($file.Name + ".rename") -ErrorAction Stop
        $foundCount++
    }
}

if ($foundCount -eq 0) {
    Write-Host "No emotes_assets_all_*.bundle files found." -ForegroundColor Yellow
}
else {
    Write-Host "Renamed $foundCount file(s). Emotes are now disabled." -ForegroundColor Green
}
