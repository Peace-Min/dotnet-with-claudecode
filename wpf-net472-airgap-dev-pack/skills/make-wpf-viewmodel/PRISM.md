# WPF ViewModel Generator — Prism (opt-in, net472)

> **Opt-in only.** Use this ONLY for projects that already depend on Prism. The
> default is dependency-free hand-rolled MVVM — see [SKILL.md](SKILL.md). Never
> auto-introduce Prism or convert a hand-rolled project to it.

> **net472/net48 uses Prism 7.2 or 8.1**, not Prism 9 (Prism 9 targets .NET 8+
> and does NOT support .NET Framework). The ViewModel/command/navigation API used
> here is the same across Prism 7/8. Match the version the project already references.

## Differences from the default hand-rolled MVVM

| Item | Hand-rolled (default) | Prism (opt-in) |
|------|----------------------|----------------|
| Base class | hand-rolled `BindableBase` | Prism `Prism.Mvvm.BindableBase` |
| Property | `SetProperty()` (hand-rolled) | `SetProperty()` (Prism) |
| Command | hand-rolled `RelayCommand` | `DelegateCommand` |
| DI registration | optional / `new` | `IContainerRegistry` |
| View mapping | code-behind `DataContext` or `DataTemplate` | `RegisterForNavigation` |

---

## Generated ViewModel (C# 7.3-safe — block-scoped namespace, no `?`/`??=`)

```csharp
using Prism.Commands;
using Prism.Mvvm;

namespace {Namespace}.ViewModels
{
    public sealed class {Name}ViewModel : BindableBase
    {
        private string _title = "{Name}";
        public string Title
        {
            get { return _title; }
            set { SetProperty(ref _title, value); }
        }

        private DelegateCommand _loadedCommand;
        public DelegateCommand LoadedCommand
        {
            get { return _loadedCommand ?? (_loadedCommand = new DelegateCommand(ExecuteLoaded)); }
        }

        private void ExecuteLoaded()
        {
            // TODO: initialize data
        }
    }
}
```

## DI registration

In `App.xaml.cs` `RegisterTypes`:

```csharp
protected override void RegisterTypes(IContainerRegistry containerRegistry)
{
    containerRegistry.RegisterForNavigation<{Name}View, {Name}ViewModel>();
}
```

## Navigation

```csharp
_regionManager.RequestNavigate("ContentRegion", nameof({Name}View));
```

```xml
<ContentControl prism:RegionManager.RegionName="ContentRegion" />
```

> The `--datatemplate` flag is ignored in Prism mode — navigation replaces DataTemplate mapping.
