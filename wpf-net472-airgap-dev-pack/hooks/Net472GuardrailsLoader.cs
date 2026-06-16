#!/usr/bin/env dotnet

// net472 Guardrails Loader Hook (SessionStart)
//
// Injects the always-on hard guardrails for this fork — target-framework
// preservation (net472/net48), offline-only operation, and dependency-free
// hand-rolled MVVM — into the session context. Plugin .claude/rules and
// .claude/CLAUDE.md are NOT auto-loaded for installed users (plugins deliver
// context only through skills, agents, and hooks), so these must ship as a
// SessionStart hook to actually take effect.
//
// Input:  stdin JSON (SessionStart payload). Consumed but unused.
// Output: a system-context rule block on stdout.

// Consume stdin for protocol compatibility, even though we don't read it.
_ = Console.In.ReadToEnd();

Console.Write(
    """
    [wpf-net472-airgap-dev-pack] net472/net48 + offline + MVVM hard rules — ENFORCED this session.

    This plugin maintains EXISTING Windows WPF apps on .NET Framework 4.7.2–4.8 (net472/net48) in an air-gapped environment. It does NOT modernize them. Apply these before writing or changing any code:

    1. NEVER modernize the framework. Do not raise TargetFramework/TargetFrameworkVersion, retarget to .NET (Core) netX.0, or convert the project format unless the user explicitly asks. New projects default to net48 (net472 if asked).
    2. Detect & preserve the existing project shape BEFORE editing: SDK-style vs legacy non-SDK csproj; PackageReference vs packages.config; app.config + assembly binding redirects; platform target (AnyCPU/x86/x64, Prefer32Bit); existing build configurations.
    3. Match the project's effective C# LangVersion. Do not assume 7.3 from the framework alone, but NEVER emit syntax the project cannot compile. When LangVersion is unknown/default for net472, write C# 7.3-safe code: NO nullable reference types, records, init-only setters, target-typed `new`, file-scoped namespaces, global usings, ImplicitUsings, `using` declarations, ranges/indices, top-level statements, raw string literals, list/relational patterns, or primary constructors. Verify with HandMirrorMcp analyze_csproj / get_type_info when unsure.
    4. MVVM is dependency-free hand-rolled and works anywhere. ViewModels derive from a hand-rolled `BindableBase : INotifyPropertyChanged` (SetProperty / RaisePropertyChanged); commands are hand-rolled `RelayCommand` / `RelayCommand<T> : ICommand`. If the project has no such base classes, CREATE them once (e.g. Mvvm/BindableBase.cs + Mvvm/RelayCommand.cs), then reuse them. NO CommunityToolkit.Mvvm (no ObservableObject / [ObservableProperty] / [RelayCommand] / source generators). NO framework auto-detection (no DevExpress / CTK / Prism sniffing). If a project already has its own base classes/wiring, preserve them.
    5. Offline only. Use local source, local assemblies, local NuGet feeds, local docs, and preinstalled tools. NEVER run `git pull`, marketplace updates, `uvx git+https://…`, or online NuGet restore/search as an implicit action. If information is missing, ask the user — do not reach the network.
    6. Build with the solution's established Visual Studio MSBuild (discover via vswhere.exe or an admin-provided path); restore only from approved local/internal feeds. A clean compile does not instantiate XAML — verify representative views/templates at runtime.

    Do NOT introduce CommunityToolkit.Mvvm, Prism, Generic Host, or any DI/MVVM framework unless the user explicitly asks. The plugin's own hooks/MCP run on .NET 10 — that is the tooling runtime, separate from the net472/net48 target of the apps.

    """);
