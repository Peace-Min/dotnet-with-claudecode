# View–ViewModel Wiring — Prism 9 (opt-in alternative)

> **Opt-in only.** The default MVVM for this fork is dependency-free hand-rolled
> `BindableBase`/`RelayCommand` (`rules/view-viewmodel-wiring-handrolled.md`).
> Use Prism **only** for projects that already depend on Prism 9 and that the
> user is keeping on Prism. Never auto-introduce Prism, and never convert a
> hand-rolled project to Prism without being asked.

Mechanism: View-first composition via `IContainerRegistry.RegisterForNavigation<View, VM>()`
+ `IRegionManager.RequestNavigate("Region", "ViewName")`. Prism's `BindableBase`
and `DelegateCommand` are used instead of the hand-rolled ones in a Prism project.
Keep ViewModels free of `System.Windows.*` UI types (except `ICommand`).

---

## Registration in App.xaml.cs

```csharp
protected override void RegisterTypes(IContainerRegistry containerRegistry)
{
    containerRegistry.RegisterForNavigation<HomeView, HomeViewModel>();
    containerRegistry.RegisterForNavigation<SettingsView, SettingsViewModel>();
}
```

## Shell — Region Definition

```xml
<Window x:Class="MyApp.MainWindow"
        xmlns:prism="http://prismlibrary.com/">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="10">
            <Button Content="Home" Command="{Binding NavigateCommand}"
                    CommandParameter="HomeView" Margin="5" />
            <Button Content="Settings" Command="{Binding NavigateCommand}"
                    CommandParameter="SettingsView" Margin="5" />
        </StackPanel>

        <!-- Region instead of ContentControl + DataTemplate -->
        <ContentControl Grid.Row="1"
                        prism:RegionManager.RegionName="ContentRegion" />
    </Grid>
</Window>
```

## Shell ViewModel — Navigation

```csharp
namespace MyApp.ViewModels;

public class MainWindowViewModel : BindableBase
{
    private readonly IRegionManager _regionManager;

    public MainWindowViewModel(IRegionManager regionManager)
    {
        _regionManager = regionManager;
    }

    private DelegateCommand<string>? _navigateCommand;
    public DelegateCommand<string> NavigateCommand =>
        _navigateCommand ??= new DelegateCommand<string>(ExecuteNavigate);

    private void ExecuteNavigate(string viewName)
    {
        _regionManager.RequestNavigate("ContentRegion", viewName);
    }
}
```

## NavigationParameters

```csharp
private void NavigateToDetail(int userId)
{
    var parameters = new NavigationParameters
    {
        { "userId", userId },
        { "mode", "edit" }
    };

    _regionManager.RequestNavigate("ContentRegion", "DetailView", parameters);
}
```

## INavigationAware — Lifecycle Callbacks

```csharp
namespace MyApp.ViewModels;

public class HomeViewModel : BindableBase, INavigationAware
{
    // Called when navigated to this View
    public void OnNavigatedTo(NavigationContext navigationContext)
    {
        if (navigationContext.Parameters.ContainsKey("userId"))
        {
            var userId = navigationContext.Parameters.GetValue<int>("userId");
            LoadUser(userId);
        }
    }

    // Whether to reuse existing instance
    public bool IsNavigationTarget(NavigationContext navigationContext)
    {
        return true;
    }

    // Called when navigating away
    public void OnNavigatedFrom(NavigationContext navigationContext)
    {
        // Cleanup logic
    }
}
```

## IConfirmNavigationRequest — Cancel Navigation

```csharp
public class EditViewModel : BindableBase, IConfirmNavigationRequest
{
    public void ConfirmNavigationRequest(
        NavigationContext navigationContext,
        Action<bool> continuationCallback)
    {
        if (HasUnsavedChanges)
        {
            var result = MessageBox.Show(
                "You have unsaved changes. Navigate away?",
                "Confirm", MessageBoxButton.YesNo);
            continuationCallback(result == MessageBoxResult.Yes);
        }
        else
        {
            continuationCallback(true);
        }
    }

    public void OnNavigatedTo(NavigationContext ctx) { }
    public bool IsNavigationTarget(NavigationContext ctx) => true;
    public void OnNavigatedFrom(NavigationContext ctx) { }
}
```

## Comparison with the default hand-rolled MVVM

| Item | Hand-rolled (default) | Prism 9 (opt-in) |
|---|---|---|
| Base class | hand-rolled `BindableBase` | Prism `BindableBase` |
| Command | hand-rolled `RelayCommand` | Prism `DelegateCommand` |
| View-VM mapping | code-behind `DataContext` or implicit `DataTemplate` | `RegisterForNavigation<V, VM>()` |
| Navigation | swap a bound `Current` property | `IRegionManager.RequestNavigate()` |
| Parameters | manual property assignment | `NavigationParameters` (type-safe) |
| Lifecycle | none | `INavigationAware`, `IConfirmNavigationRequest` |
| Hosting control | `ContentControl` + Binding | `ContentControl` + `RegionManager.RegionName` |
| Dependency | none | Prism 9 NuGet packages |
