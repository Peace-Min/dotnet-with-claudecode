# CollectionView MVVM - Prism Version (opt-in)

> **MVVM Framework Rule**: `.claude/rules/dotnet/wpf/prism9.md` 규칙이 적용됩니다.
> 이 포크의 기본값은 hand-rolled MVVM입니다 → [TOPIC.md](TOPIC.md) 참조

이 문서는 프로젝트가 **이미** Prism을 도입한 경우(opt-in)에만 적용됩니다.
이 포크의 기본 ViewModel Base는 hand-rolled `BindableBase` (`implementing-handrolled-mvvm`)입니다.

> ⚠️ Prism 9는 .NET 8+ 전용입니다. net472/net48에서는 **Prism 7.2 또는 8.1**을 사용하고
> C# 7.3 호환으로 작성합니다. Never auto-introduce Prism — opt-in only.

> [TOPIC.md](TOPIC.md)의 Service Layer 아키텍처, CollectionViewSource 캡슐화 패턴은 그대로 적용됩니다.
> 이 문서는 ViewModel이 Prism의 `BindableBase`를 상속할 때의 차이와 DI 등록만 다룹니다.

## Hand-rolled (기본) vs Prism (opt-in) 비교

| 항목 | Hand-rolled (default) | Prism (opt-in) |
|------|-----------------------|----------------|
| ViewModel Base | hand-rolled `BindableBase` | Prism `BindableBase` |
| 속성 정의 | `SetProperty()` 수동 | `SetProperty()` 수동 |
| DI 등록 | 생성자 직접 주입 또는 MS.DI | `containerRegistry.RegisterSingleton<I, T>()` |

## 1. ViewModel (Prism BindableBase)

```csharp
// 기본(hand-rolled) 버전은 TOPIC.md 참조.
// For the default hand-rolled version, see TOPIC.md.

// Prism 버전:
// Prism version:
using System.Collections;
using Prism.Mvvm;

namespace MyApp.ViewModels
{
    public class AppViewModel : BindableBase
    {
        public IEnumerable Members { get; private set; }

        public AppViewModel(IMemberCollectionService memberService)
        {
            Members = memberService.CreateView();
        }
    }

    // 필터 적용 ViewModel
    // Filtered ViewModel
    public class WalkerViewModel : BindableBase
    {
        public IEnumerable Members { get; private set; }

        public WalkerViewModel(IMemberCollectionService memberService)
        {
            Members = memberService.CreateView(
                item => (item as Member)?.Type == DeviceTypes.Walker);
        }
    }
}
```

## 2. DI 등록 (IContainerRegistry)

```csharp
protected override void RegisterTypes(IContainerRegistry containerRegistry)
{
    containerRegistry.RegisterSingleton<IMemberCollectionService, MemberCollectionService>();
    containerRegistry.Register<AppViewModel>();
    containerRegistry.Register<WalkerViewModel>();
}
```

## 3. Service Layer (변경 없음)

Service Layer의 `MemberCollectionService`는 WPF `CollectionViewSource`를 직접 사용하므로 MVVM 프레임워크와 무관합니다. [TOPIC.md](TOPIC.md)의 구현을 그대로 사용합니다.

## Key Differences from the hand-rolled default ([TOPIC.md](TOPIC.md))

- **Prism BindableBase**: hand-rolled `BindableBase` 대신 Prism의 `BindableBase` 상속 (둘 다 `SetProperty` 제공)
- **IContainerRegistry**: 생성자 직접 주입 대신 Prism DI API 사용
- **Service Layer 동일**: `CollectionViewSource` 캡슐화 패턴은 변경 없음
- **net472/net48**: Prism 7.2/8.1 사용, C# 7.3 호환 코드
