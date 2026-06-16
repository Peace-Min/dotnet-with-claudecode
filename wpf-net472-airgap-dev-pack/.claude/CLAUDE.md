# WPF Dev Pack - Configuration

WPF knowledge is served on demand by the WpfDevPackMcp MCP server
(search-before-answer); command skills are slash-invocable. There is no
keyword-detection hook.

---

## MCP Servers (all local / offline)

This fork ships its own MCP servers and depends on **NO online MCP**. The
plugin's `.mcp.json` launches them from local executables under `bin/` (built
once by `tools/build-local-bin.ps1`); there is no `dnx`/NuGet resolution at
process start, so they keep starting after a NuGet/`uv` cache cleanup.

| MCP Server | Bundled | Purpose |
|---|---|---|
| **WpfDevPackMcp** | ✅ `bin/WpfDevPackMcp` | Serves local WPF knowledge topics (offline; reads a local clone, never pulls) |
| **HandMirrorMcp** | ✅ `bin/HandMirrorMcp` | Verifies exact namespaces / API signatures before writing code |

### Offline mode (hard rule)

Use only local source, local assemblies, local NuGet feeds, local documentation,
and preinstalled tools. Never, as an implicit action, run `git pull`, marketplace
updates, `uvx git+https://…`, online NuGet search/restore against public feeds,
or any other network fetch. If information is missing, ask the user rather than
reaching out to the network.

### Removed online dependencies

**context7** and **microsoft-docs / Microsoft Learn** are NOT used and NOT
required. Do not treat them as a correctness dependency, recommend installing
them, or claim degraded results because they are absent.

### Optional local tools (not required)

These enhance some agents but the plugin works fully without them. Install only
from approved offline packages — never fetch them at runtime.

| Tool | Purpose | If absent |
|---|---|---|
| **serena** | Semantic code analysis, symbol navigation | Agents fall back to Read/Grep/Glob. Install via `uv` from a transferred copy if desired. |
| **csharp-lsp** | C# LSP code intelligence | `wpf-code-reviewer` falls back to text analysis. |

---

## MVVM Composition Style

This fork uses ONE MVVM style for all generated code: **dependency-free,
hand-rolled MVVM** that compiles on net472/net48 with no external MVVM package
and works in any project.

- ViewModels derive from a hand-rolled **`BindableBase : INotifyPropertyChanged`**
  (`SetProperty` / `RaisePropertyChanged`). Commands are hand-rolled
  **`RelayCommand` / `RelayCommand<T> : ICommand`**.
- If the project has no such base classes, **create them once** (e.g. under
  `Mvvm/BindableBase.cs` + `Mvvm/RelayCommand.cs`), then reuse them. The
  `make-wpf-viewmodel` scaffolder emits them if absent.
- **No CommunityToolkit.Mvvm** — no `ObservableObject`, `[ObservableProperty]`,
  `[RelayCommand]`, or source generators. **No framework auto-detection**
  (no DevExpress/CTK/Prism sniffing) — always emit the hand-rolled form.
- View/ViewModel wiring uses a single explicit mechanism per project; see
  `rules/view-viewmodel-wiring-handrolled.md`. **Preserve** whatever an existing
  project already uses (its own base class, DataTemplate mapping, etc.).

> **Prism** stays available only as an explicit opt-in for projects that already
> use it — never the default. See `rules/view-viewmodel-wiring-prism.md`.

See `rules/mvvm-constraints.md` and `rules/prohibitions.md` for details.

---

## Essential (Post-Compact)

These rules MUST survive context compression. If prior context is lost, re-read this section:

1. **Target is .NET Framework 4.7.2–4.8** — never modernize the framework, project format, package-management style, or C# version; detect & preserve the existing project shape. Default emitted C# is **7.3-safe** (see `## Target Framework`).
2. **Offline only** — local source/assemblies/feeds/docs and preinstalled tools; no network fetch, no `dnx`/`uvx`/online NuGet restore or search.
3. **MVVM is dependency-free hand-rolled** `BindableBase`/`RelayCommand` — no CommunityToolkit, no framework auto-detection; create the base classes if absent (`rules/mvvm-constraints.md`).
4. **No System.Windows in ViewModel** — BCL types only (`rules/mvvm-constraints.md`)
5. **Freeze all Freezable objects** — Brush, Pen, Geometry (`rules/freezable-performance.md`)
6. **Generic.xaml = MergedDictionaries hub only** (`rules/resourcedictionary-patterns.md`)
7. **Verify API signatures with HandMirrorMcp (local) before writing code**
8. **WPF knowledge topics are fetched via `WpfDevPackMcp get_wpf_topic(id)`** — not loaded from `skills/`.

