# WPF ViewModel Unit Testing — Prism (opt-in)

> 프로젝트가 **이미** Prism을 도입한 경우(opt-in)에만 이 파일을 참조합니다.
> 이 포크의 기본값은 hand-rolled MVVM입니다 → [TOPIC.md](TOPIC.md) 참조

> ⚠️ Prism 9는 .NET 8+ 전용입니다. net472/net48에서는 **Prism 7.2 또는 8.1**을 사용하고
> 모든 테스트 코드는 C# 7.3 호환으로 작성합니다. Never auto-introduce Prism — opt-in only.

## Differences from the hand-rolled default ([TOPIC.md](TOPIC.md))

| Item | Hand-rolled (default) | Prism (opt-in) |
|------|-----------------------|----------------|
| PropertyChanged | `SetProperty()` raises | `SetProperty()` raises |
| Command type | `RelayCommand` | `DelegateCommand` |
| CanExecute change | `CommandManager.RequerySuggested` (assert `CanExecute()`) | `.ObservesProperty()` |
| Async command | wrap `async Task` in `RelayCommand` | `AsyncDelegateCommand` |

---

## 1. PropertyChanged Verification

```csharp
public sealed class UserViewModelTests
{
    [Fact]
    public void Setting_UserName_Raises_PropertyChanged()
    {
        var vm = new UserViewModel();
        var changedProperties = new List<string>();
        vm.PropertyChanged += (s, e) => changedProperties.Add(e.PropertyName);

        vm.UserName = "Alice";

        changedProperties.Should().Contain(nameof(UserViewModel.UserName));
    }
}
```

## 2. DelegateCommand Testing

```csharp
public sealed class OrderViewModelTests
{
    [Fact]
    public void SaveCommand_Executes_When_CanSave_Is_True()
    {
        var mockService = Substitute.For<IOrderService>();
        var vm = new OrderViewModel(mockService) { OrderName = "Test" };

        vm.SaveCommand.CanExecute().Should().BeTrue();
        vm.SaveCommand.Execute();

        mockService.Received(1).Save(Arg.Any<Order>());
    }

    [Fact]
    public void SaveCommand_Cannot_Execute_When_OrderName_Is_Empty()
    {
        var mockService = Substitute.For<IOrderService>();
        var vm = new OrderViewModel(mockService) { OrderName = "" };

        // DelegateCommand.CanExecute() — no parameter needed
        // DelegateCommand.CanExecute() — 파라미터 불필요
        vm.SaveCommand.CanExecute().Should().BeFalse();
    }

    [Fact]
    public void SaveCommand_ObservesProperty_Raises_CanExecuteChanged()
    {
        var mockService = Substitute.For<IOrderService>();
        var vm = new OrderViewModel(mockService);
        var canExecuteChanged = false;
        vm.SaveCommand.CanExecuteChanged += (s, e) => canExecuteChanged = true;

        // ObservesProperty auto-raises CanExecuteChanged
        vm.OrderName = "Test";

        canExecuteChanged.Should().BeTrue();
    }
}
```

## 3. AsyncDelegateCommand Testing

```csharp
public sealed class DataViewModelTests
{
    [Fact]
    public async Task LoadCommand_Populates_Items()
    {
        var mockService = Substitute.For<IDataService>();
        mockService.GetAllAsync().Returns(new List<string> { "Item1", "Item2" });

        var vm = new DataViewModel(mockService);

        await vm.LoadCommand.Execute();

        vm.Items.Should().Contain(new[] { "Item1", "Item2" });
    }
}
```

## 4. INavigationAware Testing

```csharp
public sealed class DetailViewModelTests
{
    [Fact]
    public void OnNavigatedTo_Loads_Item_From_Parameters()
    {
        var mockService = Substitute.For<IItemService>();
        mockService.GetById(42).Returns(new Item { Id = 42, Name = "Test" });
        var vm = new DetailViewModel(mockService);

        var navParams = new NavigationParameters { { "itemId", 42 } };
        vm.OnNavigatedTo(new NavigationContext(
            Substitute.For<IRegionNavigationService>(), new Uri("Detail", UriKind.Relative), navParams));

        vm.Item.Should().NotBeNull();
        vm.Item.Name.Should().Be("Test");
    }

    [Fact]
    public void IsNavigationTarget_Returns_True_For_Same_Id()
    {
        var vm = new DetailViewModel(Substitute.For<IItemService>()) { Item = new Item { Id = 42 } };

        var navParams = new NavigationParameters { { "itemId", 42 } };
        var context = new NavigationContext(
            Substitute.For<IRegionNavigationService>(), new Uri("Detail", UriKind.Relative), navParams);

        vm.IsNavigationTarget(context).Should().BeTrue();
    }
}
```
