[🇺🇸 English](./TERMINOLOGY.md)

# wpf-net472-airgap-dev-pack — 용어 정의

본 문서는 wpf-net472-airgap-dev-pack이 채택하는 MVVM 방침과 관련 용어를
정의합니다. 본 문서가 plugin 전반에서 사용하는 모든 용어의 단일
출처(single source of truth)입니다.

본 fork는 **.NET Framework 4.7.2–4.8**(net472/net48)을 위한 오프라인
air-gapped fork입니다. upstream과 달리, "Composition Direction"
모델(View First vs ViewModel First)이나 단일 강제 wiring 경로를 강요하지
**않습니다**. 하나의 MVVM 스타일을 사용하며, View와 ViewModel을 연결하는
방식에 대해서는 실용적(pragmatic)으로 접근합니다.

---

## 1. 직접 구현(hand-rolled) MVVM

본 fork는 모든 생성 코드에 대해 단 하나의 MVVM 스타일을 사용합니다 —
외부 MVVM 패키지 없이 net472/net48(C# 7.3 안전)에서 컴파일되는
**의존성 없는 직접 구현(dependency-free hand-rolled) MVVM**입니다.

- ViewModel은 직접 구현한 **`BindableBase : INotifyPropertyChanged`**
  (`SetProperty` / `RaisePropertyChanged`)를 상속합니다.
- Command는 직접 구현한 **`RelayCommand` / `RelayCommand<T> : ICommand`**
  를 사용합니다.
- 프로젝트에 이러한 base class가 없으면 한 번만 생성하여(예: `Mvvm/` 아래)
  재사용합니다. 프로젝트에 이미 자체 base class가 있으면 그것을 보존하고
  사용합니다.
- **CommunityToolkit.Mvvm 미사용** — `ObservableObject`,
  `[ObservableProperty]`, `[RelayCommand]`, source generator를 사용하지
  않습니다. **프레임워크 자동 감지 없음**(DevExpress / CTK / Prism 탐지
  없음) — 항상 직접 구현 형태로 생성합니다.

전체 base class 정의 및 사용법:
[`mvvm-constraints.md`](../.claude/rules/mvvm-constraints.md).

---

## 2. View ↔ ViewModel Wiring (실용적 — 프로젝트에 맞춤)

Wiring은 단일 강제 경로가 **아닙니다**. 생성 코드가 기존 net472/net48 앱에
자연스럽게 맞도록, 다음을 모두 허용합니다. **프로젝트가 이미 사용하는
방식에 맞추되**, 일관성을 위해 프로젝트당 하나의 스타일을 권장합니다:

| Wiring 옵션 | 적합한 경우 |
|---|---|
| View 생성자에서 **code-behind** `DataContext = new XxxViewModel()` | 가장 단순하고 보편적인 패턴. 독립 Window, dialog, 소규모 앱 |
| **DataTemplate 매핑**(ViewModel-first): `DataType`만 지정하고 **`x:Key` 없는** implicit `DataTemplate`. `ContentControl.Content`에 바인딩된 ViewModel이 자신의 View로 렌더링됨 | 한 host가 여러 ViewModel을 전환하는 content/region 전환 |
| **DI로 resolve된** ViewModel을 `DataContext`에 할당 | 이미 container를 사용하는 앱 |

본 fork에서는 code-behind `DataContext` 할당이 명시적으로 **허용**됩니다.
프로젝트가 이미 동작 중인 기존 wiring을, 요청 없이 다른 스타일로 다시
작성하지 마십시오.

전체 예시:
[`view-viewmodel-wiring-handrolled.md`](../.claude/rules/view-viewmodel-wiring-handrolled.md).

---

## 3. ViewModel 순수성

- ViewModel은 `System.Windows.*` UI 타입(`Visibility`, `Brush`,
  `ImageSource`, `Thickness`, `Window`, `MessageBox`, …)을 참조하지
  않습니다.
- **허용 예외:** `System.Windows.Input.ICommand`(`RelayCommand`용).
- 바인딩 속성에는 BCL / 도메인 타입을 사용합니다: `string`, `int`, `bool`,
  `DateTime`, `ObservableCollection<T>`, 다른 ViewModel 등. UI 타입은 View
  계층(converter / trigger)에서 변환합니다.
- 컬렉션에는 `ObservableCollection<T>`를 사용하고, `CollectionView`는
  service 뒤에 두어 ViewModel이 WPF UI 타입으로부터 자유롭게 유지합니다.

상세: [`mvvm-constraints.md`](../.claude/rules/mvvm-constraints.md).

---

## 4. 금지 사항

몇 안 되는 핵심 "금지" 규칙(전체 목록은
[`prohibitions.md`](../.claude/rules/prohibitions.md) 참조):

| 금지 사항 | 규칙 |
|---|---|
| **CommunityToolkit.Mvvm 사용 금지**(base class, attribute, namespace, source generator 등 일체) | P-001 |
| **ViewModel에 `System.Windows.*` UI 타입 사용 금지**, 단 `System.Windows.Input.ICommand`는 예외 | P-002 |
| **프레임워크 자동 도입·자동 감지 금지**(CTK / Prism / DevExpress / Generic Host / DI를 미사용 프로젝트에 추가, 프레임워크 탐지 로직) | P-003 |
| **프레임워크 / 프로젝트 현대화 금지**(target framework 상향, .NET (Core)로 retarget, project 형식 변환, 패키지 관리 방식 마이그레이션, `LangVersion` 상향) — 명시적 요청 없는 한 | P-004 |
| **암묵적 네트워크 접근 금지**(오프라인 전용) | P-005 |

---

## 5. Prism — opt-in 대안

Prism은 이미 Prism에 의존하는 프로젝트를 위한 명시적 opt-in으로만 제공됩니다
— 기본값이 아니며, 자동 도입되지 않습니다.

- net472/net48에서 Prism은 **Prism 7.2 / 8.1**입니다(9가 아님).
- 메커니즘: `IContainerRegistry.RegisterForNavigation<View, ViewModel>()` +
  `IRegionManager.RequestNavigate("Region", "ViewName")`. Prism 자체의
  `BindableBase` / `DelegateCommand`를 사용합니다.
- 기존 Prism 프로젝트를 Prism으로 유지할 때만 사용하십시오. 직접 구현
  프로젝트를 요청 없이 Prism으로 전환하지 마십시오.

상세:
[`view-viewmodel-wiring-prism.md`](../.claude/rules/view-viewmodel-wiring-prism.md).

---

## 6. 참고 (rules)

| 주제 | 파일 |
|---|---|
| MVVM 제약 + 직접 구현 base class | [`mvvm-constraints.md`](../.claude/rules/mvvm-constraints.md) |
| 핵심 금지 사항 (P-001..P-005) | [`prohibitions.md`](../.claude/rules/prohibitions.md) |
| View ↔ ViewModel wiring (직접 구현, 기본) | [`view-viewmodel-wiring-handrolled.md`](../.claude/rules/view-viewmodel-wiring-handrolled.md) |
| View ↔ ViewModel wiring (Prism, opt-in) | [`view-viewmodel-wiring-prism.md`](../.claude/rules/view-viewmodel-wiring-prism.md) |
