# WPF .NET Framework 4.7.2 Air-Gapped Claude Code Plugin Fork

## Document purpose

This is the source-of-truth handoff for customizing the private working fork of
[`christian289/dotnet-with-claudecode`](https://github.com/christian289/dotnet-with-claudecode).

This is **not a Gajae-Code implementation task**. The target runtime is the user's existing
**Claude Code installation operated from VS Code in an air-gapped Windows environment**.

Last reviewed: 2026-06-15 (Asia/Seoul)

Upstream baseline reviewed:

- Repository: `christian289/dotnet-with-claudecode`
- Commit: `cf27bbe2a513430f17f5d644aae6bfe094e54cff`
- Commit subject: `feat(wpf-dev-pack): v1.7.4 - streaming chat skills, MCP config skills, authoring-rules hook, animated-theming knowledge`
- Plugin manifest version: `1.7.4`
- License: MIT; retain upstream copyright and license notices.

Fork status:

- Fork repository: `Peace-Min/dotnet-with-claudecode`
- Fork URL: <https://github.com/Peace-Min/dotnet-with-claudecode>
- Local clone: `C:\Users\minph\OneDrive\문서\GitHub\dotnet-with-claudecode`
- `origin`: `https://github.com/Peace-Min/dotnet-with-claudecode.git`
- `upstream`: `https://github.com/christian289/dotnet-with-claudecode.git`
- Current local baseline: `cf27bbe2a513430f17f5d644aae6bfe094e54cff`
- Fork and local clone were created on 2026-06-15.

## User environment and objective

- Editor/host: VS Code with Claude Code
- Network: closed/air-gapped after approved software transfer
- Main application stack: Windows WPF on .NET Framework 4.7.2 (`net472`)
- Existing projects may use legacy non-SDK-style `.csproj`, `packages.config`,
  `app.config`, binding redirects, Visual Studio MSBuild, and an established MVVM pattern.
- Objective: create a private fork of `wpf-dev-pack` optimized for reliable offline work
  against existing `net472` WPF applications.

The fork should preserve useful WPF expertise while preventing the agent from silently
modernizing the target framework, language version, project format, package-management
style, or MVVM composition.

## Decisions already made

1. Forking is preferred over using the upstream plugin unchanged.
2. The target application framework remains `.NET Framework 4.7.2`.
3. The plugin support runtime may use .NET 10. The MCP and hook runtime does not need to
   target `net472`; target-project compatibility and support-tool runtime are separate.
4. `context7` is unavailable and must not be required, recommended as an active tool, or
   treated as a correctness dependency.
5. Microsoft Learn MCP is also assumed unavailable unless the organization supplies an
   internal mirror or proxy.
6. Tools that normally install through `dnx`, `uvx`, NuGet, Git, or a marketplace may be
   downloaded once outside the closed network and transferred in, but routine execution
   must not depend on cache restoration or external package resolution.
7. Existing project architecture takes priority. The fork must not introduce
   CommunityToolkit.Mvvm, Prism, Generic Host, `Mappings.xaml`, RegionManager, or another
   composition model unless explicitly requested.
8. New-project generators from upstream are not safe defaults because they generate
   `net10.0-windows` projects and current C# patterns.

## Corrected compatibility assessment

The upstream plugin is more usable with `net472` than an initial high-level reading
suggested:

- `CommunityToolkit.Mvvm 8.4` provides a `netstandard2.0` asset and is package-compatible
  with `net472`.
- `Microsoft.Extensions.Hosting 10` provides a .NET Framework 4.6.2 asset and is
  package-compatible with `net472`.
- Installing .NET SDK 10 for plugin hooks does not by itself upgrade the target project.

Package compatibility does **not** mean these packages should be introduced into an
existing application. The fork must preserve the solution's current dependencies unless
the user requests a migration.

## Upstream behavior that matters

### Support runtime

- Hooks are C# file-based apps and require .NET SDK `10.0.300+`.
- The plugin invokes hooks with `dotnet <hook.cs>`.
- XAML formatting invokes:

  ```text
  dotnet dnx -y XamlStyler.Console -- ...
  ```

- C# formatting invokes:

  ```text
  dotnet format "<project.csproj>" --include "<file.cs>" --no-restore
  ```

### MCP configuration

The upstream `.mcp.json` invokes:

```json
{
  "mcpServers": {
    "HandMirrorMcp": {
      "type": "stdio",
      "command": "dnx",
      "args": ["HandMirrorMcp@0.1.1", "--yes"]
    },
    "WpfDevPackMcp": {
      "type": "stdio",
      "command": "dnx",
      "args": ["WpfDevPackMcp@0.1.3", "--yes"]
    }
  }
}
```

This is convenient online, but operationally fragile in a closed network because it
relies on NuGet tool resolution and cache state at process start.

### Knowledge source

`WpfDevPackMcp` reads WPF topics from a local clone after
`/wpf-dev-pack:set-repo-path <path>`. This is suitable for offline use once the repository
and server binary are present. Repository refresh operations must not be required during
normal offline operation.

### Opinionated architecture

The upstream rules enforce:

- CommunityToolkit path: ViewModel-first composition using `Mappings.xaml`
- Prism 9 path: View-first composition using `RegisterForNavigation` and RegionManager
- Prohibitions against code-behind `DataContext`, inline XAML `DataContext`,
  `ViewModelLocator.AutoWireViewModel`, alternate matching paths, and stateless ViewModels

These are upstream product choices, not universal WPF correctness rules. They must be
converted from global prohibitions to opt-in guidance in this fork.

## Required fork changes

### 1. Identity and scope

- Rename the plugin to avoid confusion with upstream, for example
  `wpf-net472-airgap-dev-pack`.
- Update manifest description, repository URL, documentation, command namespace, and
  local configuration names.
- Preserve MIT attribution.
- State that the plugin targets existing Windows WPF `.NET Framework 4.7.2` solutions.

### 2. Offline dependency policy

- Remove `context7` from required MCP checks and all agent tool declarations.
- Remove Microsoft Learn MCP from required MCP checks and active tool declarations unless
  an internal endpoint is explicitly configured.
- Do not execute `git pull`, marketplace updates, `uvx git+https://...`, online NuGet
  search, or package download as an implicit action.
- Add a clear offline-mode rule: use local source, local assemblies, local package feeds,
  local documentation, and preinstalled tools only.
- Disable plugin marketplace auto-update on the closed network.

### 3. Local executable packaging

Prefer deterministic local commands over package-runner caches:

```json
{
  "mcpServers": {
    "WpfDevPackMcp": {
      "type": "stdio",
      "command": "${CLAUDE_PLUGIN_ROOT}/bin/WpfDevPackMcp.exe"
    },
    "HandMirrorMcp": {
      "type": "stdio",
      "command": "${CLAUDE_PLUGIN_ROOT}/bin/HandMirrorMcp.exe"
    }
  }
}
```

Before adopting this exact form, verify that the current Claude Code plugin runtime
expands `${CLAUDE_PLUGIN_ROOT}` in `.mcp.json` on the target Windows machine.

Package or document all required runtime files under a stable plugin-relative path:

- `WpfDevPackMcp`
- `HandMirrorMcp`
- XamlStyler executable and dependencies, if automatic formatting remains enabled
- Serena launcher/runtime, if Serena is retained
- C# language server and runtime

Do not assume that warming the global NuGet or `uv` cache once is sufficient for
repeatable deployment.

### 4. Target-project guardrails

Add high-priority project rules equivalent to:

```md
- Target framework is .NET Framework 4.7.2.
- Never upgrade TargetFrameworkVersion or convert the project format unless requested.
- Detect and preserve SDK-style vs. non-SDK-style csproj.
- Detect and preserve PackageReference vs. packages.config.
- Respect the project's effective C# LangVersion.
- Do not generate global usings, file-scoped namespaces, records, init-only properties,
  nullable reference syntax, or other unsupported syntax unless verified.
- Build with the solution's established Visual Studio MSBuild toolchain.
- Preserve app.config, assembly binding redirects, platform target, and existing build
  configurations.
- Preserve the current MVVM framework and View/ViewModel wiring.
- Do not add CommunityToolkit.Mvvm, Prism, Generic Host, or DI frameworks unless requested.
- Use only local assemblies, local NuGet feeds, and approved offline documentation.
```

The fork should inspect the solution before deciding the language version or project
style. Do not hard-code C# 7.3 solely from the target framework; projects can use a newer
compiler while still targeting `net472`.

### 5. Build and verification

- Detect Visual Studio installations using `vswhere.exe` or an administrator-provided
  fixed MSBuild path.
- Prefer solution-native commands, for example:

  ```powershell
  & $MSBuildPath .\Product.sln /m /t:Build /p:Configuration=Debug
  ```

- Keep `dotnet build` only for solutions proven to support it.
- Do not invoke restore against public feeds.
- Support an organization-provided folder feed or internal NuGet server.
- Treat XAML designer/runtime loading as a separate verification step where practical;
  a successful compile does not instantiate every template.

### 6. Formatting

- Make automatic post-edit formatting configurable and initially disabled for legacy
  solutions.
- Verify `dotnet format` against representative non-SDK-style `net472` projects before
  enabling it.
- If `dotnet format` is unsuitable, use an approved local formatter or leave formatting
  to the existing Visual Studio/EditorConfig workflow.
- Package XamlStyler locally or disable its automatic hook. Do not run `dnx` during normal
  closed-network sessions.
- Never apply a full-solution formatting pass without explicit approval.

### 7. Agents and skills

Keep and adapt:

- WPF architecture review
- XAML styles, templates, resources, bindings, converters, behaviors
- CustomControl and DependencyProperty implementation
- Dispatcher/threading guidance
- virtualization, rendering, Freezable, DrawingContext, and memory/performance guidance
- code review and codebase audit

Disable, remove, or heavily rewrite:

- `make-wpf-project` default modern scaffold
- streaming LLM chat generation and other .NET 10-oriented generators
- package recommendations that assume online NuGet
- agents that declare unavailable online MCP tools as mandatory
- unconditional CommunityToolkit/Prism composition enforcement

Generators that remain must first inspect:

- target framework and project format
- language version
- package-management style
- root namespace and assembly name
- existing folders and naming conventions
- current MVVM framework and DI/container usage

### 8. Knowledge additions

Add local topics for:

- non-SDK-style WPF `.csproj`
- `packages.config` and offline NuGet restore
- `app.config` and assembly binding redirects
- Visual Studio MSBuild discovery and invocation
- x86/x64/AnyCPU and `Prefer32Bit`
- .NET Framework reference assemblies and developer packs
- WPF designer/build-action issues (`Page`, `Resource`, `ApplicationDefinition`)
- `AppDomain`, legacy remoting/interoperability constraints where relevant
- `Dispatcher`, STA threading, COM interop, P/Invoke, and native DLL deployment
- legacy test frameworks used by the organization
- practical API availability checks for `net472`

## Offline transfer bundle

The deployment bundle should contain or document:

- Claude Code version approved for the closed network
- forked plugin at a pinned commit/tag
- .NET SDK 10.0.300+ runtime/installer for hooks and MCP support
- .NET Framework 4.7.2 Developer Pack/reference assemblies
- required Visual Studio Build Tools workload and `vswhere.exe`
- local MCP executables and all runtime dependencies
- optional Serena and C# LSP binaries/runtimes
- optional XamlStyler binaries
- NuGet packages required by representative solutions, including transitive dependencies
- local NuGet configuration with public feeds disabled
- hashes, versions, licenses, and provenance for every transferred artifact
- installation, rollback, and verification scripts

## Verification matrix

Test on a machine with outbound network access blocked, not merely disconnected
temporarily after caches were warmed.

| Area | Required verification |
| --- | --- |
| Claude Code startup | Plugin loads without attempting network access |
| MCP startup | Both local MCP servers start repeatedly after cache cleanup |
| Knowledge | Local WPF topic search/get works from the configured repository path |
| Existing solution | Agent identifies `net472`, project format, LangVersion, NuGet style, and MVVM style |
| Editing | Simple C# and XAML edits preserve project conventions |
| Build | Correct Visual Studio MSBuild builds Debug and Release as applicable |
| Restore | Build succeeds from approved local/internal feeds only |
| Formatting | No unwanted full-file or full-solution churn |
| XAML | Validation does not reject valid legacy constructs |
| Architecture | Agent does not introduce a new MVVM/DI framework without approval |
| Syntax | Generated code compiles with the effective project compiler settings |
| Runtime | Representative view/template is instantiated, not only compiled |
| Reboot/relogin | Tools still start after reboot and under the intended Windows account |
| Cache resilience | Removing global NuGet/uv caches does not break packaged local executables |

## Acceptance criteria

- Normal operation performs no unexpected outbound network access.
- A clean target machine can be provisioned entirely from the approved transfer bundle.
- Existing `net472` projects are never upgraded or converted without explicit approval.
- The agent preserves project and MVVM conventions by default.
- Build commands use the correct Visual Studio MSBuild.
- Required local MCP and language tools start deterministically.
- Removed online dependencies do not produce repeated warnings or degraded-agent claims.
- Generated C# and XAML compile in representative real-world solutions.
- Documentation contains exact versions, hashes, installation steps, and rollback steps.

## Work sequence for the next session

1. Work from `C:\Users\minph\OneDrive\문서\GitHub\dotnet-with-claudecode` and
   re-check for any newly added `AGENTS.md`, `CLAUDE.md`, or equivalent local instructions.
2. Record the exact upstream remote, fork remote, branch, and baseline commit.
3. Create an implementation inventory:
   - manifest and marketplace definitions
   - agents and their tool declarations
   - command skills
   - hooks and external process calls
   - `.mcp.json`
   - knowledge server and knowledge directory
   - all URLs, `dnx`, `uvx`, Git, NuGet, and update paths
4. Produce a dependency lock/bill of materials before code changes.
5. Implement offline dependency removal and local MCP launch first.
6. Add `net472` guardrails and legacy solution detection.
7. Adapt build and formatting behavior.
8. Rewrite agents, skills, and knowledge.
9. Build the transfer bundle.
10. Run the blocked-network verification matrix and record evidence.

Do not start broad generator rewrites before MCP startup and dependency packaging are
proven. Otherwise, failures in the support runtime will obscure target-project behavior.

## Open questions to resolve during implementation

- Is the target project SDK-style or legacy MSBuild XML?
- Does it use `packages.config` or `PackageReference`?
- What C# language version and Visual Studio version are actually installed?
- Which MVVM framework and composition pattern are already in use?
- Are internal NuGet, Git, documentation, or MCP endpoints available?
- Is Serena required, and can its full runtime be legally and operationally transferred?
- Does the installed C# language server fully support the representative legacy solution?
- Should automatic formatting be removed entirely or retained as an opt-in feature?
- Must the transfer bundle work for multiple Windows user accounts?
- What security review, hash manifest, SBOM, and license-report format is required?

## Evidence and source links

- Upstream repository:
  <https://github.com/christian289/dotnet-with-claudecode>
- Upstream plugin directory:
  <https://github.com/christian289/dotnet-with-claudecode/tree/main/wpf-dev-pack>
- CommunityToolkit.Mvvm 8.4 package compatibility:
  <https://www.nuget.org/packages/CommunityToolkit.Mvvm/8.4.0>
- Microsoft.Extensions.Hosting 10 package compatibility:
  <https://www.nuget.org/packages/Microsoft.Extensions.Hosting/10.0.0>

## Suggested next-session opening prompt

```text
Read docs/plans/2026-06-15-wpf-net472-airgap-fork-handoff.md in full.
This is an external Claude Code plugin fork task, not a Gajae-Code product change.
Then inspect the fork workspace and produce an inventory of every network-dependent,
modern-.NET-specific, build, formatter, MCP, agent, skill, and knowledge integration.
Use the documented upstream commit as the comparison baseline. Do not edit until the
inventory and dependency bill of materials are complete.
```
