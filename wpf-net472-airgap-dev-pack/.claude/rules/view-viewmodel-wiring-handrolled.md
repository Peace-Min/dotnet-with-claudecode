# View–ViewModel Wiring — hand-rolled MVVM (default)

Applies to the default dependency-free MVVM (`BindableBase` / `RelayCommand`,
`rules/mvvm-constraints.md`). No CommunityToolkit, no framework.

Pick **one** wiring style per project and stay consistent. Match what the
project already uses; do not rewrite working wiring without being asked.

---

## Option A — Code-behind DataContext (simplest, most universal)

Best for standalone windows, dialogs, and small apps. Works on any net472 app
with zero infrastructure.

```csharp
namespace MyApp.Views
{
    public partial class CounterView : System.Windows.Controls.UserControl
    {
        public CounterView()
        {
            InitializeComponent();
            DataContext = new MyApp.ViewModels.CounterViewModel();
        }
    }
}
```

When the ViewModel needs services, construct/resolve it and assign:

```csharp
public MainWindow(IMyService service)
{
    InitializeComponent();
    DataContext = new MainWindowViewModel(service);
}
```

Design-time support in the View XAML:

```xml
<UserControl ...
             xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
             xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
             xmlns:vm="clr-namespace:MyApp.ViewModels"
             mc:Ignorable="d"
             d:DataContext="{d:DesignInstance Type=vm:CounterViewModel}">
    <TextBlock Text="{Binding Count}" />
</UserControl>
```

---

## Option B — DataTemplate mapping (ViewModel-first)

Best for content/region switching where one host swaps between ViewModels and
WPF picks the matching View automatically. Use an implicit `DataTemplate`
(`DataType`, **no `x:Key`**).

`App.xaml` (or a merged dictionary) maps ViewModel types to Views:

```xml
<Application x:Class="MyApp.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:vm="clr-namespace:MyApp.ViewModels"
             xmlns:views="clr-namespace:MyApp.Views"
             StartupUri="MainWindow.xaml">
    <Application.Resources>
        <DataTemplate DataType="{x:Type vm:HomeViewModel}">
            <views:HomeView />
        </DataTemplate>
        <DataTemplate DataType="{x:Type vm:SettingsViewModel}">
            <views:SettingsView />
        </DataTemplate>
    </Application.Resources>
</Application>
```

A shell ViewModel exposes the current child VM; the host binds to it:

```csharp
public sealed class ShellViewModel : BindableBase
{
    private object _current;
    public object Current
    {
        get { return _current; }
        private set { SetProperty(ref _current, value); }
    }

    public ICommand ShowHomeCommand { get; }
    public ICommand ShowSettingsCommand { get; }

    public ShellViewModel()
    {
        Current = new HomeViewModel();
        ShowHomeCommand = new RelayCommand(() => Current = new HomeViewModel());
        ShowSettingsCommand = new RelayCommand(() => Current = new SettingsViewModel());
    }
}
```

```xml
<!-- MainWindow.xaml -->
<DockPanel>
    <StackPanel DockPanel.Dock="Top" Orientation="Horizontal">
        <Button Content="Home"     Command="{Binding ShowHomeCommand}" />
        <Button Content="Settings" Command="{Binding ShowSettingsCommand}" />
    </StackPanel>
    <!-- The DataTemplate above renders the matching View for Current -->
    <ContentControl Content="{Binding Current}" />
</DockPanel>
```

```csharp
public MainWindow()
{
    InitializeComponent();
    DataContext = new ShellViewModel();
}
```

For recursive data (trees), use `HierarchicalDataTemplate` with `ItemsSource`.

---

## Notes

- ViewModels are plain classes deriving from `BindableBase`; they expose
  bindable properties via `SetProperty` and commands as `ICommand` (RelayCommand).
- No `ViewModelLocator` and no naming-convention auto-wiring is required — but
  none is prohibited either if a project already uses one. Keep it consistent.
- For projects already built on **Prism**, use
  `rules/view-viewmodel-wiring-prism.md` instead (opt-in, never auto-introduced).
