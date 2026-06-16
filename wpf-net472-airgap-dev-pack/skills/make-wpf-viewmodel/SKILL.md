---
description: "Generates a WPF ViewModel (and optional View) using dependency-free hand-rolled MVVM (BindableBase + RelayCommand) for .NET Framework 4.7.2-4.8. Use when creating a new screen, adding a View-ViewModel pair, or scaffolding ViewModel boilerplate. Usage: /wpf-net472-airgap-dev-pack:make-wpf-viewmodel <ViewModelName> [--with-view] [--datatemplate]"
argument-hint: [ViewModelName]
---

# WPF ViewModel Generator (net472, hand-rolled MVVM)

**If `$0` is empty, use the AskUserQuestion tool to ask: "Enter the ViewModel name (e.g., Dashboard, Settings)". Do NOT proceed until a valid name is provided.**

Generate a `$0ViewModel` deriving from a hand-rolled `BindableBase`, with commands
as hand-rolled `RelayCommand`. **No CommunityToolkit, no source generators, no
framework detection.** Output must compile on **net472/net48 (C# 7.3)** — block-scoped
namespaces only; no nullable reference types, records, init-only, target-typed `new`,
or file-scoped namespaces. See `rules/mvvm-constraints.md`.

- Replace `{Namespace}` with the project's root namespace (detect from csproj / existing code).
- If the project already uses its own base class (e.g. a Prism `BindableBase`), **follow that** instead of creating new ones.

## Usage

```bash
# ViewModel only
/wpf-net472-airgap-dev-pack:make-wpf-viewmodel Settings

# ViewModel + View, wired via code-behind DataContext (simplest, universal)
/wpf-net472-airgap-dev-pack:make-wpf-viewmodel Dashboard --with-view

# ViewModel + View, wired via implicit DataTemplate (ViewModel-first content switching)
/wpf-net472-airgap-dev-pack:make-wpf-viewmodel Report --with-view --datatemplate
```

---

## Execution Procedure

### Step 1: Parse `$0` and flags

- `$0` = ViewModel name without the `ViewModel` suffix (auto-appended): `Dashboard` → `DashboardViewModel`.
- `--with-view` → also generate `$0View.xaml` + code-behind.
- `--datatemplate` → wire the View via an implicit `DataTemplate` instead of code-behind `DataContext` (only meaningful with `--with-view`).

### Step 2: Inspect the solution (preserve conventions)

- Detect the root namespace and the target framework (must stay `net472`/`net48`).
- Detect the project's **effective `LangVersion`**; default to C# 7.3-safe output.
- Detect an existing MVVM base class:
  - If `BindableBase`/`RelayCommand` (or `DelegateCommand`) already exist in the project, **reuse them** — do not create duplicates.
  - If the project is on Prism, follow `PRISM.md` instead.
- Place the ViewModel in a `.ViewModels` project if present, else a `ViewModels/` folder.

### Step 3: Ensure the hand-rolled base classes (create once if absent)

If the project has no `BindableBase`/`RelayCommand`, create them under `Mvvm/`
(verbatim from `rules/mvvm-constraints.md`): `Mvvm/BindableBase.cs` and
`Mvvm/RelayCommand.cs` (`RelayCommand` + `RelayCommand<T>`, CommandManager
auto-requery). These compile on net472/C# 7.3.

### Step 4: Generate the ViewModel

Create `$0ViewModel.cs` (block-scoped namespace, C# 7.3-safe):

```csharp
using System.Windows.Input;
using {Namespace}.Mvvm;

namespace {Namespace}.ViewModels
{
    public sealed class $0ViewModel : BindableBase
    {
        private string _title = "$0";
        public string Title
        {
            get { return _title; }
            set { SetProperty(ref _title, value); }
        }

        public ICommand LoadedCommand { get; }

        public $0ViewModel()
        {
            LoadedCommand = new RelayCommand(OnLoaded);
        }

        private void OnLoaded()
        {
            // TODO: initialize data
        }
    }
}
```

### Step 5: Generate the View (if `--with-view`)

`Views/$0View.xaml`:

```xml
<UserControl x:Class="{Namespace}.Views.$0View"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
             xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
             xmlns:vm="clr-namespace:{Namespace}.ViewModels"
             mc:Ignorable="d"
             d:DataContext="{d:DesignInstance Type=vm:$0ViewModel}"
             d:DesignHeight="450" d:DesignWidth="800">
    <Grid>
        <TextBlock Text="{Binding Title}" HorizontalAlignment="Center"
                   VerticalAlignment="Center" FontSize="24" />
    </Grid>
</UserControl>
```

### Step 6: Wire the View ↔ ViewModel

**Default (no `--datatemplate`) — code-behind DataContext** (simplest, works anywhere):

`Views/$0View.xaml.cs`:

```csharp
using {Namespace}.ViewModels;

namespace {Namespace}.Views
{
    public partial class $0View : System.Windows.Controls.UserControl
    {
        public $0View()
        {
            InitializeComponent();
            DataContext = new $0ViewModel();
        }
    }
}
```

**With `--datatemplate` — implicit DataTemplate** (ViewModel-first; host swaps a bound
`ContentControl.Content`). Leave the code-behind without a `DataContext` assignment and
add to `App.xaml` (or a merged dictionary):

```xml
<DataTemplate DataType="{x:Type vm:$0ViewModel}">
    <views:$0View />
</DataTemplate>
```

(Declare `xmlns:vm="clr-namespace:{Namespace}.ViewModels"` and
`xmlns:views="clr-namespace:{Namespace}.Views"` on the resources owner.)

See `rules/view-viewmodel-wiring-handrolled.md` for both wiring styles. If the project
already uses a DI container, resolve the ViewModel from it and assign to `DataContext`
instead of `new`.

### Step 7: Report

List generated/modified files (including any newly created `Mvvm/` base classes) and next steps.

---

## Error Handling

- Missing ViewModel name → ask via AskUserQuestion.
- No WPF project found → suggest `/wpf-net472-airgap-dev-pack:make-wpf-project` first.
- Duplicate ViewModel → warn and abort.
- Project already has a base class → reuse it; do not create `Mvvm/` duplicates.

> **Prism 9 projects (opt-in only):** see [PRISM.md](PRISM.md). Never convert a hand-rolled project to Prism without being asked.
