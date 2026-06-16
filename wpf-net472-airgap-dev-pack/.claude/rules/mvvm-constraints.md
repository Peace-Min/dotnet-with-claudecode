# MVVM Constraints

MVVM layer-separation rules for net472/net48 projects. MVVM here is
**dependency-free and hand-rolled** — no CommunityToolkit.Mvvm, no source
generators, no framework auto-detection. ViewModels derive from a hand-rolled
`BindableBase`; commands are a hand-rolled `RelayCommand`. If a project lacks
these base classes, create them once (see below) and reuse them. If a project
already has its own base classes, preserve and use those instead.

---

## ViewModel layer purity

ViewModel code must not use WPF **UI** types. The following namespaces must
never appear in ViewModel code:

```csharp
// Prohibited in ViewModel code
using System.Windows;            // Visibility, Thickness, Window, MessageBox, ...
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Media;      // Brush, Color, ImageSource, ...
```

**Allowed exception — `System.Windows.Input.ICommand`.** On .NET Framework,
`ICommand` (and `CommandManager`, used by `RelayCommand`) live in
`PresentationCore.dll`. A ViewModel project may therefore reference
`PresentationCore` **solely** for `ICommand` / `RelayCommand` — never for any
other WPF UI type. (If you want a ViewModel project with zero WPF references,
use the manual-event command variant in the note at the end.)

Safe namespaces for ViewModels:

```csharp
// Allowed
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;            // INotifyPropertyChanged
using System.Windows.Input;             // ICommand only (RelayCommand)
// + the project's own Mvvm/base-class namespace
```

---

## ViewModel type restrictions

ViewModel properties and constructor parameters use BCL / domain types only:

- `string`, `int`, `double`, `bool`, `decimal`, `DateTime`, `Guid`
- `ObservableCollection<T>`, `List<T>`, `IEnumerable<T>`
- Other ViewModels or domain model types

Do NOT expose WPF UI types (`Brush`, `Visibility`, `ImageSource`, `Thickness`,
etc.) as ViewModel properties. Convert in the View layer (converters/triggers).

---

## Hand-rolled MVVM base classes (the standard)

Generate these once per project (e.g. under `Mvvm/`) if absent, then reuse.
Both compile on **net472/net48 with C# 7.3** (no nullable reference types,
records, init-only, target-typed `new`, file-scoped namespaces, etc.).

### `BindableBase` (INotifyPropertyChanged)

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

### `RelayCommand` / `RelayCommand<T>` (ICommand, CommandManager auto-requery)

`CanExecuteChanged` hooks `CommandManager.RequerySuggested`, so WPF
re-evaluates `CanExecute` automatically on UI interaction — the ViewModel does
not need to raise it manually for the common case.

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

        // Call to force a re-query immediately (e.g. after a non-UI state change).
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

### ViewModel usage

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

---

## Prohibited

- **CommunityToolkit.Mvvm** in any form: `ObservableObject` / `ObservableRecipient`
  base classes, `[ObservableProperty]`, `[RelayCommand]`, `[NotifyCanExecuteChangedFor]`,
  the `CommunityToolkit.Mvvm.*` namespaces, and the source generators.
- **Framework auto-detection** (DevExpress / CTK / Prism sniffing). Always emit
  the hand-rolled form; only follow a project's existing base classes when it
  already has them.
- Hand-rolling something *other* than `BindableBase` / `RelayCommand` when those
  already exist in the project — reuse them.

> **Zero-WPF-reference variant:** if a ViewModel project must not reference
> `PresentationCore` at all, replace the `CommandManager`-based event with a
> manual one (`public event EventHandler CanExecuteChanged;` and
> `RaiseCanExecuteChanged() => CanExecuteChanged?.Invoke(this, EventArgs.Empty);`),
> and call `RaiseCanExecuteChanged()` from the ViewModel whenever `CanExecute`
> may have changed. `ICommand` itself still resides in `PresentationCore`.
