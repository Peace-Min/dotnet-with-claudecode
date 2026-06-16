<#
.SYNOPSIS
    Builds / vendors every executable the wpf-net472-airgap-dev-pack plugin needs
    into <plugin>/bin so the air-gapped machine never resolves packages at runtime.

.DESCRIPTION
    Produces three self-contained tool folders under the plugin's bin/ directory,
    referenced by .mcp.json and hooks via ${CLAUDE_PLUGIN_ROOT}/bin/...:

      bin/WpfDevPackMcp   <- dotnet publish of ../../mcp (knowledge MCP server)
      bin/HandMirrorMcp   <- dotnet tool install HandMirrorMcp   (API-signature MCP)
      bin/XamlStyler      <- dotnet tool install XamlStyler.Console (XAML formatter)

    Run this ONCE during bundle preparation on a machine that can reach the feed
    (-Source). The resulting bin/ is then transferred into the closed network as
    part of the offline bundle. At runtime there is no dnx / NuGet resolution, so
    the servers keep starting even after the global NuGet/uv caches are cleared.

.PARAMETER Source
    NuGet feed for the tool installs. Default: nuget.org. For an air-gapped build
    machine, point this at an approved internal feed or a local folder feed
    (e.g. -Source 'C:\offline-nuget').

.PARAMETER HandMirrorVersion
    Pinned HandMirrorMcp version. Default 0.1.1 (matches upstream .mcp.json).

.PARAMETER XamlStylerVersion
    Pinned XamlStyler.Console version. Empty = latest on the feed. Pin this for a
    reproducible bundle.

.EXAMPLE
    pwsh ./tools/build-local-bin.ps1
    pwsh ./tools/build-local-bin.ps1 -Source 'C:\offline-nuget' -XamlStylerVersion '3.2303.3'
#>
[CmdletBinding()]
param(
    [string]$Source = 'https://api.nuget.org/v3/index.json',
    [string]$HandMirrorVersion = '0.1.1',
    [string]$XamlStylerVersion = '',
    # Self-contained bundles the .NET runtime with WpfDevPackMcp (zero runtime
    # coupling, ~80 MB). Off by default: the target already needs the .NET 10
    # runtime for the C# hooks, so a framework-dependent build is smaller and
    # consistent with the HandMirror / XamlStyler tools.
    [switch]$SelfContained,
    [string]$Rid = 'win-x64',
    # WpfDevPackMcp targets net10.0 and pulls Microsoft.Extensions.AI, which calls
    # a .NET 10 RTM System.Text.Json API (JsonElement.Parse(ReadOnlySpan<byte>)).
    # A preview/early .NET 10 SDK produces binaries that crash at startup with
    # MissingMethodException. Building requires a STABLE .NET 10 SDK 10.0.300+.
    [switch]$AllowPreviewSdk
)

$ErrorActionPreference = 'Stop'

$PluginRoot = Split-Path -Parent $PSScriptRoot           # <repo>/wpf-net472-airgap-dev-pack
$RepoRoot   = Split-Path -Parent $PluginRoot             # <repo>
$BinDir     = Join-Path $PluginRoot 'bin'
$McpProj    = Join-Path $RepoRoot 'mcp/WpfDevPackMcp.csproj'

function Resolve-DotnetOrThrow {
    $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
    if (-not $dotnet) { throw "dotnet SDK not found on PATH. Install .NET SDK 10.0.300+ first." }
    $sdks = & dotnet --list-sdks
    Write-Host "Using dotnet SDKs:`n$($sdks -join "`n")" -ForegroundColor DarkGray

    # Require a stable .NET 10 SDK 10.0.3xx+. A preview SDK silently produces a
    # WpfDevPackMcp.exe that throws MissingMethodException at startup, so refuse
    # to build unless explicitly overridden.
    $ok = $sdks | Where-Object {
        $_ -match '^(\d+)\.(\d+)\.(\d+)' -and
        [int]$Matches[1] -eq 10 -and [int]$Matches[3] -ge 300 -and
        $_ -notmatch 'preview|rc|alpha|beta'
    }
    if (-not $ok -and -not $AllowPreviewSdk) {
        throw ("No stable .NET 10 SDK >= 10.0.300 found. WpfDevPackMcp needs a .NET 10 RTM SDK; " +
               "a preview SDK produces binaries that crash at startup. Install the RTM SDK, or " +
               "pass -AllowPreviewSdk to build anyway (not recommended for a shipped bundle).")
    }
}

function Remove-IfExists([string]$path) {
    if (Test-Path $path) { Remove-Item -Recurse -Force $path }
}

Resolve-DotnetOrThrow
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

# 1) WpfDevPackMcp — build from source (knowledge MCP server)
Write-Host "`n[1/3] Publishing WpfDevPackMcp from $McpProj (self-contained=$SelfContained)" -ForegroundColor Cyan
if (-not (Test-Path $McpProj)) { throw "MCP source not found at $McpProj (run from the full repo, not a plugin-only copy)." }
$mcpOut = Join-Path $BinDir 'WpfDevPackMcp'
Remove-IfExists $mcpOut
$pubArgs = @('publish', $McpProj, '-c', 'Release', '-o', $mcpOut, '--nologo')
if ($SelfContained) { $pubArgs += @('-r', $Rid, '--self-contained', 'true') }
& dotnet @pubArgs
if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed (exit $LASTEXITCODE)." }

# 2) HandMirrorMcp — vendor the published dnx tool (API-signature MCP)
Write-Host "`n[2/3] Installing HandMirrorMcp $HandMirrorVersion from $Source" -ForegroundColor Cyan
$handOut = Join-Path $BinDir 'HandMirrorMcp'
Remove-IfExists $handOut
& dotnet tool install HandMirrorMcp --version $HandMirrorVersion --tool-path $handOut --add-source $Source
if ($LASTEXITCODE -ne 0) { throw "HandMirrorMcp install failed (exit $LASTEXITCODE)." }

# 3) XamlStyler.Console — vendor the XAML formatter used by the CodeFormatter hook
Write-Host "`n[3/3] Installing XamlStyler.Console from $Source" -ForegroundColor Cyan
$xsOut = Join-Path $BinDir 'XamlStyler'
Remove-IfExists $xsOut
$xsArgs = @('tool','install','XamlStyler.Console','--tool-path',$xsOut,'--add-source',$Source)
if ($XamlStylerVersion) { $xsArgs += @('--version',$XamlStylerVersion) }
& dotnet @xsArgs
if ($LASTEXITCODE -ne 0) { throw "XamlStyler.Console install failed (exit $LASTEXITCODE)." }

# Summary — report the produced executables so .mcp.json / hooks can be verified
Write-Host "`nVendored executables under $BinDir :" -ForegroundColor Green
Get-ChildItem -Path $BinDir -Recurse -Include *.exe | ForEach-Object {
    Write-Host ("  {0}" -f $_.FullName.Substring($PluginRoot.Length + 1))
}
Write-Host "`nDone. Transfer the whole bin/ folder with the plugin into the closed network." -ForegroundColor Green
