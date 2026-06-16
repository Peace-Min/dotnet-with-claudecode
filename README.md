[🇰🇷 한국어](./README.ko.md)

# dotnet-with-claudecode

.NET Development Tutorial with Claude Code

## Overview

This repository provides skills, rules, and agent configurations for .NET/WPF development using Claude Code.

## Contents

### [wpf-net472-airgap-dev-pack](./wpf-net472-airgap-dev-pack)

Claude Code plugin for WPF development.

## Requirements (closed-network PC)

- **Claude Code**
- **.NET 10 RTM SDK (10.0.300+)** — runs the C# hooks and builds the local MCP servers (a *preview* SDK produces MCP binaries that crash at startup)
- **NuGet access** — an approved internal feed (or nuget.org once) to vendor the tools during bootstrap
- **Visual Studio MSBuild** — to build the target net472/net48 solutions

`wpf-net472-airgap-dev-pack` is **offline**: it bundles its own MCP servers
(`WpfDevPackMcp`, `HandMirrorMcp`) and requires **no online MCP** — `context7`
and `microsoft-docs` / Microsoft Learn are **not used**. `serena` and `csharp-lsp`
are *optional* local tools.

## Quick start (closed network)

```bash
git clone <internal-mirror>/dotnet-with-claudecode.git   # or Peace-Min/dotnet-with-claudecode
cd dotnet-with-claudecode
pwsh ./setup.ps1            # one-time: builds bin/ (MCP servers + XamlStyler) + configures the knowledge path
claude --plugin-dir ./wpf-net472-airgap-dev-pack
```

git cannot auto-run a script on clone, so `setup.ps1` is the single bootstrap step.
At runtime everything is local/offline — no `dnx`, no NuGet resolution, no `git pull`.

Full docs: [`wpf-net472-airgap-dev-pack/README.md`](./wpf-net472-airgap-dev-pack/README.md).
Status / handoff: [`docs/plans/2026-06-16-net472-airgap-fork-progress.md`](./docs/plans/2026-06-16-net472-airgap-fork-progress.md).

### Alternative: install from the local marketplace

```bash
/plugin marketplace add Peace-Min/dotnet-with-claudecode
/plugin install wpf-net472-airgap-dev-pack@dotnet-net472-airgap-plugins
```

(Auto-update stays disabled on the closed network — transfer a freshly built bundle to update.)

## Git Hooks Setup

This repository includes shared git hooks for automated version bumping of `wpf-net472-airgap-dev-pack`.

### Installing Git Hooks

After cloning the repository, run one of the following:

```bash
# Option 1: Direct configuration
# 방법 1: 직접 설정
git config core.hooksPath .githooks

# Option 2: Use install script (Windows PowerShell)
# 방법 2: 설치 스크립트 사용 (Windows PowerShell)
.\.githooks\install.ps1

# Option 2: Use install script (Linux/Mac)
# 방법 2: 설치 스크립트 사용 (Linux/Mac)
./.githooks/install.sh
```

### What the Hook Does

- **pre-push**: Automatically bumps `wpf-net472-airgap-dev-pack` patch version when pushing changes to `wpf-net472-airgap-dev-pack/` directory (excluding `plugin.json` and `README.md`)

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](.github/CONTRIBUTING.md).

## License

This project is licensed under the [MIT License](LICENSE).

## Author

- **christian289** - [GitHub](https://github.com/christian289)
