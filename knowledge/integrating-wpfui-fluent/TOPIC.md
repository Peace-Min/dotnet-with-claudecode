# WPF-UI (Wpf.Ui) Integration Guide

> Integrates WPF-UI (Wpf.Ui) library for Fluent Design in WPF applications. Use when building modern UI with FluentWindow, NavigationView, SnackbarService, or theme management.

Wpf.Ui 4.x 기반 Fluent Design WPF 앱 구현 가이드.

## NuGet Package

```xml
<PackageReference Include="WPF-UI" Version="4.2.*" />
```

## 1. FluentWindow Setup

### App.xaml

```xml
<Application x:Class="MyApp.App"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Application.Resources>
        <ResourceDictionary>
            <ResourceDictionary.MergedDictionaries>
                <ResourceDictionary Source="pack://application:,,,/Wpf.Ui;component/Styles/Controls.xaml" />
            </ResourceDictionary.MergedDictionaries>
        </ResourceDictionary>
    </Application.Resources>
</Application>
```

### MainWindow.xaml

```xml
<ui:FluentWindow x:Class="MyApp.MainWindow"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:ui="http://schemas.lepo.co/wpfui/2022/xaml"
    Title="MyApp" Height="600" Width="800"
    ExtendsContentIntoTitleBar="True"
    WindowBackdropType="Mica">

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <ui:TitleBar Grid.Row="0" Title="MyApp" />

        <ui:NavigationView Grid.Row="1"
            x:Name="RootNavigation"
            PaneDisplayMode="Left"
            IsBackButtonVisible="Collapsed">

            <ui:NavigationView.MenuItems>
                <ui:NavigationViewItem Content="Home"
                    TargetPageType="{x:Type local:HomePage}"
                    Icon="{ui:SymbolIcon Home24}" />
                <ui:NavigationViewItem Content="Settings"
                    TargetPageType="{x:Type local:SettingsPage}"
                    Icon="{ui:SymbolIcon Settings24}" />
            </ui:NavigationView.MenuItems>

        </ui:NavigationView>
    </Grid>
</ui:FluentWindow>
```

### MainWindow.xaml.cs

```csharp
namespace MyApp;

public partial class MainWindow : FluentWindow
{
    public MainWindow(
        MainWindowViewModel viewModel,
        INavigationService navigationService,
        ISnackbarService snackbarService,
        IContentDialogService contentDialogService)
    {
        DataContext = viewModel;
        InitializeComponent();

        navigationService.SetNavigationControl(RootNavigation);
        snackbarService.SetSnackbarPresenter(RootSnackbar);
        contentDialogService.SetDialogHost(RootContentDialog);
    }
}
```

## 2. DI Registration (GenericHost)

```csharp
namespace MyApp;

public partial class App : Application
{
    private static readonly IHost _host = Host.CreateDefaultBuilder()
        .ConfigureServices((_, services) =>
        {
            // Wpf.Ui Services
            services.AddSingleton<INavigationService, NavigationService>();
            services.AddSingleton<ISnackbarService, SnackbarService>();
            services.AddSingleton<IContentDialogService, ContentDialogService>();
            services.AddSingleton<IThemeService, ThemeService>();

            // Windows
            services.AddSingleton<MainWindow>();
            services.AddSingleton<MainWindowViewModel>();

            // Pages (Transient for navigation)
            services.AddTransient<HomePage>();
            services.AddTransient<HomeViewModel>();
            services.AddTransient<SettingsPage>();
            services.AddTransient<SettingsViewModel>();
        })
        .Build();

    protected override async void OnStartup(StartupEventArgs e)
    {
        await _host.StartAsync();

        var mainWindow = _host.Services.GetRequiredService<MainWindow>();
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

## 3. Navigation Service

```csharp
// Page는 ui:INavigableView<TViewModel>을 구현
// Page implements ui:INavigableView<TViewModel>
public partial class HomePage : Page, INavigableView<HomeViewModel>
{
    public HomeViewModel ViewModel { get; }

