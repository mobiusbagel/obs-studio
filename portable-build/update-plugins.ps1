# ============================================================
#  update-plugins.ps1
#  Updates all plugins in the portable OBS 33 build at once.
#
#  - 11 plugins are pulled from their GitHub "latest release"
#  - 4 Exeldro plugins publish no GitHub binaries (forums-only),
#    so they are copied from the main OBS install instead
#  - obs-streamelements-core is excluded by design (SE.Live /
#    Move Transition conflict, decided 2026-10-21)
#
#  Destinations (verified against OBS 33 source,
#  frontend/plugin-manager/PluginModuleLoader_Windows.cpp):
#    New layout:    <ObsDir>\plugins\<plugin>\<plugin>.dll + data\
#    Legacy layout: <ObsDir>\obs-plugins\64bit\<plugin>.dll
#                   <ObsDir>\data\obs-plugins\<plugin>\
#  OBS 33 loads both in portable mode; legacy loading is
#  scheduled for removal in OBS 34.
#
#  Close OBS before running. Run via update-plugins.bat.
# ============================================================
param(
    [string]$ObsDir     = "E:\Kris\Downloads\obs-studio-33\build_x64\rundir\RelWithDebInfo",
    [string]$MainObsDir = "C:\Program Files\obs-studio"
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$headers = @{ "User-Agent" = "obs-portable-plugin-updater" }

if (Get-Process obs64 -ErrorAction SilentlyContinue) {
    Write-Host "[ERROR] OBS is running. Close it before updating plugins." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path (Join-Path $ObsDir "bin\64bit\obs64.exe"))) {
    Write-Host "[ERROR] Portable OBS not found at: $ObsDir" -ForegroundColor Red
    Write-Host "        Re-run with -ObsDir pointing at the RelWithDebInfo folder."
    exit 1
}

$pluginsDir = Join-Path $ObsDir "plugins"
$legacyBin  = Join-Path $ObsDir "obs-plugins\64bit"
$legacyData = Join-Path $ObsDir "data\obs-plugins"
New-Item -ItemType Directory -Force -Path $pluginsDir, $legacyBin, $legacyData | Out-Null

$stateFile = Join-Path $PSScriptRoot "plugins-installed.json"
$state = @{}
if (Test-Path $stateFile) {
    (Get-Content $stateFile -Raw | ConvertFrom-Json).PSObject.Properties |
        ForEach-Object { $state[$_.Name] = $_.Value }
}

$work = Join-Path $env:TEMP "obs-plugin-update"
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Force -Path $work | Out-Null

$results = @()

function Save-State {
    $state | ConvertTo-Json | Set-Content $stateFile -Encoding UTF8
}

function Get-LatestAsset($repo, $pattern) {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -Headers $headers
    $asset = $rel.assets | Where-Object { $_.name -match $pattern } | Select-Object -First 1
    if (-not $asset) { throw "No asset matching '$pattern' in $repo $($rel.tag_name)" }
    return @{ Tag = $rel.tag_name; Asset = $asset }
}

function Fetch($entry, $repo, $pattern) {
    $info = Get-LatestAsset $repo $pattern
    if ($state[$entry] -eq $info.Tag) {
        $script:results += [pscustomobject]@{ Plugin = $entry; Result = "Up to date ($($info.Tag))" }
        return $null
    }
    $zip = (Join-Path $work ($repo -replace '/', '_')) + ".zip"
    Write-Host "Downloading $entry $($info.Tag)..."
    Invoke-WebRequest -Uri $info.Asset.browser_download_url -OutFile $zip -Headers $headers -UseBasicParsing
    $dest = Join-Path $work ($repo -replace '/', '_')
    Expand-Archive -Path $zip -DestinationPath $dest -Force
    return @{ Dir = $dest; Tag = $info.Tag }
}

