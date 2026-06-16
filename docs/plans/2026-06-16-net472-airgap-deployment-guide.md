# wpf-net472-airgap-dev-pack — Deployment & Verification Guide

Operational guide for installing and verifying the fork on a closed-network
(air-gapped) Windows PC. Companion to the
[handoff doc](2026-06-15-wpf-net472-airgap-fork-handoff.md) and the
[progress report](2026-06-16-net472-airgap-fork-progress.md).

- **Last updated:** 2026-06-16 (Asia/Seoul)
- **Branch:** `feat/net472-airgap-fork`

---

## 1. Prerequisites on the closed PC

| Requirement | Why | Notes |
|---|---|---|
| **.NET 10 RTM SDK (10.0.300+)** | Runs the C# hooks; builds WpfDevPackMcp; vendors HandMirror/XamlStyler | A *preview* SDK produces MCP binaries that crash at startup. Verify: `dotnet --list-sdks` shows a non-preview `10.0.3xx`. |
| **Claude Code** | Host | — |
| **NuGet access** | Vendor the tools during bootstrap; restore target-app packages | An approved internal feed, or nuget.org once. No *runtime* resolution after bootstrap. |
| **Visual Studio MSBuild** | Build the target net472/net48 solutions | Discover via `vswhere.exe`. |
| **net472/net48 Developer Pack** | Build target apps | Usually present with VS; install the Developer Pack if missing. |

> The plugin's hooks and MCP run on **.NET 10** (tooling runtime). The WPF apps it
> develops target **net472/net48** — independent of the tooling runtime.

---

## 2. One-time setup

```powershell
git clone <internal-mirror>/dotnet-with-claudecode.git
cd dotnet-with-claudecode
pwsh ./setup.ps1            # or: powershell -ExecutionPolicy Bypass -File ./setup.ps1
claude --plugin-dir ./wpf-net472-airgap-dev-pack
```

`setup.ps1` (idempotent; re-run only after pulling new commits):

1. Verifies a stable .NET 10 SDK ≥ 10.0.300 (`-AllowPreviewSdk` to override; not recommended).
2. Runs `wpf-net472-airgap-dev-pack/tools/build-local-bin.ps1` to produce `bin/`.
3. Writes `~/.wpf-net472-airgap-dev-pack-mcp/config.json` pointing the knowledge MCP at this clone (no `set-repo-path` needed).

Build-script options (forwarded by `setup.ps1`): `-Source <feed>`,
`-SelfContained`, `-XamlStylerVersion <v>`, `-AllowPreviewSdk`.

---

## 3. Bill of materials (what gets vendored)

`bin/` is git-ignored and produced by the bootstrap (transfer it with the plugin
if you prep the bundle on a different machine):

| Path | Source | Purpose |
|---|---|---|
| `wpf-net472-airgap-dev-pack/bin/WpfDevPackMcp/WpfDevPackMcp.exe` | `dotnet publish mcp/` | Knowledge MCP server (offline) |
| `wpf-net472-airgap-dev-pack/bin/HandMirrorMcp/handmirror.exe` | `dotnet tool install HandMirrorMcp` | API-signature MCP (local assemblies/NuGet) |
| `wpf-net472-airgap-dev-pack/bin/XamlStyler/xstyler.exe` | `dotnet tool install XamlStyler.Console` | XAML formatter (CodeFormatter hook) |

Also part of the offline bundle (acquire once, transfer in): the .NET 10 RTM SDK
installer, the net472/48 Developer Pack, VS Build Tools + `vswhere.exe`, and a
local NuGet folder feed for representative target solutions. Record hashes,
versions, licenses, and provenance for every transferred artifact.

### Offline NuGet feed (target-app builds and tool vendoring)

```xml
<!-- nuget.config: offline feed only -->
<configuration>
  <packageSources>
    <clear />
    <add key="local" value="C:\offline-nuget" />
  </packageSources>
</configuration>
```

Vendor the tools from the same feed: `pwsh ./setup.ps1 -Source "C:\offline-nuget"`.

---

## 4. Verification checklist

Run on a machine with **outbound network blocked** (not merely disconnected after
caches were warmed).

| Area | Check | Pass when |
|---|---|---|
| Bootstrap | `pwsh ./setup.ps1` completes | `bin/{WpfDevPackMcp,HandMirrorMcp,XamlStyler}` exist; `config.json` written |
| MCP startup | Open Claude Code with `--plugin-dir`; the BootstrapCheck hook is silent | both MCP servers start; `search_wpf_topics` returns hits |
| MCP after cache cleanup | Clear the global NuGet/`uv` caches, restart | servers still start (no `dnx`/NuGet resolution) |
| Knowledge | Ask a WPF question | a local topic is fetched (`get_wpf_topic`), e.g. `implementing-handrolled-mvvm` |
| Guardrails | New session | the net472/offline/hand-rolled rules are injected (Net472GuardrailsLoader) |
| Generator (VM) | `/wpf-net472-airgap-dev-pack:make-wpf-viewmodel Foo --with-view` | emits hand-rolled `BindableBase`/`RelayCommand`, block-scoped namespace, no CTK |
| Generator (project) | `/wpf-net472-airgap-dev-pack:make-wpf-project Bar` | SDK-style **net48** + UseWPF, LangVersion 7.3; builds with 0 errors |
| MVVM violation | Write a ViewModel using `CommunityToolkit.Mvvm` | MvvmViolationDetector flags CTK + any `System.Windows.*` |
| Formatting | Edit a `.xaml` file | CodeFormatter runs the vendored `xstyler.exe` (no dnx) |
| Target build | Build a real net472 solution | correct VS MSBuild builds Debug/Release; restore from the local feed only |
| No network | Throughout | no outbound network access during normal operation |

---

## 5. Updating (closed network)

1. On a connected machine, pull the new commit and rebuild the bundle (`setup.ps1`).
2. Transfer the updated plugin (+ `bin/`) into the closed network.
3. Re-run `pwsh ./setup.ps1` on the closed PC. Keep marketplace auto-update **disabled**.

---

## 6. Troubleshooting

- **MCP won't start / `MissingMethodException` at startup** → the binaries were
  built with a *preview* .NET 10 SDK. Rebuild with the RTM SDK (10.0.300+).
- **"Local MCP executables are not built yet"** (BootstrapCheck) → run `setup.ps1`.
- **HandMirror/XamlStyler not found** → the shim names are `handmirror.exe` /
  `xstyler.exe`; confirm `bin/HandMirrorMcp/` and `bin/XamlStyler/` exist.
- **Knowledge "repo not configured"** → `config.json` is missing/wrong; re-run
  `setup.ps1`, or set `/wpf-net472-airgap-dev-pack:set-repo-path <clone-root>`.
- **`dotnet format` fails on a legacy non-SDK project** → format with the existing
  Visual Studio / EditorConfig workflow instead; the C# format step is best-effort.
