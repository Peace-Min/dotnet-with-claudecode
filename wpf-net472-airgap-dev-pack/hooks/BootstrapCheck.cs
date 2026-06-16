#!/usr/bin/env dotnet

// Bootstrap Check Hook (SessionStart)
//
// On a freshly cloned repo the local MCP executables under bin/ do not exist yet
// (bin/ is git-ignored and produced by the one-time bootstrap). If they are
// missing, the WpfDevPackMcp / HandMirrorMcp servers cannot start, so this hook
// tells the user the single command to run. Once bin/ is built it emits nothing.
//
// Plugin root is resolved from the CLAUDE_PLUGIN_ROOT env var, falling back to
// args[0] (hooks.json passes "${CLAUDE_PLUGIN_ROOT}" as an argument too). If
// neither is available the hook stays silent rather than warn incorrectly.
//
// Input:  stdin JSON (SessionStart payload). Consumed but unused.
// Output: a one-time bootstrap instruction on stdout, or nothing.

_ = Console.In.ReadToEnd();

var pluginRoot = Environment.GetEnvironmentVariable("CLAUDE_PLUGIN_ROOT");
if (string.IsNullOrWhiteSpace(pluginRoot) && args.Length > 0)
    pluginRoot = args[0];

if (string.IsNullOrWhiteSpace(pluginRoot) || !Directory.Exists(pluginRoot))
    return; // cannot locate the plugin reliably — stay silent

var binDir = Path.Combine(pluginRoot, "bin", "WpfDevPackMcp");
var built = File.Exists(Path.Combine(binDir, "WpfDevPackMcp.exe"))
         || File.Exists(Path.Combine(binDir, "WpfDevPackMcp.dll"));
if (built)
    return; // already bootstrapped

var repoRoot = Path.GetFullPath(Path.Combine(pluginRoot, ".."));
var setupPath = Path.Combine(repoRoot, "setup.ps1");

Console.Write($$"""
    [wpf-net472-airgap-dev-pack] Local MCP executables are not built yet, so the WpfDevPackMcp / HandMirrorMcp servers will not start. Run the one-time bootstrap ONCE per clone:

        pwsh "{{setupPath}}"
        (or, if pwsh is not installed: powershell -ExecutionPolicy Bypass -File "{{setupPath}}")

    It builds bin/ (WpfDevPackMcp + HandMirrorMcp + XamlStyler) and points the knowledge MCP at this clone. It needs the .NET 10 RTM SDK and NuGet access — both already available on this machine. Everything is local/offline afterwards (no dnx, no runtime NuGet, no git pull).

    """);