    public HomePage(HomeViewModel viewModel)
    {
        ViewModel = viewModel;
        DataContext = viewModel;
        InitializeComponent();
    }
}
```

### 프로그래밍 방식 네비게이션

```csharp
// ViewModel에서 INavigationService 주입
// Inject INavigationService in ViewModel
// 명령은 생성자에서 만든다: NavigateToSettingsCommand = new RelayCommand(NavigateToSettings);
// Build the command in the constructor: NavigateToSettingsCommand = new RelayCommand(NavigateToSettings);
public ICommand NavigateToSettingsCommand { get; }

private void NavigateToSettings()
{
    _navigationService.Navigate(typeof(SettingsPage));
}
```

## 4. Snackbar

```csharp
// ViewModel에서 사용
// Use in ViewModel
_snackbarService.Show(
    "성공",          // Title
    "저장되었습니다.", // Message
    ControlAppearance.Success,
    new SymbolIcon(SymbolRegular.Checkmark24),
    TimeSpan.FromSeconds(3));
```

### XAML (MainWindow에 Presenter 배치)

```xml
<ui:SnackbarPresenter x:Name="RootSnackbar" Grid.Row="2" />
```

## 5. ContentDialog

```csharp
// ViewModel에서 사용
// Use in ViewModel
var result = await _contentDialogService.ShowSimpleDialogAsync(
    new SimpleContentDialogCreateOptions
    {
        Title = "삭제 확인",
        Content = "정말 삭제하시겠습니까?",
        PrimaryButtonText = "삭제",
        CloseButtonText = "취소"
    });

if (result == ContentDialogResult.Primary)
{
    // 삭제 처리
    // Handle deletion
}
```

### XAML (MainWindow에 Host 배치)

```xml
<ui:ContentDialogService x:Name="RootContentDialog" Grid.Row="1" />
```

## 6. Theme Management

```csharp
// 테마 전환
// Switch theme
ApplicationThemeManager.Apply(ApplicationTheme.Dark);
ApplicationThemeManager.Apply(ApplicationTheme.Light);

// 시스템 테마 감지 + 자동 적용
// Detect system theme + auto-apply
ApplicationThemeManager.ApplySystemTheme();
```

## 7. Hand-Rolled MVVM 통합

WPF-UI는 ViewModel의 MVVM 구현 방식과 무관하게 동작합니다. 이 fork는
CommunityToolkit.Mvvm을 사용하지 **않고**, 의존성 없는 hand-rolled
`BindableBase` / `RelayCommand`로 통합합니다.
WPF-UI works regardless of how the ViewModel implements MVVM. This fork does
**not** use CommunityToolkit.Mvvm; it integrates with the dependency-free
hand-rolled `BindableBase` / `RelayCommand`.

```csharp
using System;
using System.Windows.Input;
using MyApp.Mvvm; // BindableBase, RelayCommand

public sealed class HomeViewModel : BindableBase
{
    private readonly ISnackbarService _snackbarService;

    public HomeViewModel(ISnackbarService snackbarService)
    {
        _snackbarService = snackbarService;
        SearchCommand = new RelayCommand(Search);
    }

    private string _searchText = string.Empty;
    public string SearchText
    {
        get { return _searchText; }
        set { SetProperty(ref _searchText, value); }
    }

    public ICommand SearchCommand { get; }

    private void Search()
    {
        _snackbarService.Show("검색", "'" + SearchText + "' 검색 중...",
            ControlAppearance.Info, null, TimeSpan.FromSeconds(2));
    }
}
```

## Key Rules

- `FluentWindow` 상속 (일반 `Window` 대신)
- `ExtendsContentIntoTitleBar="True"` + `ui:TitleBar` 조합
- Services는 GenericHost에서 Singleton 등록
- Pages는 Transient 등록 (NavigationView가 관리)
- Page는 `INavigableView<TViewModel>` 구현
- `INavigationService.SetNavigationControl()`은 MainWindow 생성자에서 호출

## 참고

- [WPF UI Documentation](https://wpfui.lepo.co/)
- [GitHub - lepoco/wpfui](https://github.com/lepoco/wpfui)