---

## Per-Project Language Preference

The plugin supports a per-project response-language preference, read by
the `LanguagePreferenceLoader` SessionStart hook at the start of every
new conversation.

- **Configure**: run `/wpf-net472-airgap-dev-pack:configuring-wpf-net472-airgap-dev-pack-language`
  to write `.claude/wpf-net472-airgap-dev-pack.local.md` with a `language:` field
  (BCP-47 code, e.g. `ko`, `en`, `ja`, `zh`).
- **Effect**: from the next session onward, the hook injects a directive
  into the system context telling Claude to respond in that language.
  The current session is not affected by an in-session change because
  SessionStart hooks fire only at session start.
- **Scope**: applies to user-facing responses within the wpf-net472-airgap-dev-pack
  context. Skill content language policy (SKILL.md body, code comments)
  is unaffected — it remains English.
- **Override**: the user can always override in-conversation
  ("respond in English" / "한글로 답해줘"). The hook only sets the
  default for the session.
- **Revert**: delete `.claude/wpf-net472-airgap-dev-pack.local.md` or remove its
  `language:` field. The hook will then emit nothing, and the plugin's
  default language behavior applies.

The file is personal and is covered by the repo's `.gitignore`
(`.claude/*.local.md`).

## Target Framework — .NET Framework 4.7.2–4.8 (net472/net48)

This fork **maintains and extends existing** Windows WPF apps on **.NET Framework
4.7.2–4.8**. It does NOT modernize them. The default target is `net472`/`net48`,
not .NET (Core) `netX.0`.

### Hard guardrails (highest priority — survive context compression)

1. **Never modernize the framework.** Do NOT raise `TargetFrameworkVersion` /
   `TargetFramework`, retarget to `netX.0`, or convert the project format unless
   the user explicitly asks. New projects default to `net48` (or `net472` if asked).
2. **Detect and preserve the existing project shape** before editing:
   - SDK-style vs non-SDK (legacy MSBuild XML) `.csproj`
   - `PackageReference` vs `packages.config`
   - `app.config` + assembly **binding redirects**, platform target
     (`AnyCPU`/`x86`/`x64`, `Prefer32Bit`), and existing build configurations
3. **Match the project's effective C# language version.** Do NOT assume C# 7.3
   from the framework alone — a `net472` project may compile with a newer Roslyn.
   But never EMIT syntax the project can't compile. When `LangVersion` is unknown
   or default for net472, target **C# 7.3** (see table below). Verify with
   HandMirrorMcp `analyze_csproj` / `get_type_info` when unsure.
4. **Preserve MVVM composition.** Keep the project's existing View/ViewModel
   wiring and base classes. Default generated MVVM is dependency-free hand-rolled
   `BindableBase`/`RelayCommand` (`rules/mvvm-constraints.md`). Do NOT introduce
   CommunityToolkit.Mvvm, Prism, Generic Host, or any DI/MVVM framework unless
   explicitly requested.
5. **Offline only.** Use local assemblies, local NuGet feeds, and approved local
   docs. No restore against public feeds; no `dnx`/`uvx`/online NuGet search.

### C# language features safe on net472/net48 (default C# 7.3)

Default to **C# 7.3** unless the csproj proves a higher `LangVersion`.

