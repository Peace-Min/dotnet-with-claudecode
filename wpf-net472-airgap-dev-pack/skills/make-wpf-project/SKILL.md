---
description: "Scaffolds a complete WPF project structure with MVVM, DI, and best practices. Use when starting a new WPF application, creating a WPF solution from scratch, or setting up project structure with CommunityToolkit.Mvvm or Prism. Usage: /wpf-net472-airgap-dev-pack:make-wpf-project <ProjectName> [--minimal|--full|--prism]"
argument-hint: [ProjectName]
---

# WPF Project Scaffolder

**If `$0` is empty, use the AskUserQuestion tool to ask: "Enter the WPF project name (e.g., MyApp, Dashboard)". Do NOT proceed until a valid name is provided. Use the response as the ProjectName for all subsequent steps.**

Scaffold a WPF project named `$0` with MVVM, DI, and best practices.

## Usage

```bash
# Default project (recommended) - CommunityToolkit.Mvvm + GenericHost
/wpf-net472-airgap-dev-pack:make-wpf-project $0

# Minimal structure
/wpf-net472-airgap-dev-pack:make-wpf-project $0 --minimal

# Full structure (all layers separated)
/wpf-net472-airgap-dev-pack:make-wpf-project $0 --full

# Prism framework (module-based architecture)
/wpf-net472-airgap-dev-pack:make-wpf-project $0 --prism
```

### Framework Options

| Option | Framework | Features |
|--------|-----------|----------|
| (default) | CommunityToolkit.Mvvm | Lightweight, Source Generator, GenericHost DI |
| `--prism` | Prism.DryIoc | Region Navigation, Module, Dialog Service |

> **Prism details**: See [PRISM.md](PRISM.md) for complete Prism project structure and examples.

> **Project naming (consistency contract)**: the WPF application project is
> suffixed **`.WpfApp`**. The `make-wpf-viewmodel` and `make-wpf-service`
> generators locate the app project by this suffix to place Views and register
> DI. Keep `.WpfApp` so the whole `make-wpf-*` family wires into one solution.

---

## Project Structures

### Default Structure

```
$0/
├── $0.sln
├── $0.WpfApp/                  # WPF Application (entry point + Views)
│   ├── App.xaml                # merges Mappings.xaml
│   ├── App.xaml.cs             # GenericHost + DI
│   ├── MainWindow.xaml         # shell: ContentControl nav host
│   ├── MainWindow.xaml.cs
│   ├── GlobalUsings.cs
│   ├── Mappings.xaml           # ViewModel→View DataTemplate map
│   ├── Views/
│   ├── Converters/
│   └── $0.WpfApp.csproj
├── $0.ViewModels/             # ViewModel (pure C#, no System.Windows)
│   ├── MainViewModel.cs
│   ├── GlobalUsings.cs
│   └── $0.ViewModels.csproj
└── $0.Core/                   # Business logic + service interfaces
    ├── Models/
    ├── Services/
    └── $0.Core.csproj
```

### Minimal Structure

```
$0/
├── $0.sln
└── $0/
    ├── App.xaml
    ├── App.xaml.cs
    ├── MainWindow.xaml
    ├── MainWindow.xaml.cs
    ├── Mappings.xaml
    ├── ViewModels/
    │   └── MainViewModel.cs
    ├── Views/
    ├── Models/
    ├── Services/
    └── $0.csproj
```

### Full Structure

```
$0/
├── $0.slnx
├── src/
│   ├── $0.Abstractions/       # Interfaces, abstract classes
│   ├── $0.Core/               # Business logic
│   ├── $0.ViewModels/         # ViewModel
│   ├── $0.WpfServices/        # WPF services (CollectionView etc.)
│   ├── $0.UI/                 # CustomControl library (Themes/Generic.xaml)
│   └── $0.WpfApp/             # WPF Application
└── tests/
    ├── $0.Core.Tests/
    └── $0.ViewModels.Tests/
```

