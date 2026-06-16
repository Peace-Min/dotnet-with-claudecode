# Enum Command Parameter Binding - Prism Version (opt-in)

> **MVVM Framework Rule**: `.claude/rules/dotnet/wpf/prism9.md` 규칙이 적용됩니다.
> 이 포크의 기본값은 hand-rolled MVVM입니다 → [TOPIC.md](TOPIC.md) 참조

이 문서는 프로젝트가 **이미** Prism을 도입한 경우(opt-in)에만 적용됩니다.
이 포크의 기본 Command 타입은 hand-rolled `RelayCommand<T>` (`implementing-handrolled-mvvm`)입니다.

> ⚠️ Prism 9는 .NET 8+ 전용입니다. net472/net48에서는 **Prism 7.2 또는 8.1**을 사용하고
> C# 7.3 호환으로 작성합니다. Never auto-introduce Prism — opt-in only.

> XAML의 `x:Static` 마크업 확장은 프레임워크 무관이므로 [TOPIC.md](TOPIC.md)와 동일합니다.
> 이 문서는 ViewModel의 Command 부분만 다룹니다.

## Hand-rolled (기본) vs Prism (opt-in) 비교

| 항목 | Hand-rolled `RelayCommand<T>` (default) | Prism `DelegateCommand<T>` (opt-in) |
|------|------------------------------------------|--------------------------------------|
| Command 정의 | 생성자에서 `new RelayCommand<T>(...)` | `DelegateCommand<T>` 수동 작성 |
| 타입 제약 | Value type 직접 지원 (`(T)parameter` 캐스트) | class 제약 → Nullable wrapper 필요 (`T?`) |

## ViewModel (Prism)

> Prism의 `DelegateCommand<T>`는 `where T : class` 제약이 있어 값 타입 enum에는
> `ViewerTool?` (Nullable)을 사용해야 합니다. Hand-rolled `RelayCommand<T>`에는 이 제약이
> 없으므로 [TOPIC.md](TOPIC.md)에서는 `RelayCommand<ViewerTool>`을 그대로 사용합니다.

```csharp
using Prism.Commands;
using Prism.Mvvm;

public class ViewerViewModel : BindableBase
{
    private ViewerTool _currentTool = ViewerTool.Pan;
    public ViewerTool CurrentTool
    {
        get { return _currentTool; }
        set { SetProperty(ref _currentTool, value); }
    }

    // DelegateCommand<T>는 class 제약이 있으므로 Nullable enum 사용
    // DelegateCommand<T> has a class constraint, so use a Nullable enum
    private DelegateCommand<ViewerTool?> _selectToolCommand;
    public DelegateCommand<ViewerTool?> SelectToolCommand
    {
        get
        {
            return _selectToolCommand ?? (_selectToolCommand =
                new DelegateCommand<ViewerTool?>(ExecuteSelectTool));
        }
    }

    private void ExecuteSelectTool(ViewerTool? tool)
    {
        if (tool.HasValue)
            CurrentTool = tool.Value;
    }
}
```

## XAML (TOPIC.md와 동일)

```xml
<!-- x:Static은 프레임워크 무관 -->
<!-- x:Static is framework-independent -->
<ToggleButton Content="Pan"
              Command="{Binding SelectToolCommand}"
              CommandParameter="{x:Static viewmodels:ViewerTool.Pan}" />
```

## Key Differences from the hand-rolled default ([TOPIC.md](TOPIC.md))

- **DelegateCommand\<T?\>**: hand-rolled `RelayCommand<ViewerTool>` 대신 Prism `DelegateCommand<ViewerTool?>` 사용
- **Nullable 처리**: Prism의 `DelegateCommand<T>`는 참조 타입(`class`) 제약이 있으므로 값 타입은 `T?` 사용 (hand-rolled `RelayCommand<T>`에는 이 제약 없음)
- **XAML 동일**: `x:Static`, `EnumToBoolConverter` 등 XAML 부분은 변경 없음
- **net472/net48**: Prism 7.2/8.1 사용, C# 7.3 호환 코드
