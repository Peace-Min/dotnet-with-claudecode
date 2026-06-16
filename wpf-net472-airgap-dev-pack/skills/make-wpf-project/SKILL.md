---
description: "Scaffolds a new .NET Framework 4.7.2-4.8 (net472/net48) WPF project with dependency-free hand-rolled MVVM (BindableBase + RelayCommand). Use when starting a new net472/net48 WPF app from scratch. Usage: /wpf-net472-airgap-dev-pack:make-wpf-project <ProjectName> [--full|--prism]"
argument-hint: [ProjectName]
---

# WPF Project Scaffolder (net472/net48)

**If `$0` is empty, ask via AskUserQuestion: "Enter the WPF project name (e.g., MyApp)". Do NOT proceed until provided.**

Scaffold a **net48** (or net472 if asked) WPF app with dependency-free hand-rolled
MVVM. **No CommunityToolkit, no GenericHost, no DI framework, no global usings.**
Output compiles on **net472/net48 (C# 7.3)** — block-scoped namespaces; no nullable
reference types, records, init-only, target-typed `new`, file-scoped namespaces,
or `ImplicitUsings`.

> **Working in an EXISTING solution?** Do NOT scaffold a new project. Detect and
> match the existing project style (SDK-style vs legacy non-SDK, `packages.config`
> vs `PackageReference`, the existing root namespace and base classes) and add files
> in that style. This generator is for brand-new projects only.

## Usage

```bash
# Single-project net48 app (default, simplest)
/wpf-net472-airgap-dev-pack:make-wpf-project MyApp

# Multi-project (App + ViewModels + Core)
/wpf-net472-airgap-dev-pack:make-wpf-project MyApp --full

# Prism (opt-in; only if you already standardize on Prism for .NET Framework)
/wpf-net472-airgap-dev-pack:make-wpf-project MyApp --prism
```

---

## Default structure (single project)

Keeps `ICommand`/`CommandManager` in one WPF project (no cross-assembly WPF
reference friction):

```
$0/
├── $0.sln
└── $0/
    ├── $0.csproj            # SDK-style, net48, UseWPF, LangVersion 7.3
    ├── App.xaml             # StartupUri=MainWindow.xaml
    ├── App.xaml.cs
    ├── MainWindow.xaml
    ├── MainWindow.xaml.cs   # DataContext = new MainViewModel()
    ├── Mvvm/
    │   ├── BindableBase.cs  # hand-rolled (rules/mvvm-constraints.md)
    │   └── RelayCommand.cs  # hand-rolled (RelayCommand + RelayCommand<T>)
    ├── ViewModels/
    │   └── MainViewModel.cs
    └── Views/
```

`--full` adds `$0.ViewModels` (classlib) and `$0.Core` (classlib). If ViewModels
live in a separate assembly, that assembly must reference `PresentationCore` /
`WindowsBase` so it can use `System.Windows.Input.ICommand` (the only allowed WPF
type in a ViewModel — see `rules/mvvm-constraints.md`).

---

## Generated files

### $0.csproj (SDK-style, net48 — verified to build)

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net48</TargetFramework>
    <UseWPF>true</UseWPF>
    <RootNamespace>$0</RootNamespace>
    <AssemblyName>$0</AssemblyName>
    <LangVersion>7.3</LangVersion>
  </PropertyGroup>

</Project>
```

> SDK-style targeting `net48` is the concise modern form and builds clean. If the
> shop standardizes on **legacy non-SDK** `.csproj` + `packages.config`, generate
> that style instead (match what their other projects use). Use `net472` instead
> of `net48` only if the user asks.

### App.xaml / App.xaml.cs

```xml
<Application x:Class="$0.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
    <Application.Resources>
    </Application.Resources>
</Application>
```

```csharp
using System.Windows;

namespace $0
{
    public partial class App : Application
    {
    }
}
```

### MainWindow.xaml / code-behind (code-behind DataContext — simplest wiring)

```xml
<Window x:Class="$0.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="{Binding Title}" Height="600" Width="800">
    <Grid>
        <TextBlock Text="{Binding Title}" HorizontalAlignment="Center"
                   VerticalAlignment="Center" FontSize="24" />
    </Grid>
</Window>
```

```csharp
using System.Windows;
using $0.ViewModels;

namespace $0
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            DataContext = new MainViewModel();
        }
    }
}
```

### Mvvm/BindableBase.cs and Mvvm/RelayCommand.cs

Generate both verbatim from `rules/mvvm-constraints.md` (hand-rolled
`BindableBase : INotifyPropertyChanged`, and `RelayCommand` / `RelayCommand<T> :
ICommand` with `CommandManager` auto-requery). Both compile on net472/net48 (C# 7.3).

### ViewModels/MainViewModel.cs

```csharp
using $0.Mvvm;

namespace $0.ViewModels
{
    public sealed class MainViewModel : BindableBase
    {
        private string _title = "$0";
        public string Title
        {
            get { return _title; }
            set { SetProperty(ref _title, value); }
        }
    }
}
```

> No `GlobalUsings.cs` — global usings require C# 10. Use explicit `using` per file.
> No CommunityToolkit, no `Microsoft.Extensions.Hosting`, no source generators.

---

## CLI commands

```bash
dotnet new sln -n $0
mkdir $0
# create the SDK-style net48 csproj above, App.xaml(.cs), MainWindow.xaml(.cs),
# Mvvm/*.cs, ViewModels/MainViewModel.cs, then:
dotnet sln add $0/$0.csproj
```

> If the org builds with Visual Studio MSBuild (not `dotnet build`), open the
> solution in VS or build with the discovered MSBuild (see `## Build` in
> `.claude/CLAUDE.md`). Restore only from approved local/internal NuGet feeds.

---

## Next steps

1. Add a screen: `/wpf-net472-airgap-dev-pack:make-wpf-viewmodel <Name> --with-view`
2. Add a CustomControl: `/wpf-net472-airgap-dev-pack:make-wpf-custom-control <Name>`
3. Add a Converter: `/wpf-net472-airgap-dev-pack:make-wpf-converter <Name>`
4. Add a Service: `/wpf-net472-airgap-dev-pack:make-wpf-service <Name>`

---

## Related knowledge topics (via WpfDevPackMcp)

- `structuring-wpf-projects` — project / solution structure
- `implementing-handrolled-mvvm` — the hand-rolled MVVM pattern

> **Prism projects (opt-in only):** see [PRISM.md](PRISM.md). net472/net48 uses
> Prism 7.2 / 8.1, not Prism 9 (which is .NET 8+ only). Never auto-introduce Prism.