### Prism Structure (`--prism`)

See [PRISM.md](PRISM.md) for complete structure.

---

## Composition Style (CommunityToolkit.Mvvm)

This scaffold establishes **ViewModel First Composition + Stateful ViewModel**
from the start:

- the shell `MainViewModel` exposes `CurrentViewModel`,
- the shell `MainWindow` hosts it in a `ContentControl`, and
- `Mappings.xaml` resolves the View from the ViewModel type via an implicit
  `DataTemplate` (no `x:Key`).

Add screens with `/wpf-net472-airgap-dev-pack:make-wpf-viewmodel <Name> --with-view`, which
appends one `DataTemplate` to `Mappings.xaml` and registers DI.
`ViewModelLocator`, code-behind `DataContext = new VM()`, and inline XAML
`DataContext` are prohibited (see `prohibitions.md`).

---

## Generated Files

### $0.WpfApp.csproj

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net10.0-windows</TargetFramework>
    <!-- Assembly is $0.WpfApp but root namespace is $0, so View/ViewModel
         namespaces ($0.Views / $0.ViewModels) line up across projects. -->
    <RootNamespace>$0</RootNamespace>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <UseWPF>true</UseWPF>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="CommunityToolkit.Mvvm" Version="8.4.*" />
    <PackageReference Include="Microsoft.Extensions.Hosting" Version="10.0.*" />
  </ItemGroup>

  <ItemGroup>
    <!-- Forward slashes: MSBuild accepts them on Windows, and a "\$" sequence
         in this skill body is consumed as an argument escape at invocation. -->
    <ProjectReference Include="../$0.ViewModels/$0.ViewModels.csproj" />
    <ProjectReference Include="../$0.Core/$0.Core.csproj" />
  </ItemGroup>

</Project>
```

### App.xaml (merges Mappings.xaml)

```xml
<Application x:Class="$0.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Application.Resources>
        <ResourceDictionary>
            <ResourceDictionary.MergedDictionaries>
                <ResourceDictionary Source="Mappings.xaml" />
            </ResourceDictionary.MergedDictionaries>
        </ResourceDictionary>
    </Application.Resources>
</Application>
```

> No `StartupUri` — the host resolves and shows `MainWindow` from DI in `OnStartup`.

### App.xaml.cs (with DI)

```csharp
namespace $0;

public partial class App : Application
{
    private readonly IHost _host;

    public App()
    {
        _host = Host.CreateDefaultBuilder()
            .ConfigureServices((context, services) =>
            {
                // Services — add with /wpf-net472-airgap-dev-pack:make-wpf-service
                // (that generator adds the registration + the GlobalUsings entry)

                // ViewModels
                services.AddSingleton<MainViewModel>();

                // Windows
                services.AddSingleton<MainWindow>();
            })
            .Build();
    }

    protected override async void OnStartup(StartupEventArgs e)
    {
        await _host.StartAsync();

        var mainWindow = _host.Services.GetRequiredService<MainWindow>();
        mainWindow.DataContext = _host.Services.GetRequiredService<MainViewModel>();
        mainWindow.Show();

        base.OnStartup(e);
    }

    protected override async void OnExit(ExitEventArgs e)
    {
        await _host.StopAsync();
        _host.Dispose();
        base.OnExit(e);
    }
}
```

### MainWindow.xaml (shell — ContentControl nav host)

```xml
<Window x:Class="$0.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="{Binding Title}" Height="600" Width="800">
    <!-- CurrentViewModel is resolved to its View by Mappings.xaml (ViewModel First). -->
    <ContentControl Content="{Binding CurrentViewModel}" />
</Window>
```

```csharp
namespace $0;

public partial class MainWindow : Window
{
    public MainWindow() => InitializeComponent();
}
```

### Mappings.xaml (ViewModel → View)

```xml
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                    xmlns:vm="clr-namespace:$0.ViewModels;assembly=$0.ViewModels"
                    xmlns:views="clr-namespace:$0.Views">

    <!-- /wpf-net472-airgap-dev-pack:make-wpf-viewmodel appends one entry per screen, e.g.:
    <DataTemplate DataType="{x:Type vm:HomeViewModel}">
        <views:HomeView />
    </DataTemplate>
    -->

