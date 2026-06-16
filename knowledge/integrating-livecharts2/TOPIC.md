# LiveCharts2 Integration Guide

> Integrates LiveCharts2 for data visualization in WPF with SkiaSharp rendering. Use when building charts, graphs, or dashboards with CartesianChart, PieChart, or real-time data updates.

LiveCharts2 (SkiaSharpView.WPF) 기반 데이터 시각화 가이드.

## NuGet Package

```xml
<!-- ⚠️ 프리릴리스: --version 명시 필수 -->
<!-- ⚠️ Prerelease: --version flag required -->
<PackageReference Include="LiveChartsCore.SkiaSharpView.WPF" Version="2.0.0-rc6.1" />
```

```bash
dotnet add package LiveChartsCore.SkiaSharpView.WPF --version 2.0.0-rc6.1
```

## 1. App Initialization

```csharp
// App.xaml.cs — OnStartup에서 한 번 호출
// App.xaml.cs — Call once in OnStartup
protected override void OnStartup(StartupEventArgs e)
{
    base.OnStartup(e);

    LiveCharts.Configure(config =>
        config
            .AddSkiaSharp()
            .AddDefaultMappers()
            .AddDefaultTheme());
}
```

## 2. CartesianChart (Line, Column, Bar)

### XAML

```xml
xmlns:lvc="clr-namespace:LiveChartsCore.SkiaSharpView.WPF;assembly=LiveChartsCore.SkiaSharpView.WPF"

<lvc:CartesianChart
    Series="{Binding Series}"
    XAxes="{Binding XAxes}"
    YAxes="{Binding YAxes}" />
```

### ViewModel

```csharp
using System.Collections.ObjectModel;
using MyApp.Mvvm; // BindableBase

public sealed class ChartViewModel : BindableBase
{
    // ✅ ObservableCollection 사용 (List 금지 — 동적 업데이트 불가)
    // ✅ Use ObservableCollection (not List — no dynamic updates)
    private ObservableCollection<ISeries> _series = new ObservableCollection<ISeries>
    {
        new LineSeries<double>
        {
            Values = new ObservableCollection<double> { 3, 5, 7, 2, 8 },
            Name = "매출"
        },
        new ColumnSeries<double>
        {
            Values = new ObservableCollection<double> { 2, 4, 1, 6, 3 },
            Name = "비용"
        }
    };
    public ObservableCollection<ISeries> Series
    {
        get { return _series; }
        set { SetProperty(ref _series, value); }
    }

    private Axis[] _xAxes =
    {
        new Axis { Name = "월", Labels = new[] { "1월", "2월", "3월", "4월", "5월" } }
    };
    public Axis[] XAxes
    {
        get { return _xAxes; }
        set { SetProperty(ref _xAxes, value); }
    }

    private Axis[] _yAxes =
    {
        new Axis { Name = "금액 (만원)" }
    };
    public Axis[] YAxes
    {
        get { return _yAxes; }
        set { SetProperty(ref _yAxes, value); }
    }
}
```

## 3. PieChart

```xml
<lvc:PieChart Series="{Binding PieSeries}" />
```

```csharp
private ObservableCollection<ISeries> _pieSeries = new ObservableCollection<ISeries>
{
    new PieSeries<double> { Values = new double[] { 45 }, Name = "A 제품" },
    new PieSeries<double> { Values = new double[] { 30 }, Name = "B 제품" },
    new PieSeries<double> { Values = new double[] { 25 }, Name = "C 제품" }
};
public ObservableCollection<ISeries> PieSeries
{
    get { return _pieSeries; }
    set { SetProperty(ref _pieSeries, value); }
}
```

## 4. Real-Time Data Update

```csharp
using System;
using System.Collections.ObjectModel;
using System.Windows.Input;
using MyApp.Mvvm; // BindableBase, RelayCommand

private readonly ObservableCollection<double> _values =
    new ObservableCollection<double> { 0, 0, 0, 0, 0 };
private readonly Random _random = new Random();

public ObservableCollection<ISeries> Series { get; } = new ObservableCollection<ISeries>();

public ICommand AddDataPointCommand { get; }

public ChartViewModel()
{
    Series.Add(new LineSeries<double> { Values = _values });
    AddDataPointCommand = new RelayCommand(AddDataPoint);
}

private void AddDataPoint()
{
    // ⚠️ UI 스레드에서 수정해야 함 (Dispatcher 사용)
    // ⚠️ Must modify on UI thread (use Dispatcher)
    _values.Add(_random.Next(0, 100));

    if (_values.Count > 50)
    {
        _values.RemoveAt(0);
    }
}
```

## 5. Common Mistakes

| 실수 | 올바른 방법 |
|------|------------|
| `List<ISeries>` 사용 | `ObservableCollection<ISeries>` 사용 필수 |
| Values에 `List<T>` | 동적 업데이트 시 `ObservableCollection<T>` |
| LiveCharts v1 API (`SeriesCollection`, `ChartValues<T>`) | v2 API (`ISeries`, `LineSeries<T>`) |
| 안정 버전으로 패키지 참조 | `2.0.0-rc6.1` 프리릴리스, `--version` 명시 |
| 고빈도 업데이트 시 직접 수정 | UI 스레드에서 수정 또는 `AutoUpdateEnabled` 제어 |

## 6. Namespace Reference

```csharp
// GlobalUsings.cs
global using LiveChartsCore;
global using LiveChartsCore.SkiaSharpView;
global using LiveChartsCore.SkiaSharpView.Painting;
global using SkiaSharp;
```

- `LiveChartsCore` — ISeries, Axis
- `LiveChartsCore.SkiaSharpView` — LineSeries, ColumnSeries, PieSeries
- `LiveChartsCore.SkiaSharpView.WPF` — CartesianChart, PieChart (XAML 컨트롤)

## Key Rules

- `ObservableCollection<ISeries>` 필수 (List 금지)
- Values도 동적 업데이트 시 `ObservableCollection<T>`
- App 초기화에서 `LiveCharts.Configure()` 한 번 호출
- 프리릴리스 버전: `--version 2.0.0-rc6.1` 명시
- ViewModel에서 WPF 참조 없이 사용 가능 (ISeries는 LiveChartsCore 네임스페이스)

## 참고

- [LiveCharts2 Docs](https://livecharts.dev/)
- [GitHub - beto-rodriguez/LiveCharts2](https://github.com/beto-rodriguez/LiveCharts2)
