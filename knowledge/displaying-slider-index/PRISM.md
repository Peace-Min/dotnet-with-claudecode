# Slider Index Display - Prism 9 Version

> **MVVM Framework Rule**: `.claude/rules/dotnet/wpf/prism9.md` 규칙이 적용됩니다.
> 기본(hand-rolled) MVVM 사용 시 → [TOPIC.md](TOPIC.md) 참조
> Default (hand-rolled) MVVM → see [TOPIC.md](TOPIC.md)

Prism 9 (Community License) 기준 Slider 인덱스 패턴. TOPIC.md의 hand-rolled 버전에 대응하는 Prism 옵트인 버전.
Prism 9 (Community License) Slider index pattern. The opt-in Prism counterpart to the hand-rolled version in TOPIC.md.

> XAML 바인딩은 프레임워크 무관이므로 TOPIC.md와 동일합니다.
> XAML binding is framework-agnostic, identical to TOPIC.md.
> 이 문서는 ViewModel의 Prism `BindableBase` + `SetProperty` 패턴만 다룹니다.
> This document only covers Prism's `BindableBase` + `SetProperty` ViewModel pattern.

## Hand-Rolled (default) vs Prism 비교

> Hand-rolled 기본 MVVM도 같은 메서드 이름(`SetProperty`/`RaisePropertyChanged`)을 직접 구현해서 씁니다.
> The default hand-rolled MVVM uses the same method names (`SetProperty`/`RaisePropertyChanged`), implemented by hand instead of inherited from Prism.

| 항목 / Item | Hand-rolled (default) | Prism 9 (opt-in) |
|------|----------------------|---------|
| 기반 클래스 / Base class | 직접 구현한 `BindableBase` | `Prism.Mvvm.BindableBase` |
| 속성 정의 / Property | `SetProperty()` 수동 | `SetProperty()` 수동 |
| 연관 속성 알림 / Notify | `RaisePropertyChanged()` 수동 | `RaisePropertyChanged()` 수동 |

## ViewModel (Prism 9)

```csharp
// Hand-rolled 기본 버전은 TOPIC.md 참조 (직접 구현한 BindableBase).
// For the hand-rolled default version, see TOPIC.md (hand-written BindableBase).

// Prism 9 버전 (Prism.Mvvm.BindableBase 상속):
// Prism 9 version (inherits Prism.Mvvm.BindableBase):
public class ViewerViewModel : BindableBase
{
    // 내부 인덱스 (0-based)
    // Internal index (0-based)
    private int _currentSliceIndex;
    public int CurrentSliceIndex
    {
        get => _currentSliceIndex;
        set
        {
            if (SetProperty(ref _currentSliceIndex, value))
            {
                RaisePropertyChanged(nameof(SliceDisplayNumber));
            }
        }
    }

    // 총 개수
    // Total count
    private int _totalSliceCount;
    public int TotalSliceCount
    {
        get => _totalSliceCount;
        set
        {
            if (SetProperty(ref _totalSliceCount, value))
            {
                RaisePropertyChanged(nameof(MaxSliceIndex));
            }
        }
    }

    /// <summary>
    /// Slider Maximum (0-based index maximum)
    /// </summary>
    public int MaxSliceIndex => Math.Max(0, TotalSliceCount - 1);

    /// <summary>
    /// 사용자 표시 번호 (1-based)
    /// User display number (1-based)
    /// </summary>
    public int SliceDisplayNumber => CurrentSliceIndex + 1;
}
```

## XAML (TOPIC.md와 동일 / identical to TOPIC.md)

```xml
<TextBlock Text="{Binding SliceDisplayNumber}" />
<Slider Minimum="0"
        Maximum="{Binding MaxSliceIndex}"
        Value="{Binding CurrentSliceIndex}" />
<TextBlock Text="{Binding TotalSliceCount}" />
```

## Key Differences from the Hand-Rolled Version (TOPIC.md)

- **Base class**: Prism의 `Prism.Mvvm.BindableBase`를 상속 — TOPIC.md는 직접 구현한 `BindableBase`를 상속.
  Inherits Prism's `Prism.Mvvm.BindableBase` — TOPIC.md inherits a hand-written `BindableBase`.
- **SetProperty + RaisePropertyChanged**: 두 버전 모두 `SetProperty()` 성공 시 수동으로 `RaisePropertyChanged()`를 호출 — API 형태는 동일.
  Both versions manually call `RaisePropertyChanged()` when `SetProperty()` succeeds — the API shape is identical.
- **XAML 동일 / Same XAML**: 바인딩 패턴은 변경 없음. The binding pattern is unchanged.