| Feature | Safe by default on net472? |
|---|---|
| tuples, `out var`, `is`/`switch` pattern matching, local functions | ✅ yes (C# 7.x) |
| `async`/`await`, `in`/`ref readonly`, `Span<T>` (via `System.Memory`) | ✅ yes |
| expression-bodied members, `nameof`, string interpolation | ✅ yes |
| nullable reference types (`#nullable`, `?` annotations) | ❌ no (C# 8) |
| `using` declarations, default interface members, ranges/indices | ❌ no (C# 8) |
| records, init-only setters, target-typed `new`, top-level statements | ❌ no (C# 9) |
| file-scoped namespaces, global usings, `ImplicitUsings` | ❌ no (C# 10 / SDK-style) |

If the project sets a higher `LangVersion`, the corresponding features may be used — verify first.

### Build & verification

- Build with the solution's established **Visual Studio MSBuild** toolchain.
  Discover it via `vswhere.exe` (or an admin-provided fixed MSBuild path):
  `& $MSBuildPath .\Product.sln /m /t:Build /p:Configuration=Debug`.
- Use `dotnet build` only for solutions proven to support it. **Never** restore
  against public feeds — use an approved local/internal feed only.
- A clean compile does not instantiate XAML; verify representative views/templates
  load at runtime where practical.

> The plugin's own support runtime (hooks, MCP) uses .NET 10 — that is the tooling
> runtime, independent of the net472/net48 **target** of the apps being developed.

---

## Core Rules

```
RULE 1: For WPF/C#/.NET questions → search WpfDevPackMcp topics before answering (search_wpf_topics → get_wpf_topic)
RULE 2: Delegate complex tasks to specialized agents
RULE 3: Announce command-skill activation
RULE 4: Select the most specific topic/skill when multiple match
RULE 5: wpf-architect MUST conduct Requirements Interview before analysis
```

---

## Requirements Interview System

When `wpf-architect` is invoked, conduct an **adaptive path-based interview** using AskUserQuestion:

| Path | Task Type | Steps | Focus |
|------|-----------|-------|-------|
| **A** | Create new project | 7 | concept → architecture → scale → complexity → libraries → feature areas |
| **B** | Analyze/improve | 5 | analysis goal → analysis mode → scope → output format |
| **C** | Implement feature | 5 | feature description → implementation approach → libraries → feature areas |
| **D** | Debug/fix | 4 | symptom → problem type → problem area |

**Keyword Analysis**: At free-input steps (A-2, B-2, C-2, D-2), detect keywords and auto-set defaults for subsequent steps.

See `agents/wpf-architect.md` for full interview specification.

## Trigger Priority

1. **Explicit slash command** (`/wpf-net472-airgap-dev-pack:skill-name`) → command skills
2. **WPF knowledge** → search/fetch via WpfDevPackMcp (`search_wpf_topics` → `get_wpf_topic`); see `skills/.claude/CLAUDE.md`
3. **Context-based inference** → delegate to a specialized agent

## Trigger Behavior

**On Trigger:**
1. Announce: "wpf-net472-airgap-dev-pack: Activating `skill-name` skill."
2. Default MVVM is dependency-free hand-rolled `BindableBase`/`RelayCommand`
   (`rules/mvvm-constraints.md`). Follow a framework path only if the project
   already uses one and the user is keeping it.
3. Load content:
   - **Knowledge topics** → call `WpfDevPackMcp get_wpf_topic(id[, variant])` to fetch from MCP
   - **Command skills** → invoked via slash command (`/wpf-net472-airgap-dev-pack:<skill-name>`)
   - **Default (hand-rolled) skills** → SKILL.md
   - **Prism (opt-in, only for projects already on Prism)** → PRISM.md if present, otherwise SKILL.md
4. Generate/modify code per guidelines and the project's existing conventions

**Silent application** (no announcement):
- `formatting-wpf-csharp-code` — applied automatically by the `CodeFormatter` PostToolUse hook on `.cs` / `.xaml` edits.

**Multiple Keywords:**
1. Most specific first (e.g., "drawingcontext" > "performance")
2. Related skills can be referenced in parallel
3. Ask user if conflict

---

## Adding a New Skill — Required Co-updates

**Adding a knowledge topic** (WPF knowledge, served via MCP — NOT a plugin skill):
1. Create `knowledge/<id>/TOPIC.md` (at the repo root, outside the plugin) with the topic content. **No YAML frontmatter.** The first `# H1` is the title; put a one-line `> summary` blockquote directly under the H1 — the MCP catalog (`TopicDocReader`) reads title from the first H1 and summary from the first `>` blockquote.
2. No router edit, no plugin skill registration, no version bump, no MCP rebuild — the MCP catalog auto-discovers the new directory and `search_wpf_topics` surfaces it on the next `git pull`.

**Adding a command skill** (slash-invocable plugin skill under `skills/`):

When adding a new skill at `skills/<skill-name>/SKILL.md`, these files MUST be updated together:

1. **`skills/.claude/CLAUDE.md`** — add a row to the retained-command table.
2. **Adjacent existing SKILL.md files** — when topics overlap, add a cross-link to the new skill (`See [...](../skill-name/SKILL.md)`).
3. **Skills that need a Prism 9 branch** — author a `PRISM.md` companion file (see `mvvm-framework.md`).
4. **Foundation + Application skill pairs** — author the two skills separately and cross-reference. Foundation skill describes the mechanism / general principle; Application skill applies it to a specific scenario (e.g., `preventing-dispatcher-deadlock` + `shutting-down-wpf-gracefully`).