# --- Mode: NewFolder — zip root IS the plugin folder content ---
function Install-NewFolder($entry, $repo, $pattern, $folderName) {
    $f = Fetch $entry $repo $pattern
    if (-not $f) { return }
    $target = Join-Path $pluginsDir $folderName
    if (Test-Path $target) { Remove-Item $target -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Copy-Item (Join-Path $f.Dir "*") $target -Recurse -Force
    $state[$entry] = $f.Tag; Save-State
    $script:results += [pscustomobject]@{ Plugin = $entry; Result = "Updated to $($f.Tag) [new layout]" }
}

# --- Mode: ProgramData — zip has <plugin>\bin\64bit\<dll> + <plugin>\data ---
function Install-ProgramData($entry, $repo, $pattern) {
    $f = Fetch $entry $repo $pattern
    if (-not $f) { return }
    $inner = Get-ChildItem $f.Dir -Directory | Select-Object -First 1
    $dll = Get-ChildItem (Join-Path $inner.FullName "bin\64bit") -Filter *.dll | Select-Object -First 1
    $target = Join-Path $pluginsDir $inner.Name
    if (Test-Path $target) { Remove-Item $target -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Copy-Item $dll.FullName (Join-Path $target $dll.Name) -Force
    $dataSrc = Join-Path $inner.FullName "data"
    if (Test-Path $dataSrc) { Copy-Item $dataSrc (Join-Path $target "data") -Recurse -Force }
    $state[$entry] = $f.Tag; Save-State
    $script:results += [pscustomobject]@{ Plugin = $entry; Result = "Updated to $($f.Tag) [new layout]" }
}

# --- Mode: ExtractRoot — zip already carries obs-plugins\ / data\ / plugins\ prefixes ---
function Install-ExtractRoot($entry, $repo, $pattern) {
    $f = Fetch $entry $repo $pattern
    if (-not $f) { return }
    Copy-Item (Join-Path $f.Dir "*") $ObsDir -Recurse -Force
    $state[$entry] = $f.Tag; Save-State
    $script:results += [pscustomobject]@{ Plugin = $entry; Result = "Updated to $($f.Tag)" }
}

# --- Mode: BareDll — zip is just a .dll, goes to legacy bin ---
function Install-BareDll($entry, $repo, $pattern) {
    $f = Fetch $entry $repo $pattern
    if (-not $f) { return }
    Get-ChildItem $f.Dir -Filter *.dll | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $legacyBin $_.Name) -Force
    }
    $state[$entry] = $f.Tag; Save-State
    $script:results += [pscustomobject]@{ Plugin = $entry; Result = "Updated to $($f.Tag) [legacy]" }
}

# --- Mode: CopyFromMain — no GitHub binaries; copy installed copy ---
function Install-FromMain($entry, $keyword) {
    $dll = Get-ChildItem (Join-Path $MainObsDir "obs-plugins\64bit") -Filter *.dll -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -match $keyword } | Select-Object -First 1
    if (-not $dll) {
        $script:results += [pscustomobject]@{ Plugin = $entry; Result = "NOT FOUND in main OBS install - install manually" }
        return
    }
    Copy-Item $dll.FullName (Join-Path $legacyBin $dll.Name) -Force
    $dataDir = Get-ChildItem (Join-Path $MainObsDir "data\obs-plugins") -Directory -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -match $keyword } | Select-Object -First 1
    if ($dataDir) {
        $dest = Join-Path $legacyData $dataDir.Name
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
        Copy-Item $dataDir.FullName $dest -Recurse -Force
    }
    $script:results += [pscustomobject]@{ Plugin = $entry; Result = "Copied from main OBS [legacy]" }
}

# ============================================================
#  The plugin set (15)
# ============================================================
$jobs = @(
    { Install-ProgramData "Move Transition"   "exeldro/obs-move-transition"      "-windows-programdata\.zip$" },
    { Install-ProgramData "Source Clone"      "exeldro/obs-source-clone"         "-windows-programdata\.zip$" },
    { Install-ProgramData "Aitum Stream Suite" "Aitum/obs-aitum-stream-suite"    "-windows-programdata\.zip$" },
    { Install-NewFolder   "Advanced Masks"    "FiniteSingularity/obs-advanced-masks"    "-windows-x64\.zip$" "obs-advanced-masks" },
    { Install-NewFolder   "Composite Blur"    "FiniteSingularity/obs-composite-blur"    "-windows-x64\.zip$" "obs-composite-blur" },
    { Install-NewFolder   "Retro Effects"     "FiniteSingularity/obs-retro-effects"     "-windows-x64\.zip$" "obs-retro-effects" },
    { Install-ExtractRoot "StreamUP"          "StreamUPTips/obs-streamup"        "-windows-x64-obs33\.zip$" },
    { Install-ExtractRoot "SVG Source"        "FiniteSingularity/svg-source"     "-windows-x64\.zip$" },
    { Install-ExtractRoot "OBS Noise"         "FiniteSingularity/obs-noise"      "-windows\.zip$" },
    { Install-ExtractRoot "Stroke Glow Shadow" "FiniteSingularity/obs-stroke-glow-shadow" "-windows\.zip$" },
    { Install-BareDll     "Autostarter"       "DaviBe92/Autostarter"             "^autostarter\.zip$" },
    { Install-FromMain    "3D Effect"         "3d" },
    { Install-FromMain    "Freeze Filter"     "freeze" },
    { Install-FromMain    "Gradient Source"   "gradient" },
    { Install-FromMain    "Scene Notes Dock"  "notes" }
)

foreach ($job in $jobs) {
    try { & $job } catch {
        $results += [pscustomobject]@{ Plugin = "(see error)"; Result = "FAILED: $($_.Exception.Message)" }
        Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "=== Plugin update summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize | Out-String | Write-Host
Write-Host "Launch OBS and check Tools > Plugin Manager: everything should"
Write-Host "show under Installed (new-layout ones) or Legacy (the rest)."
