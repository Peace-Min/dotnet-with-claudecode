<#
.SYNOPSIS
    One-time bootstrap for the wpf-net472-airgap-dev-pack fork. Run ONCE after
    `git clone` on the closed-network PC.

.DESCRIPTION
    git itself cannot run scripts on clone, so this is the single command that
    makes a fresh clone usable. It:

      1. Verifies the .NET 10 RTM SDK (>= 10.0.300) is present.
      2. Builds the local MCP / formatter executables into the plugin's bin/
         (WpfDevPackMcp from source + HandMirrorMcp + XamlStyler) via
         tools/build-local-bin.ps1 — no `dnx`/NuGet resolution will happen at
         runtime afterwards.
      3. Configures the WpfDevPackMcp knowledge path to THIS clone, so the
         knowledge MCP works without running /wpf-net472-airgap-dev-pack:set-repo-path.
      4. Prints the exact `claude --plugin-dir` command to start using it.

    Assumes (all confirmed available on the target PC): .NET 10 RTM SDK, Claude
    Code, NuGet access (nuget.org or an internal feed), Visual Studio MSBuild.
    It does NOT install any of those.

.PARAMETER Source
    NuGet feed for the HandMirror / XamlStyler tool installs (forwarded to
    tools/build-local-bin.ps1). Default nuget.org; pass an internal feed if needed.

.PARAMETER SelfContained
    Build WpfDevPackMcp self-contained (bundles the runtime; ~80 MB, zero runtime
    coupling). Off by default — the target already has the .NET 10 runtime.

.PARAMETER XamlStylerVersion
    Pin the XamlStyler.Console version (forwarded). Empty = latest on the feed.

.PARAMETER AllowPreviewSdk
    Build even if only a preview .NET 10 SDK is found (forwarded). NOT recommended:
    preview SDKs produce MCP binaries that crash at startup.

.EXAMPLE
    pwsh ./setup.ps1
    pwsh ./setup.ps1 -Source 'C:\internal-nuget' -XamlStylerVersion '3.2303.3'
#>
[CmdletBinding()]
param(
    [string]$Source = 'https://api.nuget.org/v3/index.json',
    [switch]$SelfContained,
    [string]$XamlStylerVersion = '',
    [switch]$AllowPreviewSdk
)

$ErrorActionPreference = 'Stop'

$RepoRoot    = $PSScriptRoot
$PluginDir   = Join-Path $RepoRoot 'wpf-net472-airgap-dev-pack'
$BuildScript = Join-Path $PluginDir 'tools/build-local-bin.ps1'

Write-Host '== wpf-net472-airgap-dev-pack bootstrap ==' -ForegroundColor Cyan
Write-Host "Repo (this clone): $RepoRoot"

if (-not (Test-Path $BuildScript)) {
    throw "Build script not found at $BuildScript. Run setup.ps1 from the repo root of a full clone."
}

# 1) .NET 10 RTM SDK check (informational here; build-local-bin enforces it)
$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
if (-not $dotnet) { throw 'dotnet SDK not found on PATH. Install the .NET 10 RTM SDK (10.0.300+).' }
$sdks = & dotnet --list-sdks
$haveRtm = $sdks | Where-Object {
    $_ -match '^(\d+)\.(\d+)\.(\d+)' -and
    [int]$Matches[1] -eq 10 -and [int]$Matches[3] -ge 300 -and $_ -notmatch 'preview|rc|alpha|beta'
}
if ($haveRtm) {
    Write-Host "Found stable .NET 10 SDK: $($haveRtm | Select-Object -First 1)" -ForegroundColor DarkGray
} elseif (-not $AllowPreviewSdk) {
    Write-Warning 'No stable .NET 10 SDK >= 10.0.300 found. Install the RTM SDK, or re-run with -AllowPreviewSdk (binaries may crash at startup).'
}

# 2) Build the local executables into the plugin's bin/
Write-Host "`n[1/2] Building local MCP executables..." -ForegroundColor Cyan
$buildArgs = @{ Source = $Source }
if ($SelfContained)    { $buildArgs.SelfContained = $true }
if ($XamlStylerVersion){ $buildArgs.XamlStylerVersion = $XamlStylerVersion }
if ($AllowPreviewSdk)  { $buildArgs.AllowPreviewSdk = $true }
& $BuildScript @buildArgs

# 3) Configure the WpfDevPackMcp knowledge path -> this clone (auto, no set-repo-path)
Write-Host "`n[2/2] Configuring knowledge repo path..." -ForegroundColor Cyan
$baseDir = Join-Path $env:USERPROFILE '.wpf-net472-airgap-dev-pack-mcp'
New-Item -ItemType Directory -Force -Path $baseDir | Out-Null
$configPath  = Join-Path $baseDir 'config.json'
$repoPathJson = ($RepoRoot -replace '\\', '/')
$json = @"
{
  "repoPath": "$repoPathJson",
  "branch": "main"
}
"@
# Write UTF-8 without BOM (works the same under Windows PowerShell 5.1 and pwsh 7)
[System.IO.File]::WriteAllText($configPath, $json)
Write-Host "  knowledge repoPath -> $RepoRoot"
Write-Host "  written            -> $configPath"

# 4) Next steps
Write-Host "`nBootstrap complete." -ForegroundColor Green
Write-Host 'Use the plugin from this clone:' -ForegroundColor Green
Write-Host "    claude --plugin-dir `"$PluginDir`""
Write-Host ''
Write-Host 'At runtime everything is local/offline (WPFDEVPACK_OFFLINE=1): no dnx, no NuGet'
Write-Host 'resolution, no git pull. Re-run setup.ps1 only after pulling new commits.'
