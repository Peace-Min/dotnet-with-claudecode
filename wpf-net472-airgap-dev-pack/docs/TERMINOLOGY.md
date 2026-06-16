[🇰🇷 한국어](./TERMINOLOGY.ko.md)

# wpf-net472-airgap-dev-pack — Terminology

This document defines the MVVM stance adopted by wpf-net472-airgap-dev-pack.
It is the single source of truth for the terminology used throughout the
plugin.

This fork is an offline, air-gapped fork for **.NET Framework 4.7.2–4.8**
(net472/net48). Unlike upstream, it does **not** enforce an opinionated
"Composition Direction" model (View First vs ViewModel First) or a single
mandated wiring path. It uses one MVVM style and stays pragmatic about how a
View is connected to its ViewModel.

---

## 1. Hand-rolled MVVM

The fork uses ONE MVVM style for all generated code: **dependency-free,
hand-rolled MVVM** that compiles on net472/net48 (C# 7.3-safe) with no external
MVVM package.

- ViewModels derive from a hand-rolled **`BindableBase : INotifyPropertyChanged`**
  (`SetProperty` / `RaisePropertyChanged`).
- Commands are hand-rolled **`RelayCommand` / `RelayCommand<T> : ICommand`**.
- If a project lacks these base classes, create them once (e.g. under `Mvvm/`)
  and reuse them. If a project already has its own base classes, preserve and
  use those instead.
- **No CommunityToolkit.Mvvm** — no `ObservableObject`, `[ObservableProperty]`,
  `[RelayCommand]`, or source generators. **No framework auto-detection** (no
  DevExpress / CTK / Prism sniffing) — always emit the hand-rolled form.

Full base-class definitions and usage: [`mvvm-constraints.md`](../.claude/rules/mvvm-constraints.md).

---

## 2. View ↔ ViewModel Wiring (pragmatic — match the project)

Wiring is **not** a single enforced path. So generated code fits any existing
net472/net48 app, all of the following are allowed. **Match what the project
already uses**, and prefer one style per project for consistency:

| Wiring option | When it fits |
|---|---|
| **Code-behind** `DataContext = new XxxViewModel()` in the View constructor | The simplest, most universal pattern; standalone windows, dialogs, small apps |
| **DataTemplate mapping** (ViewModel-first): an implicit `DataTemplate` with `DataType` and **no `x:Key`**, so a ViewModel bound to `ContentControl.Content` renders its View | Content/region switching where one host swaps between ViewModels |
| **DI-resolved** ViewModel assigned to `DataContext` | Apps that already use a container |

Code-behind `DataContext` assignment is explicitly **allowed** in this fork.
Do not rewrite a project's existing, working wiring to a different style
without being asked.

Full examples: [`view-viewmodel-wiring-handrolled.md`](../.claude/rules/view-viewmodel-wiring-handrolled.md).

---

## 3. ViewModel Purity

- ViewModels must not reference `System.Windows.*` UI types (`Visibility`,
  `Brush`, `ImageSource`, `Thickness`, `Window`, `MessageBox`, …).
- **Allowed exception:** `System.Windows.Input.ICommand` (for `RelayCommand`).
- Use BCL / domain types for bindable properties: `string`, `int`, `bool`,
  `DateTime`, `ObservableCollection<T>`, other ViewModels, etc. Convert UI
  types in the View layer (converters / triggers).
- For collections, use `ObservableCollection<T>`; keep any `CollectionView`
  behind a service so the ViewModel stays free of WPF UI types.

Details: [`mvvm-constraints.md`](../.claude/rules/mvvm-constraints.md).

---

## 4. Prohibitions

The few hard "do not" rules (full list in
[`prohibitions.md`](../.claude/rules/prohibitions.md)):

| Prohibition | Rule |
|---|---|
| **No CommunityToolkit.Mvvm** in any form (base classes, attributes, namespaces, source generators) | P-001 |
| **No `System.Windows.*` UI types in ViewModels**, except `System.Windows.Input.ICommand` | P-002 |
| **No framework auto-introduction or auto-detection** (CTK / Prism / DevExpress / Generic Host / DI added to a project that lacks it; framework-sniffing logic) | P-003 |
| **No framework / project modernization** (raising the target framework, retargeting to .NET (Core), converting project format, migrating package management, bumping `LangVersion`) without explicit request | P-004 |
| **No implicit network access** (offline only) | P-005 |

---

## 5. Prism — opt-in alternative

Prism remains available **only** as an explicit opt-in for projects that
already depend on Prism — it is never the default and is never auto-introduced.

- On net472/net48, Prism is **Prism 7.2 / 8.1** (not 9).
- Mechanism: `IContainerRegistry.RegisterForNavigation<View, ViewModel>()` +
  `IRegionManager.RequestNavigate("Region", "ViewName")`, using Prism's own
  `BindableBase` / `DelegateCommand`.
- Use it only when keeping an existing Prism project on Prism; never convert a
  hand-rolled project to Prism without being asked.

Details: [`view-viewmodel-wiring-prism.md`](../.claude/rules/view-viewmodel-wiring-prism.md).

---

## 6. References (rules)

| Topic | File |
|---|---|
| MVVM constraints + hand-rolled base classes | [`mvvm-constraints.md`](../.claude/rules/mvvm-constraints.md) |
| Hard prohibitions (P-001..P-005) | [`prohibitions.md`](../.claude/rules/prohibitions.md) |
| View ↔ ViewModel wiring (hand-rolled, default) | [`view-viewmodel-wiring-handrolled.md`](../.claude/rules/view-viewmodel-wiring-handrolled.md) |
| View ↔ ViewModel wiring (Prism, opt-in) | [`view-viewmodel-wiring-prism.md`](../.claude/rules/view-viewmodel-wiring-prism.md) |