</ResourceDictionary>
```

### MainViewModel.cs (shell)

```csharp
namespace $0.ViewModels;

public sealed partial class MainViewModel : ObservableObject
{
    [ObservableProperty] private string _title = "$0";

    // ViewModel First: assign a screen ViewModel to CurrentViewModel and
    // Mappings.xaml resolves the matching View into the shell ContentControl.
    // Set this once you add a screen with /wpf-net472-airgap-dev-pack:make-wpf-viewmodel.
    [ObservableProperty] private object? _currentViewModel;
}
```

### GlobalUsings.cs (WpfApp)

```csharp
global using System;
global using System.Collections.Generic;
global using System.Collections.ObjectModel;
global using System.Linq;
global using System.Threading.Tasks;
global using System.Windows;
global using CommunityToolkit.Mvvm.ComponentModel;
global using CommunityToolkit.Mvvm.Input;
global using Microsoft.Extensions.DependencyInjection;
global using Microsoft.Extensions.Hosting;
global using $0.ViewModels;
```

> When other generators need more global usings (e.g. `make-wpf-converter` needs
> `System.Windows.Data` / `System.Windows.Markup`), **append to this existing
> `GlobalUsings.cs`** — do not create a second `GlobalUsings.cs` in the same
> project (duplicate `global using` directives fail to compile).

---

## CLI Commands

```bash
# Create solution
dotnet new sln -n $0

# Create projects (note the .WpfApp suffix on the application project)
dotnet new wpf -n $0.WpfApp
dotnet new classlib -n $0.ViewModels
dotnet new classlib -n $0.Core

# Add projects to solution
dotnet sln add $0.WpfApp/$0.WpfApp.csproj
dotnet sln add $0.ViewModels/$0.ViewModels.csproj
dotnet sln add $0.Core/$0.Core.csproj

# Add project references
dotnet add $0.WpfApp reference $0.ViewModels
dotnet add $0.WpfApp reference $0.Core
dotnet add $0.ViewModels reference $0.Core

# Add packages
dotnet add $0.WpfApp package CommunityToolkit.Mvvm
dotnet add $0.WpfApp package Microsoft.Extensions.Hosting
dotnet add $0.ViewModels package CommunityToolkit.Mvvm
```

---

## Prism vs CommunityToolkit.Mvvm

| Feature | CommunityToolkit.Mvvm | Prism |
|---------|----------------------|-------|
| Base Class | `ObservableObject` | `BindableBase` |
| Command | `RelayCommand` (Source Gen) | `DelegateCommand` |
| DI Container | GenericHost (any) | DryIoc, Unity, etc. |
| Navigation | `CurrentViewModel` + Mappings.xaml | `IRegionManager` |
| Dialog | Manual implementation | `IDialogService` |
| Module | Not supported | `IModule` |
| Best for | Small-Medium apps | Medium-Large apps |

---

## Next Steps

1. **Add a screen (View + ViewModel)**: `/wpf-net472-airgap-dev-pack:make-wpf-viewmodel <Name> --with-view`
2. **Add a CustomControl**: `/wpf-net472-airgap-dev-pack:make-wpf-custom-control <Name>`
3. **Add a Converter**: `/wpf-net472-airgap-dev-pack:make-wpf-converter <Name>`
4. **Add a Service**: `/wpf-net472-airgap-dev-pack:make-wpf-service <Name>`

---

## Related knowledge topics (via WpfDevPackMcp)

Fetch with `WpfDevPackMcp get_wpf_topic`:

- `structuring-wpf-projects` — project / solution structure
- `configuring-dependency-injection` — DI setup
- `implementing-communitytoolkit-mvvm` — MVVM pattern
