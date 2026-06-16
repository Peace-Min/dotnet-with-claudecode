[🇰🇷 한국어](./README.ko.md)

<div align="center">

# 🎨 wpf-net472-airgap-dev-pack

### The Ultimate WPF Development Toolkit for Claude Code

[![Version](https://img.shields.io/badge/version-1.7.4-blue.svg)](https://github.com/christian289/dotnet-with-claudecode)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![.NET](https://img.shields.io/badge/.NET_SDK-10.0.300+-purple.svg)](https://dotnet.microsoft.com/)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-orange.svg)](https://claude.ai)

**14 Skills** · **10 Specialized Agents** · **2 MCP Servers**

[Installation](#-installation) · [Quick Start](#-quick-start) · [Features](#-features) · [Documentation](#-documentation)

---

</div>

## ✨ Highlights

> **MVVM Composition Style**: wpf-net472-airgap-dev-pack enforces a single matching path per MVVM framework, both with **Stateful ViewModel**:
> - **CommunityToolkit.Mvvm** (default) → **ViewModel First Composition** via `Mappings.xaml` + implicit DataTemplate.
> - **Prism 9** (alternative) → **View First Composition** via `RegisterForNavigation` + `IRegionManager.RequestNavigate`.
>
> Prism `ViewModelLocator.AutoWireViewModel`, code-behind `DataContext = new VM()`, inline XAML `DataContext`, and Stateless-VM patterns are prohibited (see [`.claude/rules/prohibitions.md`](./.claude/rules/prohibitions.md) and [`docs/TERMINOLOGY.md`](./docs/TERMINOLOGY.md)).
>
> Pre-v1.6.4 docs labeled this uniformly as "View First MVVM" — that label conflicted with Microsoft's official definition (lookup key for `Mappings.xaml` is the ViewModel type → ViewModel First). v1.6.4 corrects the labels per path; the enforced code rules are unchanged.

<table>
<tr>
<td width="50%">

### 🤖 AI-Powered Development
- **10 Specialized Agents** for different WPF tasks
- **Session-model agnostic** — agents inherit your current model
- **MCP-served knowledge** — search-before-answer via WpfDevPackMcp
- **Prism 9** companion files for dual-framework support

</td>
<td width="50%">

### 🛠️ Complete Toolkit
- **14 command Skills** + on-demand WPF knowledge via MCP
- **Best practices** built-in

</td>
</tr>
<tr>
<td width="50%">

### 📚 Local Knowledge (offline)
- **WpfDevPackMcp** serves WPF topics from a local clone (no network)
- **HandMirrorMcp** verifies APIs against local assemblies/NuGet
- **Semantic code analysis** with Serena (optional, local)

</td>
<td width="50%">

### ⚡ High Performance
- **DrawingContext** rendering patterns
- **Virtualization** strategies
- **Memory optimization** techniques

</td>
</tr>
</table>

---

## 📦 Installation

### Quick start (closed network — recommended)

On the air-gapped PC (which has the .NET 10 RTM SDK, Claude Code, NuGet access, and VS MSBuild):

```bash
git clone <your-internal-remote>/dotnet-with-claudecode.git
cd dotnet-with-claudecode
pwsh ./setup.ps1          # one-time: builds bin/ (MCP servers + XamlStyler) + configures the knowledge path
claude --plugin-dir ./wpf-net472-airgap-dev-pack
```

`setup.ps1` is the single bootstrap step (git cannot auto-run a script on clone). Re-run it only after pulling new commits. At runtime everything is local/offline — no `dnx`, no NuGet resolution, no `git pull`. A SessionStart hook reminds you if `bin/` is not built yet.

> No `pwsh`? It also runs under Windows PowerShell 5.1: `powershell -ExecutionPolicy Bypass -File ./setup.ps1`.

### From Marketplace

```bash
# Step 1: Add the marketplace (one-time)
/plugin marketplace add Peace-Min/dotnet-with-claudecode

# Step 2: Install the plugin
/plugin install wpf-net472-airgap-dev-pack@dotnet-net472-airgap-plugins
```

### Local Installation

```bash
claude --plugin-dir ./wpf-net472-airgap-dev-pack
```

### Updating (closed network)

Auto-update is **off and must stay off**. Update only by transferring a freshly
built bundle from outside the network — never let the plugin or marketplace pull
on its own.

```bash
# Apply an approved new bundle, then (optionally) reinstall locally:
claude --plugin-dir ./wpf-net472-airgap-dev-pack
```

> **Note:** Third-party marketplaces have auto-update disabled by default. Keep it disabled.

### Requirements

| Requirement | Version | Notes |
|-------------|---------|-------|
| .NET SDK | **10.0.300+ (RTM)** | Runs the C# hooks and builds the local MCP servers. A *preview* .NET 10 SDK produces MCP binaries that crash at startup — use the RTM SDK. |
| Claude Code | Latest | - |
| uv | Latest | **Optional** — only if you choose to run Serena locally |

> **Target Framework vs support SDK**: .NET SDK 10.0.300+ only **runs the plugin** (hooks + local MCP build).
> The WPF code this fork generates and maintains targets **.NET Framework 4.7.2–4.8 (`net472`/`net48`)**, which is independent of the support SDK.

### MCP servers (local / offline)

This fork **bundles its MCP servers and requires no online MCP.** Build them once
during bundle prep on a machine that can reach an approved feed; afterwards they
run from `bin/` with no `dnx`/NuGet resolution at startup:

```powershell
pwsh ./tools/build-local-bin.ps1
# builds bin/WpfDevPackMcp (from ../mcp) and vendors HandMirrorMcp + XamlStyler.Console
```

| MCP Server | Bundled | Purpose |
|---|---|---|
| **WpfDevPackMcp** | ✅ `bin/WpfDevPackMcp` | Local WPF knowledge topics (offline; reads a local clone, never pulls) |
| **HandMirrorMcp** | ✅ `bin/HandMirrorMcp` | Verifies namespaces/signatures against local assemblies & NuGet |

**Removed online dependencies:** `context7` and `microsoft-docs` / Microsoft
Learn are **not used and not required**. The plugin does not check for them and
does not degrade without them.

**Optional local tools** (the plugin works fully without them — install only from
approved offline packages, never fetched at runtime):

| Tool | Purpose | If absent |
|---|---|---|
| [**serena**](https://github.com/oraios/serena) | Semantic code analysis, symbol navigation | Agents fall back to Read/Grep/Glob. If used, install directly via `uv` (not the Claude Code plugin path — see the [Attention note](https://oraios.github.io/serena/02-usage/030_clients.html#claude-code)). |
| [**csharp-lsp**](https://github.com/razzmatazz/csharp-language-server) | C# LSP (definition, references, diagnostics) | `wpf-code-reviewer` falls back to text analysis. |

---

## 🚀 Quick Start

### Create a New WPF Project

```bash
# With CommunityToolkit.Mvvm (Recommended)
/wpf-net472-airgap-dev-pack:make-wpf-project MyApp

# With Prism Framework
/wpf-net472-airgap-dev-pack:make-wpf-project MyApp --prism
```

### Generate Components

```bash
# CustomControl
/wpf-net472-airgap-dev-pack:make-wpf-custom-control MyButton Button

# UserControl
/wpf-net472-airgap-dev-pack:make-wpf-usercontrol SearchBox

# Converter
/wpf-net472-airgap-dev-pack:make-wpf-converter BoolToVisibility

# Behavior
/wpf-net472-airgap-dev-pack:make-wpf-behavior SelectAllOnFocus TextBox
```

### Ask for Help

```
"How do I create a high-performance chart control?"
"Review this ViewModel from MVVM perspective"
"Optimize this rendering code for large datasets"
```

---

## 🎯 Requirements Interview System

When you invoke `wpf-architect`, an **adaptive path-based interview** identifies your exact needs:

### How It Works

```
Step 1: Task Type Selection
   ├─→ Path A: Create new project (7 steps)
   ├─→ Path B: Analyze/improve existing (5 steps)
   ├─→ Path C: Implement feature (5 steps)
   └─→ Path D: Debug/fix (4 steps)
```

Each path asks targeted questions with **keyword analysis** on free-input steps to auto-configure subsequent defaults.

### Interview Paths

| Path | Task Type | Steps | Focus |
|------|-----------|:-----:|-------|
| **A** | Create new project | 7 | Concept → Architecture → Scale → Complexity → Libraries → Feature areas |
| **B** | Analyze/improve | 5 | Goal → Analysis mode → Scope → Output format |
| **C** | Implement feature | 5 | Description → Approach → Libraries → Feature areas |
| **D** | Debug/fix | 4 | Symptoms → Problem type → Problem area |

### Example Flow (Path A)

```
User: "I want to build a chart app with WPF"

wpf-architect: [A-1] What kind of app? Describe the concept.
   → User: "Real-time stock chart dashboard"
   (Keywords detected: "chart", "real-time" → LiveCharts2, performance defaults)

wpf-architect: [A-2] Architecture pattern?
   → User selects: "MVVM + CommunityToolkit"

wpf-architect: [A-3] Project scale?
   → User selects: "Medium (5-15 Views)"

wpf-architect: [A-5] 3rd-party libraries?
   → Auto-suggested: LiveCharts2 ✓, WPF-UI (optional)

Result: Activates LiveCharts2 + DrawingContext skills + wpf-performance-optimizer
```

---

## 🧠 How Knowledge Is Served

wpf-net472-airgap-dev-pack does **not** use a keyword-detection hook. WPF knowledge is served on demand by the **WpfDevPackMcp** MCP server — its own server instructions tell the agent to **search the topic catalog before answering** WPF/C#/.NET questions.

### How It Works

1. **You ask** a WPF/C#/.NET question (or invoke a command skill / agent).
2. **The agent searches** the catalog with `WpfDevPackMcp search_wpf_topics`, then loads the best matches with `get_wpf_topic`.
3. **Specialized agents** handle complex, multi-step tasks.

> The ~50 knowledge topics live as plain Markdown at `knowledge/<id>/TOPIC.md` in the repo and are fetched live — editing them needs no plugin rebuild or version bump. Run [`/wpf-net472-airgap-dev-pack:set-repo-path`](#-configuration) once to point the server at your local clone.

### Example Topics (served via MCP)

| You ask about | Topic |
|---------------|-------|
| Authoring a CustomControl | `authoring-wpf-controls` |
| MVVM with CommunityToolkit | `implementing-communitytoolkit-mvvm` |
| Rendering with DrawingContext | `rendering-with-drawingcontext` |
| High-performance rendering | `rendering-wpf-high-performance` |

For complex tasks, a specialized agent is recommended (e.g. `wpf-performance-optimizer` for rendering, `wpf-architect` for architecture reviews).

### Command Skills vs Knowledge

- **Command skills** (`/wpf-net472-airgap-dev-pack:<name>`) — slash-invocable generators and plugin operations (19 bundled; see **Skills & Knowledge** below).
- **Knowledge topics** — reference content served by WpfDevPackMcp; kept out of the session skill listing (no per-session context cost).

---

## 🎯 Features

### 🤖 Specialized Agents

> All agents inherit the current session model. Run `/model` to switch (e.g. Opus 1M ↔ Sonnet ↔ Haiku).

| Agent | Specialty |
|-------|-----------|
| 🏗️ **wpf-architect** | Strategic architecture & design decisions |
| 🎨 **wpf-control-designer** | CustomControl implementation |
| 📐 **wpf-xaml-designer** | XAML styles & templates |
| 🔄 **wpf-mvvm-expert** | MVVM pattern & CommunityToolkit |
| 🔗 **wpf-data-binding-expert** | Complex bindings & validation |
| ⚡ **wpf-performance-optimizer** | Rendering & performance |
| 🔍 **wpf-code-reviewer** | Code quality analysis |
| 🔎 **wpf-code-auditor** | Full-codebase pattern & consistency audit |
| 📝 **code-formatter** | C# formatting & style |
| 🔧 **serena-initializer** | Project setup |

### 🔌 MCP Servers

| Plugin | MCP Server | Purpose |
|--------|-----------|---------|
| **HandMirrorMcp** | HandMirrorMcp | .NET assembly/NuGet inspection (bundled, local) |
| **WpfDevPackMcp** | WpfDevPackMcp | WPF knowledge topics from a local repo clone (bundled, local) |
| _(optional, `uv`)_ | **serena** | Semantic code analysis (optional, local) |
| _(optional)_ | **csharp-lsp** | C# LSP code intelligence (optional, local) |

> Both bundled MCP servers run from `bin/` with no network. `context7` and `microsoft-docs` / Microsoft Learn are **not used**. Serena / csharp-lsp are optional — see [MCP servers (local / offline)](#mcp-servers-local--offline) above.

### 📚 Skills & Knowledge

> **As of v1.7.0**, the ~50 WPF *knowledge* topics (MVVM, rendering, threading,
> styling, 3rd-party libraries, .NET common, Prism 9 companions, testing, …) are
> **no longer bundled as plugin skills**. They are served on demand by the
> **WpfDevPackMcp** MCP server via `get_wpf_topic` / `search_wpf_topics`; the
> server's own instructions tell the agent to search before answering. This keeps them out of the
> session's skill listing (no per-session context cost) while remaining editable
> as plain Markdown. See [`mcp/README.md`](../mcp/README.md) and
> [`/wpf-net472-airgap-dev-pack:set-repo-path`](#-configuration).

The plugin bundles **14 command skills** (slash-invocable):

<details>
<summary><b>🏗️ Scaffolding (7 skills)</b></summary>

| Skill | Description |
|-------|-------------|
| `make-wpf-project` | WPF project scaffolding with MVVM/DI |
| `make-wpf-custom-control` | CustomControl generation |
| `make-wpf-usercontrol` | UserControl generation |
| `make-wpf-converter` | IValueConverter generation |
| `make-wpf-behavior` | Behavior<T> generation |
| `make-wpf-viewmodel` | ViewModel + View + DI + DataTemplate mapping generation |
| `make-wpf-service` | Service interface + implementation + DI registration |

</details>

<details>
<summary><b>🎨 Code Quality (1 skill)</b></summary>

| Skill | Description |
|-------|-------------|
| `formatting-wpf-csharp-code` | C# / XAML formatting & style (auto-applied on edits by the CodeFormatter hook) |

</details>

<details>
<summary><b>🔧 Plugin Operations (6 skills)</b></summary>

| Skill | Description |
|-------|-------------|
| `collecting-wpf-net472-airgap-dev-pack-feedback` | Capture anonymized feedback docs for later application |
| `configuring-wpf-net472-airgap-dev-pack-language` | Set the per-project response language (`.claude/wpf-net472-airgap-dev-pack.local.md`) |
| `set-repo-path` | Configure the local repo-clone path WpfDevPackMcp reads knowledge from |
| `set-repo-branch` | Set the git branch WpfDevPackMcp tracks (`config.json`) |
| `set-repo-managed` | Set the server-managed flag (`state.json`) — destructive vs non-destructive refresh |
| `show-wpf-net472-airgap-dev-pack-config` | Show the WpfDevPackMcp `config.json` / `state.json` paths and values |

</details>

---

## 📁 Plugin Structure

```
wpf-net472-airgap-dev-pack/
├── 📁 .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── 📁 agents/                 # 10 Specialized agents
│   ├── wpf-architect.md
│   ├── wpf-code-auditor.md
│   ├── wpf-code-reviewer.md
│   ├── wpf-control-designer.md
│   ├── wpf-xaml-designer.md
│   ├── wpf-mvvm-expert.md
│   ├── wpf-data-binding-expert.md
│   ├── wpf-performance-optimizer.md
│   ├── code-formatter.md
│   └── serena-initializer.md
├── 📁 skills/                 # 14 command skills
├── 📁 hooks/                  # Event hooks
├── 📄 .mcp.json               # MCP config (HandMirrorMcp + WpfDevPackMcp)
├── 📄 README.md
└── 📄 LICENSE
```

---

## 🔧 Configuration

### Serena MCP Setup

> ⚠️ **Required**: Install [uv](https://docs.astral.sh/uv/) to use Serena.

```bash
# Test Serena locally
uvx --from git+https://github.com/oraios/serena serena start-mcp-server
```

### C# LSP (Required for IntelliSense)

```bash
claude /install-plugin csharp-lsp
```

---

## 📖 Documentation

### Official References

- 📘 [WPF Samples (Microsoft)](https://github.com/microsoft/WPF-Samples)
- 📗 [WPF Graphics & Multimedia](https://learn.microsoft.com/dotnet/desktop/wpf/graphics-multimedia/)
- 📙 [Claude Code Plugin Spec](https://code.claude.com/docs/en/plugins-reference)

### Architecture Reference

- [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) - Agent-based orchestration pattern

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

<div align="center">

**Made with ❤️ by vincent lee**

[⬆ Back to Top](#-wpf-net472-airgap-dev-pack)

</div>
