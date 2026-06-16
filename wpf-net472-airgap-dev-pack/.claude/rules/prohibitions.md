# Prohibitions

The few hard "do not" rules for this net472 air-gapped fork. Unlike upstream,
this fork does **not** enforce a single opinionated MVVM composition path — it
is pragmatic so generated code fits any existing net472/net48 app (see "Allowed
wiring" below).

---

## P-001: No CommunityToolkit.Mvvm

Do not introduce or use CommunityToolkit.Mvvm in any form — `ObservableObject` /
`ObservableRecipient` base classes, `[ObservableProperty]`, `[RelayCommand]`,
`[NotifyCanExecuteChangedFor]`, the `CommunityToolkit.Mvvm.*` namespaces, or its
source generators. Use the hand-rolled `BindableBase` / `RelayCommand`
(`rules/mvvm-constraints.md`).

## P-002: No WPF UI types in ViewModels (except `ICommand`)

Do not reference `System.Windows.*` UI types (`Visibility`, `Brush`,
`ImageSource`, `Thickness`, `Window`, `MessageBox`, …) from ViewModel code.
**Allowed exception:** `System.Windows.Input.ICommand` (for `RelayCommand`).
Convert UI types in the View layer (converters / triggers).

## P-003: No framework auto-introduction or auto-detection

Do not add CommunityToolkit.Mvvm, Prism, DevExpress, Generic Host, or any
DI/MVVM framework to a project that does not already use it, and do not run
framework-detection ("is this DevExpress / CTK / Prism?") logic. Always emit the
dependency-free hand-rolled form; only follow a project's existing framework when
it already uses one and the user is keeping it.

## P-004: No framework / project modernization

Do not raise the target framework, retarget to .NET (Core), convert the project
format (non-SDK ⇄ SDK), migrate `packages.config` ⇄ `PackageReference`, or bump
the C# `LangVersion` unless the user explicitly asks. See `## Target Framework`
in `.claude/CLAUDE.md`.

## P-005: No implicit network access

Offline only. Do not run `git pull`, marketplace updates, `uvx git+https://…`,
or online NuGet restore/search as an implicit action. If information is missing,
ask the user.

---

## Allowed wiring (NOT prohibited)

This fork is pragmatic about View ↔ ViewModel wiring so generated code fits any
existing net472 app. All of these are acceptable — **match what the project
already uses**:

- **Code-behind** `DataContext = new XxxViewModel()` in the View constructor —
  the simplest, most universal pattern; fine for small/standalone views and dialogs.
- **DataTemplate mapping** (ViewModel-first): a `DataTemplate` with `DataType`
  (no `x:Key`) so a ViewModel bound to `ContentControl.Content` renders its View.
- **DI-resolved** ViewModels assigned to `DataContext` where the app already uses
  a container.

Prefer **one** wiring style within a single project for consistency, but do not
rewrite a project's existing, working wiring to a different style without being
asked.

> Prism's `RegisterForNavigation` / `RegionManager` remains an opt-in alternative
> for projects already on Prism — see `rules/view-viewmodel-wiring-prism.md`. It
> is never the default and is never auto-introduced.
