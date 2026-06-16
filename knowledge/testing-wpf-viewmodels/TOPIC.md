# WPF ViewModel Unit Testing

> Implements xUnit unit tests for WPF ViewModels built with hand-rolled MVVM (BindableBase + RelayCommand, no CommunityToolkit.Mvvm). Covers PropertyChanged verification, RelayCommand testing, CanExecute logic, and service mocking with NSubstitute. Use when writing ViewModel tests or setting up a test project for WPF MVVM.

Unit test patterns for WPF ViewModels using xUnit and the hand-rolled
`BindableBase`/`RelayCommand` MVVM (no CommunityToolkit.Mvvm).

> **net472/no-CTK note (this fork):** the testing technique is the subject. The
> ViewModels under test use the hand-rolled `BindableBase`/`RelayCommand`
> (the fork's standard is `implementing-handrolled-mvvm`), and all test code is
> C# 7.3-safe. Do NOT use CommunityToolkit.Mvvm's `AsyncRelayCommand.IsRunning`
> or `ExecuteAsync` — the hand-rolled command exposes neither.

> For inventory-driven **governance** of these tests (classification, naming, coverage tracking), see the [`managing-unit-tests`](../managing-unit-tests/SKILL.md) skill.

---

## Testing Principles

These principles apply to every test class in this guide, regardless of which pattern is being demonstrated.

### Classification — Happy / Boundary / Error

Organize tests into three groups, each as its own `#region`:

| Group | Definition | Example |
|-------|------------|---------|
| **Happy** | Valid input / normal state → expected success result | `Setting_UserName_Raises_PropertyChanged` |
| **Boundary** | Edge conditions (empty, zero, min/max, inactive state, null-safe paths) | `Setting_Same_Value_Does_Not_Raise_PropertyChanged` |
| **Error** | Invalid input / exceptions / detection events | `Submit_InvalidEmail_ReportsValidationError` |

For validators and detectors, the "successful detection" case is classified as **Error** — surfacing a failure state *is* the error path of such logic.

Omit a region entirely if no cases exist for it — never leave an empty region.

### Method Naming — `Method_Scenario_Expected`

| Good | Bad |
|------|-----|
| `Activate_EmptyString_ReturnsError` | `TestActivate1` |
| `LoadCommand_Canceled_StopsExecution` | `ShouldCancel` |
| `Validate_PartiallyConnectedInputs_ReportsError` | `PartialConnection` |

- Method segment: the public method or property under test. Constructor tests use the `Ctor_*` prefix.
- Scenario segment: input or state condition (PascalCase).
- Expected segment: return value / state change / exception (`ReturnsX`, `ThrowsX`, `RaisesX`, `UpdatesX`).

### Mocking Policy

- Mocking libraries (Moq / NSubstitute / FakeItEasy) are only for **external dependencies** — I/O, database, network, system APIs, P/Invoke.
- For internal domain objects use real instances or hand-written fakes. Mocking domain objects hides real bugs.
- Reserve randomized / bulk data generators (Bogus) for scenarios that genuinely need volume or randomness.

### Forbidden Test Shapes

- **POCO default-value checks** — e.g. `Assert.Null(new Foo().Prop)`. Skip unless the default is part of the business contract, and then document the rationale inline.
- **Inheritance-relation assertions** — e.g. `Assert.IsType<Base>(instance, exactMatch: false)`. Tautological; the compiler already guarantees this.
- **Hard-coded collection counts** — e.g. `Assert.Equal(3, items.Count)`. Assert on meaningful shape (contents, ordering) instead.
- **Private-method tests** — reach them through the public contract. Unreachable branches indicate a design defect.

### Resource & Timing Discipline

- Hold disposables? Implement `IDisposable` and clean up.
- File I/O? Use `Path.GetTempPath()` combined with `Guid.NewGuid():N` directories.
- Time-sensitive logic? Use relative time (`AddDays(-N)`) or a time abstraction — never `DateTime.Now` directly.
- Async tests use `async Task`, never `async void`. Guard external signals with `Task.WhenAny(target, Task.Delay(timeout))` to avoid hangs.

---

## NuGet Packages

```xml
<ItemGroup>
  <PackageReference Include="xunit" Version="2.*" />
  <PackageReference Include="xunit.runner.visualstudio" Version="2.*" />
  <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.*" />
  <PackageReference Include="NSubstitute" Version="5.*" />
  <PackageReference Include="FluentAssertions" Version="7.*" />
</ItemGroup>
```

---

## 1. PropertyChanged Verification

```csharp
using FluentAssertions;

public sealed class UserViewModelTests
{
    [Fact]
    public void Setting_UserName_Raises_PropertyChanged()
    {
        // Arrange
        var vm = new UserViewModel();
        var changedProperties = new List<string>();
        vm.PropertyChanged += (_, e) => changedProperties.Add(e.PropertyName);

        // Act
        vm.UserName = "Alice";

        // Assert
        changedProperties.Should().Contain(nameof(UserViewModel.UserName));
    }

    [Fact]
    public void Setting_Same_Value_Does_Not_Raise_PropertyChanged()
    {
        var vm = new UserViewModel { UserName = "Alice" };
        var raised = false;
        vm.PropertyChanged += (s, e) => raised = true;

        vm.UserName = "Alice";

        raised.Should().BeFalse();
    }
}
```

## 2. RelayCommand Testing

```csharp
public sealed class OrderViewModelTests
{
    [Fact]
    public void SaveCommand_Executes_When_CanSave_Is_True()
    {
        var mockService = Substitute.For<IOrderService>();
        var vm = new OrderViewModel(mockService) { OrderName = "Test" };

        vm.SaveCommand.CanExecute(null).Should().BeTrue();
        vm.SaveCommand.Execute(null);

        mockService.Received(1).Save(Arg.Any<Order>());
    }

    [Fact]
    public void SaveCommand_Cannot_Execute_When_OrderName_Is_Empty()
    {
        var mockService = Substitute.For<IOrderService>();
        var vm = new OrderViewModel(mockService) { OrderName = "" };

        vm.SaveCommand.CanExecute(null).Should().BeFalse();
    }
}
```

## 3. Async Command Testing (hand-rolled)

The hand-rolled `RelayCommand` has no `ExecuteAsync`/`IsRunning`. Expose the async
work through a public `Task`-returning method that the command wraps, and surface
busy state via an `IsLoading` property on the ViewModel. Tests call the method
directly (cleaner than `ICommand.Execute`, which is `async void` for an async body).

```csharp
public sealed class DataViewModel : BindableBase
{
    private readonly IDataService _service;

    public DataViewModel(IDataService service)
    {
        _service = service;
        LoadCommand = new RelayCommand(async () => await LoadAsync(), () => !IsLoading);
    }

    public ObservableCollection<string> Items { get; } = new ObservableCollection<string>();

    private bool _isLoading;
    public bool IsLoading
    {
        get { return _isLoading; }
        private set { SetProperty(ref _isLoading, value); }
    }

    public ICommand LoadCommand { get; }

    // Public Task-returning method so tests can await it deterministically.
    public async Task LoadAsync()
    {
        IsLoading = true;
        try
        {
            var items = await _service.GetAllAsync();
            Items.Clear();
            foreach (var item in items)
                Items.Add(item);
        }
        finally
        {
            IsLoading = false;
        }
    }
}
```

```csharp
public sealed class DataViewModelTests
{
    [Fact]
    public async Task LoadAsync_Populates_Items()
    {
        var mockService = Substitute.For<IDataService>();
        mockService.GetAllAsync().Returns(new List<string> { "Item1", "Item2" });

        var vm = new DataViewModel(mockService);

        await vm.LoadAsync();

        vm.Items.Should().Contain(new[] { "Item1", "Item2" });
    }

    [Fact]
    public async Task LoadAsync_Sets_IsLoading_During_Execution()
    {
        var tcs = new TaskCompletionSource<List<string>>();
        var mockService = Substitute.For<IDataService>();
        mockService.GetAllAsync().Returns(tcs.Task);

        var vm = new DataViewModel(mockService);
        var loadTask = vm.LoadAsync();

        vm.IsLoading.Should().BeTrue();

        tcs.SetResult(new List<string> { "Item1" });
        await loadTask;

        vm.IsLoading.Should().BeFalse();
    }
}
```

## 4. CanExecute Re-evaluation Testing (hand-rolled)

The hand-rolled `RelayCommand.CanExecuteChanged` forwards to
`CommandManager.RequerySuggested`, which the WPF dispatcher raises during idle —
**not** synchronously from a property setter. So asserting on a
`CanExecuteChanged` callback is non-deterministic in a unit test. Instead, assert
that `CanExecute()` itself flips after the dependent property changes — that is
the behavior users actually care about.

```csharp
public sealed class FormViewModelTests
{
    [Fact]
    public void SubmitCommand_CanExecute_Becomes_True_After_Email_Set()
    {
        var vm = new FormViewModel();
        vm.SubmitCommand.CanExecute(null).Should().BeFalse();

        vm.Email = "test@example.com";

        vm.SubmitCommand.CanExecute(null).Should().BeTrue();
    }
}
```

> If a ViewModel needs to force a requery immediately (e.g. for a manual button
> refresh), expose a setter that calls `RaiseCanExecuteChanged()` on the command;
> the test can then assert the `CanExecute(null)` transition as above.

## 5. Service Mocking with NSubstitute

```csharp
public sealed class DashboardViewModelTests
{
    private readonly INavigationService _navService;
    private readonly IDataService _dataService;
    private readonly DashboardViewModel _vm;

    public DashboardViewModelTests()
    {
        _navService = Substitute.For<INavigationService>();
        _dataService = Substitute.For<IDataService>();
        _vm = new DashboardViewModel(_navService, _dataService);
    }

    [Fact]
    public void NavigateCommand_Calls_NavigationService()
    {
        _vm.NavigateCommand.Execute("Settings");

        _navService.Received(1).NavigateTo("Settings");
    }

    [Fact]
    public void Constructor_Does_Not_Call_Services()
    {
        // ViewModel 생성자에서 서비스 호출 금지 확인
        // Verify constructor doesn't call services
        _dataService.DidNotReceive().GetAllAsync();
        _navService.DidNotReceive().NavigateTo(Arg.Any<string>());
    }
}
```

## 6. Test Project Structure

```
{SolutionName}.Tests/
├── {SolutionName}.Tests.csproj
├── GlobalUsings.cs
├── ViewModels/
│   ├── DashboardViewModelTests.cs
│   ├── SettingsViewModelTests.cs
│   └── FormViewModelTests.cs
└── Fixtures/
    └── ServiceFixtures.cs          (shared mock setups)
```

### GlobalUsings.cs

```csharp
global using Xunit;
global using NSubstitute;
global using FluentAssertions;
```

---

## Checklist

- [ ] Each ViewModel has a corresponding test class
- [ ] PropertyChanged events verified for key properties
- [ ] All Commands tested (Execute + CanExecute)
- [ ] Async commands tested with TaskCompletionSource for timing control
- [ ] Services mocked — no real I/O in unit tests
- [ ] Constructor side-effects verified (should be minimal)

> **Prism 9 사용자**: See [PRISM.md](PRISM.md) for Prism-specific testing patterns.
