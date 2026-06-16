# Hand-rolled MVVM (BindableBase + RelayCommand)

> Dependency-free MVVM for .NET Framework 4.7.2-4.8 (net472/net48): a hand-rolled `BindableBase` (INotifyPropertyChanged) plus `RelayCommand` / `RelayCommand<T>` (ICommand). Use when building ViewModels and commands without CommunityToolkit.Mvvm or any MVVM framework. This is the default MVVM style for wpf-net472-airgap-dev-pack.

The standard here is **dependency-free, hand-rolled MVVM** that compiles on
net472/net48 with **C# 7.3** and works in any project. **No CommunityToolkit.Mvvm**
(no `ObservableObject`, `[ObservableProperty]`, `[RelayCommand]`, source generators),
**no framework auto-detection** (no DevExpress/CTK/Prism sniffing). If a project has
no base classes, create them once under `Mvvm/` and reuse them. If a project already
has its own base class, preserve and use that instead.

## C# 7.3 constraints (net472/net48)

Write C# 7.3-safe code: block-scoped namespaces only; **no** nullable reference
types (`?` on reference types), records, init-only setters, target-typed `new`,
file-scoped namespaces, global usings, `or`/relational patterns, or `using`
declarations. Verify API availability with HandMirrorMcp when unsure.

## BindableBase

```csharp
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace MyApp.Mvvm
{
    public abstract class BindableBase : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual bool SetProperty<T>(ref T storage, T value,
            [CallerMemberName] string propertyName = null)
        {
            if (EqualityComparer<T>.Default.Equals(storage, value))
                return false;
            storage = value;
            RaisePropertyChanged(propertyName);
            return true;
        }

        protected void RaisePropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
```

## RelayCommand / RelayCommand<T>

`CanExecuteChanged` hooks `CommandManager.RequerySuggested`, so WPF re-evaluates
`CanExecute` automatically on UI interaction. `ICommand` and `CommandManager` live
in `PresentationCore.dll` on .NET Framework — that is the **one** allowed WPF
reference in a ViewModel (no other `System.Windows.*` UI types).

```csharp
using System;
using System.Windows.Input;

namespace MyApp.Mvvm
{
    public sealed class RelayCommand : ICommand
    {
        private readonly Action _execute;
        private readonly Func<bool> _canExecute;

        public RelayCommand(Action execute, Func<bool> canExecute = null)
        {
            _execute = execute ?? throw new ArgumentNullException(nameof(execute));
            _canExecute = canExecute;
        }

        public event EventHandler CanExecuteChanged
        {
            add { CommandManager.RequerySuggested += value; }
            remove { CommandManager.RequerySuggested -= value; }
        }

        public bool CanExecute(object parameter) => _canExecute == null || _canExecute();
        public void Execute(object parameter) => _execute();

        public void RaiseCanExecuteChanged() => CommandManager.InvalidateRequerySuggested();
    }

    public sealed class RelayCommand<T> : ICommand
    {
        private readonly Action<T> _execute;
        private readonly Predicate<T> _canExecute;

        public RelayCommand(Action<T> execute, Predicate<T> canExecute = null)
        {
            _execute = execute ?? throw new ArgumentNullException(nameof(execute));
            _canExecute = canExecute;
        }

        public event EventHandler CanExecuteChanged
        {
            add { CommandManager.RequerySuggested += value; }
            remove { CommandManager.RequerySuggested -= value; }
        }

        public bool CanExecute(object parameter) => _canExecute == null || _canExecute((T)parameter);
        public void Execute(object parameter) => _execute((T)parameter);

        public void RaiseCanExecuteChanged() => CommandManager.InvalidateRequerySuggested();
    }
}
```

## ViewModel usage

```csharp
using System.Windows.Input;
using MyApp.Mvvm;

namespace MyApp.ViewModels
{
    public sealed class CounterViewModel : BindableBase
    {
        private int _count;
        public int Count
        {
            get { return _count; }
            private set { SetProperty(ref _count, value); }
        }

        public ICommand IncrementCommand { get; }

        public CounterViewModel()
        {
            IncrementCommand = new RelayCommand(() => Count++, () => Count < 10);
        }
    }
}
```

## ViewModel layer rules

- ViewModel properties/parameters use BCL/domain types only — never WPF UI types
  (`Brush`, `Visibility`, `ImageSource`, `Thickness`, ...). Convert in the View
  layer with converters/triggers.
- Allowed WPF reference: `System.Windows.Input.ICommand` only.
- Prohibited: CommunityToolkit.Mvvm in any form.

## View ↔ ViewModel wiring

Pick one style per project (match what the project already uses):

- **Code-behind DataContext** — `DataContext = new XxxViewModel()` in the View
  constructor. Simplest, universal.
- **Implicit DataTemplate** (ViewModel-first) — a `DataTemplate` with `DataType`
  (no `x:Key`) renders the View for a ViewModel bound to `ContentControl.Content`.
- **DI-resolved** — assign a container-resolved ViewModel to `DataContext` if the
  project already uses a container.

> **Prism (opt-in only):** for projects already on Prism, use Prism's `BindableBase`
> + `DelegateCommand` + `RegisterForNavigation`. On net472/net48 use Prism 7.2/8.1
> (Prism 9 is .NET 8+ only). Never auto-introduce Prism.
